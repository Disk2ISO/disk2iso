# Metadata Cache-DB - Implementierungsplan

**Erstellt**: 18. Januar 2026  
**Status**: Planung  
**Ziel**: Lokale Metadaten-Datenbank für schnelle Suche ohne API-Calls  
**Geschätzte Dauer**: 4-6 Tage

---

## 📋 Übersicht

### Problem
- Jede Suche = API-Call (MusicBrainz/TMDB, 500-2000ms)
- Keine Wiederverwendung von bereits abgerufenen Metadaten
- Offline-Betrieb unmöglich
- Duplikate schwer erkennbar

### Lösung
Lokale Cache-Datenbank mit .nfo-Dateien + Thumbnails:
```
.temp/musicbrainz/
├── ronan_keating_ronan_de_2000_mercury_14tracks_9767fd7e.nfo
├── ronan_keating_ronan_de_2000_mercury_14tracks_9767fd7e-thumb.jpg
├── ronan_keating_ronan_gb_2000_polydor_14tracks_a1b2c3d4.nfo
└── ronan_keating_ronan_gb_2000_polydor_14tracks_a1b2c3d4-thumb.jpg

.temp/tmdb/
├── supernatural_s10_us_2014_tv_23ep_1622.nfo
├── supernatural_s10_us_2014_tv_23ep_1622-thumb.jpg
└── matrix_us_1999_movie_136min_603.nfo
```

### Vorteile
- ✅ **10-40x schneller** (grep vs. API-Call)
- ✅ **API-schonend** (nur bei echten Neusuchen)
- ✅ **Offline-fähig** (Web-UI funktioniert ohne Internet)
- ✅ **Wiederverwendung** (zweite Supernatural-Disc → Instant-Results)
- ✅ **Historische Daten** (gelöschte MusicBrainz-Releases bleiben erhalten)

---

## 🎯 Dateinamen-Schema

### MusicBrainz
```
{artist}_{album}_{country}_{year}_{label}_{tracks}tracks_{release_id_short}.nfo

Beispiele:
ronan_keating_ronan_de_2000_mercury_14tracks_9767fd7e.nfo
various_artists_bravo_hits_90_de_2015_sony_40tracks_abc12345.nfo
ac_dc_back_in_black_us_1980_atlantic_10tracks_def67890.nfo
```

**Normalisierung:**
- Kleinbuchstaben
- Nur `a-z0-9_` (Sonderzeichen → `_`)
- Release-ID: Erste 8 Zeichen (für Eindeutigkeit)

### TMDB
```
{title}_{country}_{year}_{type}_{info}_{tmdb_id}.nfo

Beispiele:
supernatural_s10_us_2014_tv_23ep_1622.nfo
matrix_us_1999_movie_136min_603.nfo
matrix_de_1999_movie_136min_603.nfo  (Deutsche Version)
```

**Info-Felder:**
- TV: `{season}ep` (z.B. `23ep` für 23 Episoden)
- Movie: `{runtime}min` (z.B. `136min`)

---

## 📄 NFO-Format

### MusicBrainz (.nfo)
```ini
SEARCH_RESULT_FOR=ronan_keating_ronan
RELEASE_ID=9767fd7e-9b2a-4a90-a527-c72ba6cbe4ef
TITLE=Ronan
ARTIST=Ronan Keating
DATE=2000-07-31
COUNTRY=DE
TRACKS=14
LABEL=Mercury Records
DURATION=3120
COVER_URL=https://coverartarchive.org/release/9767fd7e.../front-250
TYPE=audio-cd
CACHED_AT=2026-01-18T19:30:00Z
CACHE_VERSION=1.0
```

**Wichtige Felder:**
- `SEARCH_RESULT_FOR`: Zuordnung zur ursprünglichen Suche (z.B. `ronan_keating_ronan`)
- `RELEASE_ID`: MusicBrainz UUID (für spätere Detail-Abfragen)
- `CACHED_AT`: Timestamp für Auto-Refresh (nach 30 Tagen)

### TMDB (.nfo)
```ini
SEARCH_RESULT_FOR=supernatural_season_10_disc_5
TMDB_ID=1622
MEDIA_TYPE=tv
TITLE=Supernatural
YEAR=2014
COUNTRY=US
SEASON=10
EPISODES=23
GENRE=Drama, Fantasy, Horror
RATING=8.3
POSTER_PATH=/o9OKe3M06QMLOzTl3l6GStYtnE9.jpg
TYPE=tv-series
CACHED_AT=2026-01-18T19:30:00Z
CACHE_VERSION=1.0
```

---

## 🚀 Implementierungs-Phasen

### **Phase 1: Cache-Befüllung (Tag 1-2)**

#### 1.1 Neue Funktionen in lib-cd-metadata.sh

```bash
# ===========================================================================
# populate_musicbrainz_cache
# ---------------------------------------------------------------------------
# Funktion: Erstelle .nfo + Thumbnail für jeden MusicBrainz-Treffer
# Parameter: $1 = RAW API Response (JSON)
#            $2 = Suchbegriff (z.B. "ronan_keating_ronan")
# Rückgabe: 0 = Erfolg, Anzahl gecachter Releases
# ===========================================================================
populate_musicbrainz_cache() {
    local raw_json="$1"
    local search_label="$2"
    
    # Initialisiere Cache
    init_musicbrainz_cache_dirs >&2 || return 1
    
    # Extrahiere Release-Count
    local release_count=$(echo "$raw_json" | jq -r '.releases | length')
    
    if [[ "$release_count" -eq 0 ]]; then
        log_message "MusicBrainz: Keine Releases zum Cachen" >&2
        return 0
    fi
    
    log_message "MusicBrainz: Cache $release_count Releases..." >&2
    
    local cached=0
    for i in $(seq 0 $((release_count - 1))); do
        # Extrahiere Metadaten
        local release_id=$(echo "$raw_json" | jq -r ".releases[$i].id")
        local title=$(echo "$raw_json" | jq -r ".releases[$i].title")
        local artist=$(echo "$raw_json" | jq -r ".releases[$i].\"artist-credit\"[0].name")
        local country=$(echo "$raw_json" | jq -r ".releases[$i].country // \"XX\"")
        local date=$(echo "$raw_json" | jq -r ".releases[$i].date // \"0000\"")
        local year=$(echo "$date" | cut -d'-' -f1)
        local tracks=$(echo "$raw_json" | jq -r ".releases[$i].media[0].\"track-count\" // 0")
        local label=$(echo "$raw_json" | jq -r ".releases[$i].\"label-info\"[0]?.label?.name // \"Unknown\"")
        local duration=$(echo "$raw_json" | jq -r "if .releases[$i].media[0].tracks then (.releases[$i].media[0].tracks | map(.length // 0) | add) else 0 end")
        local cover_url=$(echo "$raw_json" | jq -r "if .releases[$i].\"cover-art-archive\".front == true then \"https://coverartarchive.org/release/\" + .releases[$i].id + \"/front-250\" else \"\" end")
        
        # Normalisiere für Dateinamen
        local safe_artist=$(echo "$artist" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')
        local safe_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')
        local safe_label=$(echo "$label" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')
        local release_id_short="${release_id:0:8}"
        
        # Generiere Dateinamen
        local nfo_name="${safe_artist}_${safe_title}_${country}_${year}_${safe_label}_${tracks}tracks_${release_id_short}"
        local nfo_file="${MUSICBRAINZ_CACHE_DIR}/${nfo_name}.nfo"
        local thumb_file="${MUSICBRAINZ_CACHE_DIR}/${nfo_name}-thumb.jpg"
        
        # Prüfe ob bereits gecacht
        if [[ -f "$nfo_file" ]]; then
            log_message "MusicBrainz: Cache-Hit - überspringe $nfo_name" >&2
            continue
        fi
        
        # Erstelle .nfo
        cat > "$nfo_file" <<EOF
SEARCH_RESULT_FOR=${search_label}
RELEASE_ID=${release_id}
TITLE=${title}
ARTIST=${artist}
DATE=${date}
COUNTRY=${country}
TRACKS=${tracks}
LABEL=${label}
DURATION=${duration}
COVER_URL=${cover_url}
TYPE=audio-cd
CACHED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
CACHE_VERSION=1.0
EOF
        
        # Lade Cover-Thumbnail (falls verfügbar)
        if [[ -n "$cover_url" ]]; then
            if curl -s -f -m 5 -H "User-Agent: ${MUSICBRAINZ_USER_AGENT}" "$cover_url" -o "$thumb_file" 2>/dev/null; then
                log_message "MusicBrainz: Cover gecacht für $nfo_name" >&2
            else
                log_message "MusicBrainz: Cover-Download fehlgeschlagen für $nfo_name" >&2
            fi
        fi
        
        cached=$((cached + 1))
    done
    
    log_message "MusicBrainz: $cached von $release_count Releases neu gecacht" >&2
    return 0
}
```

#### 1.2 Integration in search_musicbrainz_json()

```bash
search_musicbrainz_json() {
    # ... bestehender Code ...
    
    # Speichere Response direkt in Cache-Datei
    if curl -s -f -m 10 -H "User-Agent: ${MUSICBRAINZ_USER_AGENT}" "$url" -o "$cache_file" 2>/dev/null; then
        mb_response=$(cat "$cache_file")
        log_message "MusicBrainz: API-Response gespeichert" >&2
        
        # NEU: Befülle lokale .nfo-Cache-Datenbank
        populate_musicbrainz_cache "$mb_response" "$safe_name" >&2
    else
        # ... Fehlerbehandlung ...
    fi
    
    # ... Rest wie bisher (jq-Formatierung) ...
}
```

#### 1.3 Analog für TMDB (lib-dvd-metadata.sh)

```bash
populate_tmdb_cache() {
    local raw_json="$1"
    local search_label="$2"
    local media_type="$3"  # "movie" oder "tv"
    
    # Analog zu MusicBrainz
    # Extrahiere results[] und speichere jeden als .nfo + Poster
}
```

**Milestone 1**: ✅ Cache wird bei jeder Suche automatisch befüllt

---

### **Phase 2: Cache-First-Suche (Tag 3-4)**

#### 2.1 Lokale Suche in lib-cd-metadata.sh

```bash
# ===========================================================================
# search_local_musicbrainz_cache
# ---------------------------------------------------------------------------
# Funktion: Suche in lokaler .nfo-Cache-Datenbank
# Parameter: $1 = Suchbegriff (z.B. "ronan_keating_ronan")
# Rückgabe: JSON mit {"success": true, "results": [...], "from_cache": true}
#           oder Exit-Code 1 bei Fehler/kein Treffer
# ===========================================================================
search_local_musicbrainz_cache() {
    local search_label="$1"
    
    # Initialisiere Cache
    init_musicbrainz_cache_dirs >&2 || return 1
    
    # Suche .nfo-Dateien mit passendem SEARCH_RESULT_FOR
    local matches=$(grep -l "^SEARCH_RESULT_FOR=${search_label}$" "${MUSICBRAINZ_CACHE_DIR}"/*.nfo 2>/dev/null)
    
    if [[ -z "$matches" ]]; then
        log_message "MusicBrainz: Kein Cache-Treffer für '$search_label'" >&2
        return 1
    fi
    
    local match_count=$(echo "$matches" | wc -l)
    log_message "MusicBrainz: ✅ $match_count Cache-Treffer!" >&2
    
    # Baue JSON-Array aus .nfo-Dateien
    local results="["
    local first=true
    
    for nfo in $matches; do
        # Parse .nfo
        local release_id=$(grep "^RELEASE_ID=" "$nfo" | cut -d'=' -f2-)
        local title=$(grep "^TITLE=" "$nfo" | cut -d'=' -f2-)
        local artist=$(grep "^ARTIST=" "$nfo" | cut -d'=' -f2-)
        local date=$(grep "^DATE=" "$nfo" | cut -d'=' -f2-)
        local country=$(grep "^COUNTRY=" "$nfo" | cut -d'=' -f2-)
        local tracks=$(grep "^TRACKS=" "$nfo" | cut -d'=' -f2-)
        local label=$(grep "^LABEL=" "$nfo" | cut -d'=' -f2-)
        local duration=$(grep "^DURATION=" "$nfo" | cut -d'=' -f2-)
        
        # Prüfe ob Thumbnail existiert
        local thumb_file="${nfo%.nfo}-thumb.jpg"
        local cover_url=""
        if [[ -f "$thumb_file" ]]; then
            cover_url="file://$(basename "$thumb_file")"
        fi
        
        # JSON-Objekt bauen (escaped für jq)
        if [[ "$first" != "true" ]]; then
            results+=","
        fi
        first=false
        
        # Nutze jq für sauberes JSON-Escaping
        results+=$(jq -n \
            --arg id "$release_id" \
            --arg title "$title" \
            --arg artist "$artist" \
            --arg date "$date" \
            --arg country "$country" \
            --argjson tracks "$tracks" \
            --arg label "$label" \
            --argjson duration "$duration" \
            --arg cover_url "$cover_url" \
            '{
                id: $id,
                title: $title,
                artist: $artist,
                date: $date,
                country: $country,
                tracks: $tracks,
                label: $label,
                duration: $duration,
                cover_url: $cover_url
            }'
        )
    done
    
    results+="]"
    
    # Finale Response (als LETZTE Zeile auf stdout)
    echo "{\"success\": true, \"results\": $results, \"from_cache\": true}"
    return 0
}
```

#### 2.2 Erweitere search_musicbrainz_json()

```bash
search_musicbrainz_json() {
    local artist="$1"
    local album="$2"
    local iso_path="$3"
    
    # Bestimme Suchbegriff
    local search_label=""
    if [[ -n "$iso_path" ]]; then
        search_label=$(basename "${iso_path%.iso}")
    else
        search_label=$(echo "${artist}_${album}" | tr ' ' '_' | tr -cd 'a-z0-9_')
    fi
    
    # SCHRITT 1: Versuche lokalen Cache
    if search_local_musicbrainz_cache "$search_label"; then
        # Cache-Hit! JSON bereits auf stdout ausgegeben
        return 0
    fi
    
    # SCHRITT 2: Fallback zu API
    log_message "MusicBrainz: Kein Cache → API-Anfrage" >&2
    
    # ... bestehender API-Code ...
}
```

**Milestone 2**: ✅ Cache-First-Strategie aktiv, API nur bei echten Neusuchen

---

### **Phase 3: Python Web-API Integration (Tag 4-5)**

#### 3.1 Thumbnail-Serving in app.py

```python
@app.route('/api/metadata/cache/thumbnail/<path:filename>')
def serve_cache_thumbnail(filename):
    """Serve cached thumbnail images"""
    cache_base = os.path.join(os.environ.get('DEFAULT_OUTPUT_DIR', '/media/iso'), '.temp')
    
    # Bestimme Cache-Typ (musicbrainz oder tmdb)
    if filename.startswith('musicbrainz/'):
        cache_dir = os.path.join(cache_base, 'musicbrainz')
        thumb_file = filename.replace('musicbrainz/', '')
    elif filename.startswith('tmdb/'):
        cache_dir = os.path.join(cache_base, 'tmdb')
        thumb_file = filename.replace('tmdb/', '')
    else:
        return jsonify({'error': 'Invalid cache type'}), 400
    
    full_path = os.path.join(cache_dir, thumb_file)
    
    if not os.path.exists(full_path):
        return jsonify({'error': 'Thumbnail not found'}), 404
    
    return send_file(full_path, mimetype='image/jpeg')
```

#### 3.2 Frontend: Cover-URLs anpassen (archive.js)

```javascript
function displayMusicBrainzResults(results, fromCache) {
    let html = '<div class="metadata-results">';
    
    results.forEach((release, idx) => {
        // Cover-URL: Prüfe ob aus Cache (file://) oder API (https://)
        let coverUrl;
        if (release.cover_url && release.cover_url.startsWith('file://')) {
            // Lokaler Cache
            const thumbFilename = release.cover_url.replace('file://', '');
            coverUrl = `/api/metadata/cache/thumbnail/musicbrainz/${thumbFilename}`;
        } else if (release.cover_url) {
            // API (CoverArt Archive)
            coverUrl = release.cover_url;
        } else {
            coverUrl = '/static/img/audio-cd-placeholder.png';
        }
        
        html += `
            <div class="result-item" onclick="applyMusicBrainzMetadata('${release.id}')">
                <img src="${coverUrl}" alt="Cover" class="result-cover">
                <div class="result-info">
                    <strong>${escapeHtml(release.title)}</strong><br>
                    ${escapeHtml(release.artist)} (${release.date || 'Unknown'})<br>
                    <small>${release.country} · ${release.tracks} Tracks · ${release.label}</small>
                </div>
            </div>
        `;
    });
    
    // Zeige Cache-Hinweis
    if (fromCache) {
        html += '<p class="cache-hint">ℹ️ Ergebnisse aus lokalem Cache (Offline verfügbar)</p>';
    }
    
    html += '</div>';
    resultsDiv.innerHTML = html;
}
```

**Milestone 3**: ✅ Web-UI zeigt Cache-Ergebnisse mit lokalen Thumbnails

---

### **Phase 4: Cache-Verwaltung (Tag 5-6)**

#### 4.1 Auto-Refresh nach 30 Tagen

```bash
# In search_local_musicbrainz_cache()
for nfo in $matches; do
    # Prüfe Cache-Alter
    local cached_at=$(grep "^CACHED_AT=" "$nfo" | cut -d'=' -f2-)
    local age_days=$(( ($(date +%s) - $(date -d "$cached_at" +%s)) / 86400 ))
    
    if [[ $age_days -gt 30 ]]; then
        log_message "MusicBrainz: Cache-Eintrag veraltet ($age_days Tage) - wird aktualisiert" >&2
        rm -f "$nfo" "${nfo%.nfo}-thumb.jpg"
        # Cache wird beim nächsten API-Call neu befüllt
    fi
done
```

#### 4.2 Cache-Statistik-Tool

```bash
#!/bin/bash
# tools/cache-stats.sh

echo "📊 disk2iso Metadata-Cache Statistik"
echo "======================================"

CACHE_BASE="/media/iso/.temp"

# MusicBrainz
mb_count=$(find "$CACHE_BASE/musicbrainz" -name "*.nfo" 2>/dev/null | wc -l)
mb_size=$(du -sh "$CACHE_BASE/musicbrainz" 2>/dev/null | cut -f1)
echo "MusicBrainz: $mb_count Releases ($mb_size)"

# TMDB
tmdb_count=$(find "$CACHE_BASE/tmdb" -name "*.nfo" 2>/dev/null | wc -l)
tmdb_size=$(du -sh "$CACHE_BASE/tmdb" 2>/dev/null | cut -f1)
echo "TMDB: $tmdb_count Movies/Shows ($tmdb_size)"

echo ""
echo "Älteste Einträge (Auto-Refresh nach 30 Tagen):"
find "$CACHE_BASE" -name "*.nfo" -exec grep -H "^CACHED_AT=" {} \; | \
    sed 's/:CACHED_AT=/\t/' | \
    sort -k2 | \
    head -5
```

#### 4.3 Cache-Purge-Funktion

```bash
# In lib-cd-metadata.sh
purge_musicbrainz_cache() {
    local days="${1:-90}"  # Default: 90 Tage
    
    find "$MUSICBRAINZ_CACHE_DIR" -name "*.nfo" -type f | while read nfo; do
        local cached_at=$(grep "^CACHED_AT=" "$nfo" | cut -d'=' -f2-)
        local age_days=$(( ($(date +%s) - $(date -d "$cached_at" +%s)) / 86400 ))
        
        if [[ $age_days -gt $days ]]; then
            log_message "MusicBrainz: Lösche veralteten Cache-Eintrag: $(basename "$nfo")"
            rm -f "$nfo" "${nfo%.nfo}-thumb.jpg"
        fi
    done
}
```

**Milestone 4**: ✅ Cache-Verwaltung mit Auto-Refresh und Purge

---

## 🔧 Testing-Strategie

### Test 1: Cache-Befüllung
```bash
# Suche mit neuem Album
cd /opt/disk2iso
source conf/disk2iso.conf
source lib/lib-config.sh
source lib/lib-logging.sh
source lib/lib-common.sh
source lib/lib-folders.sh
source lib/lib-cd-metadata.sh

OUTPUT_DIR="/media/iso"
search_musicbrainz_json "Ronan Keating" "Ronan" ""

# Erwartung:
# - .temp/musicbrainz/ronan_keating_ronan_*_*.nfo erstellt
# - Thumbnail heruntergeladen
# - JSON-Response auf stdout
```

### Test 2: Cache-Hit
```bash
# Gleiche Suche nochmal
search_musicbrainz_json "Ronan Keating" "Ronan" ""

# Erwartung:
# - Log: "✅ Cache-Treffer!"
# - Keine API-Anfrage
# - JSON mit "from_cache": true
# - <50ms Antwortzeit
```

### Test 3: Web-UI Integration
1. Öffne http://localhost:8080/archive
2. Klicke "Add Metadata" bei einer Audio-ISO
3. Erwartung: Modal zeigt gecachte Ergebnisse mit Thumbnails
4. Hinweis: "ℹ️ Ergebnisse aus lokalem Cache"

### Test 4: Cache-Alter
```bash
# Simuliere 31 Tage alten Cache
touch -d "31 days ago" .temp/musicbrainz/ronan_keating_ronan_*.nfo
search_musicbrainz_json "Ronan Keating" "Ronan" ""

# Erwartung:
# - Log: "Cache-Eintrag veraltet - wird aktualisiert"
# - API-Anfrage durchgeführt
# - Neuer Cache-Eintrag erstellt
```

---

## 📊 Performance-Benchmarks

### Erwartete Verbesserungen

| Szenario | Aktuell | Mit Cache | Faktor |
|----------|---------|-----------|--------|
| MusicBrainz-Suche (erstmalig) | 1200ms | 1300ms | 0.92x (minimal langsamer) |
| MusicBrainz-Suche (gecacht) | 1200ms | **50ms** | **24x schneller** |
| TMDB-Suche (erstmalig) | 800ms | 850ms | 0.94x |
| TMDB-Suche (gecacht) | 800ms | **40ms** | **20x schneller** |
| Supernatural S10 (5 Discs) | 4000ms | **40ms** | **100x schneller** |

### Speicherplatz

**Pro Release:**
- .nfo: ~500 Bytes
- Thumbnail: ~20-50 KB
- **Gesamt: ~50 KB**

**Bei 1000 Releases:**
- ~50 MB (vernachlässigbar)

---

## ⚠️ Risiken & Gegenmaßnahmen

### Risiko 1: Dateinamen-Kollisionen
**Problem**: Identische Metadaten → gleicher Dateiname
```
ronan_keating_ronan_de_2000_mercury_14tracks.nfo  # Release 1
ronan_keating_ronan_de_2000_mercury_14tracks.nfo  # Release 2
```

**Lösung**: Release-ID-Suffix (8 Zeichen)
```
ronan_keating_ronan_de_2000_mercury_14tracks_9767fd7e.nfo
ronan_keating_ronan_de_2000_mercury_14tracks_a1b2c3d4.nfo
```

### Risiko 2: Performance bei >10.000 Dateien
**Problem**: grep über 10.000 .nfo-Dateien = langsam

**Lösung Phase 1** (ausreichend bis ~5000 Releases):
- grep mit `-l` (nur Dateinamen)
- Optimiertes grep-Pattern: `^SEARCH_RESULT_FOR=`

**Lösung Phase 2** (ab ~5000 Releases):
```bash
# Index-Datei: .temp/musicbrainz/index.txt
ronan_keating_ronan → ronan_keating_ronan_de_2000_...|ronan_keating_ronan_gb_2000_...
supernatural_s10 → supernatural_s10_us_2014_...|supernatural_s10_de_2015_...

# Suche: grep in index.txt → split results
```

**Lösung Phase 3** (ab ~10.000 Releases):
```sql
-- SQLite-Datenbank: .temp/cache.db
CREATE TABLE metadata_cache (
    id INTEGER PRIMARY KEY,
    search_label TEXT NOT NULL,
    nfo_file TEXT NOT NULL,
    release_id TEXT,
    title TEXT,
    artist TEXT,
    country TEXT,
    year INTEGER,
    cached_at TIMESTAMP,
    INDEX(search_label)
);

-- Suche: SELECT * FROM metadata_cache WHERE search_label = ?
```

### Risiko 3: Sonderzeichen-Probleme
**Problem**: `AC/DC` → `ac_dc`, Informationsverlust

**Lösung**: Mapping-Datei (optional)
```bash
# .temp/musicbrainz/mappings.txt
ac_dc → AC/DC
guns_n_roses → Guns N' Roses
```

### Risiko 4: Cache-Invalidierung bei API-Änderungen
**Problem**: MusicBrainz korrigiert Track-Count

**Lösung**: 
- `CACHE_VERSION=1.0` im .nfo
- Bei Breaking Changes: Version erhöhen → alter Cache ignoriert
- Auto-Refresh nach 30 Tagen fängt meiste Änderungen ab

---

## 🎯 Meilensteine & Timeline

### Tag 1-2: Cache-Befüllung
- [x] `populate_musicbrainz_cache()` implementiert
- [x] `populate_tmdb_cache()` implementiert
- [x] Integration in `search_musicbrainz_json()` und `search_tmdb_json()`
- [x] Tests: Cache wird bei Suche automatisch befüllt
- **Deliverable**: Jede Suche hinterlässt .nfo + Thumbnail im Cache

### Tag 3: Lokale Suche
- [ ] `search_local_musicbrainz_cache()` implementiert
- [ ] `search_local_tmdb_cache()` implementiert
- [ ] Cache-First-Logik in `search_*_json()`
- [ ] Tests: Cache-Hit bei zweiter Suche
- **Deliverable**: API-Calls nur bei echten Neusuchen

### Tag 4: Web-UI Integration
- [ ] Thumbnail-Serving-Endpoint in app.py
- [ ] Frontend: Cover-URLs anpassen (file:// vs. https://)
- [ ] Cache-Hinweis im Modal
- [ ] Tests: Modal zeigt gecachte Thumbnails
- **Deliverable**: Web-UI funktioniert offline mit Cache

### Tag 5: Cache-Verwaltung
- [ ] Auto-Refresh nach 30 Tagen
- [ ] `cache-stats.sh` Tool
- [ ] `purge_*_cache()` Funktionen
- [ ] Tests: Veraltete Einträge werden aktualisiert
- **Deliverable**: Selbstverwaltender Cache

### Tag 6: Optimierung & Dokumentation
- [ ] Performance-Tests (Benchmarks)
- [ ] Edge-Cases testen (Sonderzeichen, 0 Treffer, >100 Treffer)
- [ ] Dokumentation aktualisieren (Handbuch.md, Entwickler.md)
- [ ] GitHub Issue #7 updaten
- **Deliverable**: Production-Ready

---

## 📚 Referenzen

### Betroffene Dateien
```
lib/lib-cd-metadata.sh          # populate_musicbrainz_cache(), search_local_*
lib/lib-dvd-metadata.sh         # populate_tmdb_cache(), search_local_*
www/app.py                      # /api/metadata/cache/thumbnail/<path>
www/static/js/archive.js        # displayResults() anpassen
doc/Handbuch.md                 # Offline-Fähigkeit dokumentieren
doc/Entwickler.md               # Cache-Architektur dokumentieren
```

### Neue Tools
```
tools/cache-stats.sh            # Statistiken anzeigen
tools/cache-purge.sh            # Alte Einträge löschen (optional)
```

### Konfiguration (optional)
```ini
# conf/disk2iso.conf
METADATA_CACHE_ENABLED=true
METADATA_CACHE_REFRESH_DAYS=30
METADATA_CACHE_MAX_AGE_DAYS=90
```

---

## 💡 Zukunfts-Ideen (nicht in v1.0)

### SQLite-Volltextsuche
```sql
-- Fuzzy-Search über alle gecachten Metadaten
SELECT * FROM metadata_cache 
WHERE title LIKE '%supernatural%' 
   OR artist LIKE '%supernatural%'
ORDER BY relevance DESC;
```

### Deduplizierungs-Report
```bash
# Finde identische Releases (nur Cover unterscheidet sich)
diff ronan_..._de_*.nfo ronan_..._gb_*.nfo
→ "⚠️ Duplikat erkannt - nur Cover unterscheidet sich"
```

### Export/Import
```bash
# Backup der Cache-DB
tar -czf metadata-cache-backup.tar.gz .temp/musicbrainz .temp/tmdb

# Restore auf anderem System
tar -xzf metadata-cache-backup.tar.gz -C /media/iso/
```

### Web-UI: Cache-Browser
- Durchsuche alle gecachten Metadaten
- Filter: Country, Year, Label, Genre
- Bulk-Apply: "Wende auf alle Supernatural-Discs an"

---

## ✅ Erfolgskriterien

1. **Performance**: Cache-Hit <100ms (aktuell 1000-2000ms)
2. **API-Schonung**: >80% Suchen aus Cache (nach 1 Monat Betrieb)
3. **Offline**: Web-UI funktioniert ohne Internet (gecachte Daten)
4. **Speicher**: <100MB bei 1000 Releases
5. **Stabilität**: Keine Dateinamen-Kollisionen
6. **Wartbarkeit**: Auto-Refresh verhindert veraltete Daten

---

**Status-Tracking**: Dieses Dokument wird während der Implementierung aktualisiert.  
**Nächster Schritt**: Phase 1 - Cache-Befüllung (lib-cd-metadata.sh)
