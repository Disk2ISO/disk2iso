# MusicBrainz: Python vs. Bash Implementation Analysis

**Erstellt:** 2026-01-26  
**Zweck:** Migrationsplanung – MusicBrainz-Logik von Python (www/app.py) nach Bash (lib/libmusicbrainz.sh) überführen  
**Ziel:** Python wird reiner HTTP-Gateway, gesamte Business-Logik in Bash-Modulen

---

## 1. Übersicht: Aktuelle Implementierung

### 1.1 Python-Implementierung (www/app.py)

| Endpoint | Zeilen | Funktion | Datenquelle | Verarbeitung |
|----------|--------|----------|-------------|--------------|
| `/api/musicbrainz/releases` | 562-580 | Liste MusicBrainz Releases | JSON-Dateien (`musicbrainz_releases.json`, `musicbrainz_selection.json`) | **Python**: Liest JSON, kombiniert Status, liefert Frontend-Datenstruktur |
| `/api/musicbrainz/cover/<id>` | 581-630 | Cover-Art Download | MusicBrainz Cover Art API | **Hybrid**: Python ruft Bash-Funktion `fetch_coverart()` via subprocess, Bash downloaded, Python liefert Datei |
| `/api/musicbrainz/select` | 632-660 | Release-Auswahl speichern | POST-Request (Frontend) | **Python**: Validierung, JSON-Schreiben (`musicbrainz_selection.json`) |
| `/api/musicbrainz/manual` | 662-689 | Manuelle Metadaten-Eingabe | POST-Request (Frontend) | **Python**: Validierung, JSON-Schreiben (`musicbrainz_manual.json`) |
| `/api/metadata/musicbrainz/search` | 1857-1950 | Suche in MusicBrainz | ISO-Datei (MP3-Track-Counting) | **Hybrid**: Python mounted ISO, zählt MP3-Tracks, ruft `search_musicbrainz_json()` Bash-Funktion via subprocess |
| `/api/musicbrainz/apply` | 1950-2030 | Remaster ISO mit korrekten Tags | ISO-Datei + Release-ID | **Hybrid**: Python validiert, ruft `remaster_audio_iso_with_metadata()` Bash-Funktion (5-10 Min. Timeout) |

**Wichtige Python-Operationen:**
- **ISO-Mounting** (Zeilen 1857-1950): Python mounted ISO via loop-device, zählt Anzahl MP3-Dateien
- **JSON-Verarbeitung**: Python kombiniert `musicbrainz_releases.json` + `musicbrainz_selection.json` zu Frontend-Datenstruktur
- **File-Serving**: Python liefert Cover-Art als `send_file()` (after Bash download)
- **Timeout-Management**: 600s für Remaster-Prozess (Zeile 1995)

---

### 1.2 Bash-Implementierung (lib/libmusicbrainz.sh)

| Funktion | Zeilen | Status | Funktionalität |
|----------|--------|--------|----------------|
| `check_dependencies_musicbrainz()` | 43-69 | ✅ Vollständig | Prüft Abhängigkeiten, lädt INI-Config, initialisiert Pfade |
| `load_api_config_musicbrainz()` | 135-164 | ✅ Vollständig | Lädt API-Konfiguration aus `libmusicbrainz.ini` (base_url, timeout, user_agent) |
| `musicbrainz_query()` | 172-244 | ✅ Vollständig | **Query-Phase**: Suche via MusicBrainz API, erstellt `.mbquery` Datei mit JSON-Response |
| `musicbrainz_parse_selection()` | 250-298 | ⚠️ Teilweise | **Parse-Phase**: Liest `.mbquery`, extrahiert Metadaten, setzt via `metadb_set_data()` |
| `musicbrainz_apply_selection()` | 304-318 | ✅ Vollständig | **Apply-Phase**: Erzeugt `disc_label` aus Metadaten |
| `musicbrainz_url_encode()` | 325-339 | ✅ Vollständig | Helper: URL-Encoding für Query-Parameter |
| `musicbrainz_populate_cache()` | 341-390 | ✅ Vollständig | Erstellt `.nfo` Dateien + Cover-Thumbnails in Cache |

**Implementierungsstand:**
- ✅ **Query-Mechanismus**: Vollständig (API-Request, JSON-Parsing, Cache-Befüllung)
- ✅ **Provider-Registration**: Auto-Register via `metadata_register_provider()` (Zeile 395-401)
- ⚠️ **Metadaten-Extraktion**: Nur Basis-Felder (artist, album, year, release_id)
- ❌ **Track-Informationen**: Nicht implementiert (keine Track-Level-Daten)
- ❌ **Disc-ID-Generierung**: Nicht vorhanden (Python zählt MP3-Tracks)
- ❌ **ISO-Mounting**: Nicht vorhanden (Python-Only)

---

## 2. Detaillierte Datenanalyse

### 2.1 MusicBrainz API Response (aus Bash-Query)

**Aktuelle Nutzung in `musicbrainz_parse_selection()` (Zeilen 275-287):**

```bash
# Extrahiert aus MusicBrainz API JSON:
artist=$(echo "$mb_json" | jq -r ".[$selected_index][\"artist-credit\"][0].name // \"Unknown Artist\"")
album=$(echo "$mb_json" | jq -r ".[$selected_index].title // \"Unknown Album\"")
year=$(echo "$mb_json" | jq -r ".[$selected_index].date // \"\"" | cut -d- -f1)
release_id=$(echo "$mb_json" | jq -r ".[$selected_index].id // \"\"")

# Setzt in metadb:
metadb_set_data "artist" "$artist"
metadb_set_data "album" "$album"
metadb_set_data "year" "$year"
metadb_set_metadata "provider_id" "$release_id"
```

**Verfügbare Felder in MusicBrainz API (nicht genutzt):**

```json
{
  "releases": [
    {
      "id": "uuid",
      "title": "Album Title",
      "artist-credit": [{"name": "Artist Name"}],
      "date": "YYYY-MM-DD",
      "country": "XX",
      "status": "Official/Promo/...",
      "barcode": "1234567890",
      "label-info": [
        {
          "label": {"name": "Label Name"},
          "catalog-number": "CAT-123"
        }
      ],
      "media": [
        {
          "format": "CD",
          "track-count": 12,
          "tracks": [
            {
              "id": "uuid",
              "title": "Track 1",
              "number": "1",
              "length": 180000,
              "recording": {
                "id": "uuid",
                "title": "Track 1 Recording"
              }
            }
          ]
        }
      ]
    }
  ]
}
```

**Fehlende Daten in Bash:**
- ❌ **Label-Informationen**: `label-info[].label.name`, `label-info[].catalog-number`
- ❌ **Release-Status**: `status` (Official, Promo, Bootleg)
- ❌ **Barcode**: `barcode`
- ❌ **Track-Daten**: `media[].tracks[]` (Track-Title, Länge, Recording-ID)
- ❌ **Medium-Format**: `media[].format` (CD, Vinyl, Digital)
- ❌ **Track-Count**: `media[].track-count` (für Validierung)

---

### 2.2 Python-Spezifische Operationen

#### **A) ISO-Mounting & MP3-Track-Counting (app.py Zeilen 1857-1950)**

```python
# Python mounted ISO via loop-device
iso_path = data.get('iso_path', '')
if not os.path.exists(iso_path):
    return error

# Zählt MP3-Tracks in ISO
mp3_count = 0
for root, dirs, files in os.walk(mount_point):
    mp3_count += sum(1 for f in files if f.lower().endswith('.mp3'))

# Ruft Bash-Funktion mit Track-Count auf
subprocess.run(['bash', '-c', f'search_musicbrainz_json "{iso_path}" {mp3_count}'])
```

**Problem:** Bash hat keine ISO-Mounting-Logik → **Muss implementiert werden**

---

#### **B) JSON-Datei-Kombination (app.py Zeilen 562-580)**

```python
releases = read_api_json('musicbrainz_releases.json')
selection = read_api_json('musicbrainz_selection.json')

return jsonify({
    'status': selection.get('status', 'unknown'),
    'releases': releases.get('releases', []),
    'selected_index': selection.get('selected_index', 0),
    'confidence': selection.get('confidence', 'unknown')
})
```

**Problem:** Python kombiniert 2 JSON-Dateien zu Frontend-Datenstruktur → **Kann Bash übernehmen**

---

#### **C) Cover-Art File-Serving (app.py Zeilen 581-630)**

```python
# Bash downloaded Cover, Python liefert Datei
result = subprocess.run(['bash', '-c', f'fetch_coverart "{release_id}"'])
response_data = json.loads(result.stdout)

if response_data.get('success'):
    cover_path = response_data.get('path')
    return send_file(cover_path, mimetype='image/jpeg')
```

**Problem:** Python liest JSON von Bash, liefert Datei → **Flask `send_file()` bleibt Python, Bash liefert Pfad**

---

## 3. Gap Analysis: Was fehlt in Bash?

| Feature | Python (Aktuell) | Bash (Aktuell) | Status | Priorität |
|---------|-----------------|----------------|--------|-----------|
| **MusicBrainz API Query** | ❌ Nicht vorhanden | ✅ `musicbrainz_query()` | ✅ Vollständig | - |
| **Release-Auswahl** | ✅ JSON-Schreiben (`selection.json`) | ⚠️ Nur `metadb_set_data()` | ⚠️ Fehlende JSON-Persistierung | 🔴 HOCH |
| **Cover-Art Download** | ✅ Bash-Delegation | ✅ `fetch_coverart()` existiert | ✅ Vollständig | - |
| **Track-Daten-Extraktion** | ❌ Nicht vorhanden | ❌ Nicht vorhanden | ❌ **FEHLT KOMPLETT** | 🔴 HOCH |
| **Label-Info-Extraktion** | ❌ Nicht vorhanden | ❌ Nicht vorhanden | ❌ **FEHLT KOMPLETT** | 🟡 MITTEL |
| **ISO-Mounting** | ✅ Python `os.walk()` | ❌ Nicht vorhanden | ❌ **FEHLT KOMPLETT** | 🔴 HOCH |
| **MP3-Track-Counting** | ✅ Python Loop | ❌ Nicht vorhanden | ❌ **FEHLT KOMPLETT** | 🔴 HOCH |
| **Barcode-Extraktion** | ❌ Nicht vorhanden | ❌ Nicht vorhanden | ❌ **FEHLT KOMPLETT** | 🟢 NIEDRIG |
| **Status-Validierung** | ❌ Nicht vorhanden | ❌ Nicht vorhanden | ❌ **FEHLT KOMPLETT** | 🟢 NIEDRIG |
| **Frontend-Datenstruktur** | ✅ JSON-Kombination | ❌ Nicht vorhanden | ❌ **FEHLT KOMPLETT** | 🟡 MITTEL |
| **Metadb-Integration** | ❌ Nicht vorhanden | ✅ `metadb_set_data()` | ✅ Vollständig | - |

---

## 4. Migrationsplan: Python → Bash

### Phase 1: Track-Daten-Extraktion (Priorität 🔴 HOCH, 4-6h)

**Ziel:** `musicbrainz_parse_selection()` extrahiert Track-Informationen aus MusicBrainz API Response

**Aufgaben:**
1. ✅ **Bereits vorhanden:** API-Query liefert `media[].tracks[]` (Zeile 219: `inc=artists+labels+recordings+media`)
2. ❌ **Fehlt:** Track-Loop in `musicbrainz_parse_selection()` implementieren
3. ❌ **Fehlt:** Track-Daten via `metadb_set_data()` speichern

**Implementation:**

```bash
# Zeilen 298-350 (nach "Update disc_label")
musicbrainz_parse_selection() {
    # ... (bestehender Code) ...
    
    # NEU: Extrahiere Track-Informationen
    local track_count=$(echo "$mb_json" | jq -r ".[$selected_index].media[0][\"track-count\"] // 0")
    log_debug "MusicBrainz: Track-Count: $track_count"
    
    # Setze Track-Count in metadb
    metadb_set_metadata "track_count" "$track_count"
    
    # Extrahiere Track-Liste
    for track_index in $(seq 0 $((track_count - 1))); do
        local track_number=$(echo "$mb_json" | jq -r ".[$selected_index].media[0].tracks[$track_index].number // \"0\"")
        local track_title=$(echo "$mb_json" | jq -r ".[$selected_index].media[0].tracks[$track_index].title // \"Unknown Track\"")
        local track_length=$(echo "$mb_json" | jq -r ".[$selected_index].media[0].tracks[$track_index].length // 0")
        
        # Konvertiere Millisekunden in MM:SS
        local track_length_sec=$((track_length / 1000))
        local track_minutes=$((track_length_sec / 60))
        local track_seconds=$((track_length_sec % 60))
        local track_duration=$(printf "%02d:%02d" "$track_minutes" "$track_seconds")
        
        # Setze Track-Daten in metadb
        metadb_set_data "track_${track_number}_title" "$track_title"
        metadb_set_data "track_${track_number}_duration" "$track_duration"
        metadb_set_data "track_${track_number}_length_ms" "$track_length"
        
        log_debug "MusicBrainz: Track $track_number: $track_title ($track_duration)"
    done
    
    # ... (restlicher Code) ...
}
```

**Metadb-Felder (neu):**
- `track_count` (Anzahl Tracks)
- `track_<N>_title` (Track-Titel)
- `track_<N>_duration` (MM:SS Format)
- `track_<N>_length_ms` (Millisekunden für Validierung)

---

### Phase 2: Label-Informationen (Priorität 🟡 MITTEL, 2-3h)

**Ziel:** Extrahiere Label, Catalog-Number, Barcode, Status

**Implementation:**

```bash
# In musicbrainz_parse_selection(), nach Track-Loop
local label=$(echo "$mb_json" | jq -r ".[$selected_index][\"label-info\"][0].label.name // \"\"")
local catalog_number=$(echo "$mb_json" | jq -r ".[$selected_index][\"label-info\"][0][\"catalog-number\"] // \"\"")
local barcode=$(echo "$mb_json" | jq -r ".[$selected_index].barcode // \"\"")
local status=$(echo "$mb_json" | jq -r ".[$selected_index].status // \"Official\"")
local country=$(echo "$mb_json" | jq -r ".[$selected_index].country // \"\"")

metadb_set_metadata "label" "$label"
metadb_set_metadata "catalog_number" "$catalog_number"
metadb_set_metadata "barcode" "$barcode"
metadb_set_metadata "release_status" "$status"
metadb_set_metadata "release_country" "$country"
```

**Metadb-Felder (neu):**
- `label` (Plattenlabel)
- `catalog_number` (Katalognummer)
- `barcode` (EAN/UPC)
- `release_status` (Official, Promo, Bootleg)
- `release_country` (Ländercode)

---

### Phase 3: ISO-Mounting & MP3-Counting (Priorität 🔴 HOCH, 5-7h)

**Ziel:** Bash übernimmt ISO-Mounting, MP3-Track-Counting

**Problem:** Python mounted ISO via `os.walk()`, zählt MP3-Dateien

**Lösung:** Neue Bash-Funktion in `libfiles.sh` oder `libaudio.sh`

**Implementation:**

```bash
# Neue Funktion in lib/libfiles.sh
# ===========================================================================
# mount_iso_readonly
# ---------------------------------------------------------------------------
# Funktion.: Mounted ISO-Datei read-only via loop-device
# Parameter: $1 = iso_path (Pfad zur ISO-Datei)
#            $2 = mount_point (optional, Default: /tmp/disk2iso_mount_$$)
# Rückgabe.: 0 = Erfolgreich gemounted, echo mount_point
#            1 = Fehler (ISO nicht gefunden, mount failed)
# Nutzt....: sudo mount -o loop,ro (benötigt /etc/sudoers Eintrag)
# ===========================================================================
mount_iso_readonly() {
    local iso_path="$1"
    local mount_point="${2:-/tmp/disk2iso_mount_$$}"
    
    # Validierung
    if [[ ! -f "$iso_path" ]]; then
        log_error "ISO nicht gefunden: $iso_path"
        return 1
    fi
    
    # Erstelle Mount-Point
    if [[ ! -d "$mount_point" ]]; then
        mkdir -p "$mount_point" || return 1
    fi
    
    # Mount via sudo (benötigt sudoers-Eintrag)
    if ! sudo mount -o loop,ro "$iso_path" "$mount_point" 2>/dev/null; then
        log_error "ISO-Mount fehlgeschlagen: $iso_path"
        return 1
    fi
    
    log_debug "ISO gemounted: $mount_point"
    echo "$mount_point"
    return 0
}

# ===========================================================================
# umount_iso
# ---------------------------------------------------------------------------
# Funktion.: Unmounted ISO-Datei
# Parameter: $1 = mount_point
# Rückgabe.: 0 = Erfolgreich unmounted
#            1 = Fehler
# ===========================================================================
umount_iso() {
    local mount_point="$1"
    
    if [[ ! -d "$mount_point" ]]; then
        return 0
    fi
    
    sudo umount "$mount_point" 2>/dev/null || return 1
    rmdir "$mount_point" 2>/dev/null
    
    log_debug "ISO unmounted: $mount_point"
    return 0
}

# ===========================================================================
# count_mp3_in_iso
# ---------------------------------------------------------------------------
# Funktion.: Zählt MP3-Dateien in ISO
# Parameter: $1 = iso_path
# Rückgabe.: 0 = Erfolgreich, echo Anzahl MP3-Dateien
#            1 = Fehler
# ===========================================================================
count_mp3_in_iso() {
    local iso_path="$1"
    local mount_point
    
    # Mount ISO
    mount_point=$(mount_iso_readonly "$iso_path") || return 1
    
    # Zähle MP3-Dateien
    local mp3_count
    mp3_count=$(find "$mount_point" -type f -iname "*.mp3" 2>/dev/null | wc -l)
    
    # Unmount
    umount_iso "$mount_point"
    
    echo "$mp3_count"
    return 0
}
```

**Python-Ersatz:** `search_musicbrainz_json()` ruft `count_mp3_in_iso()` auf

**Wichtig:** `/etc/sudoers` muss `disk2iso` User erlauben: `mount -o loop,ro` und `umount` ohne Passwort

---

### Phase 4: Frontend-Datenstruktur (Priorität 🟡 MITTEL, 3-4h)

**Ziel:** Bash erstellt kombinierte JSON-Struktur für Frontend

**Problem:** Python kombiniert `musicbrainz_releases.json` + `musicbrainz_selection.json`

**Lösung:** Neue Bash-Funktion `musicbrainz_get_frontend_data()`

**Implementation:**

```bash
# Neue Funktion in lib/libmusicbrainz.sh
# ===========================================================================
# musicbrainz_get_frontend_data
# ---------------------------------------------------------------------------
# Funktion.: Kombiniert musicbrainz_releases.json + selection.json zu Frontend-Datenstruktur
# Parameter: $1 = disc_id
# Rückgabe.: 0 = Erfolgreich, echo JSON-String
#            1 = Fehler (keine Daten)
# ===========================================================================
musicbrainz_get_frontend_data() {
    local disc_id="$1"
    local api_dir
    api_dir=$(get_api_dir) || return 1
    
    local releases_file="${api_dir}/musicbrainz_releases.json"
    local selection_file="${api_dir}/musicbrainz_selection.json"
    
    # Prüfe ob Dateien existieren
    if [[ ! -f "$releases_file" ]]; then
        echo '{"status": "no_data", "releases": []}'
        return 1
    fi
    
    # Lese Releases
    local releases_json=$(cat "$releases_file")
    
    # Lese Selection (falls vorhanden)
    local selection_status="unknown"
    local selected_index=0
    local confidence="unknown"
    local message=""
    
    if [[ -f "$selection_file" ]]; then
        selection_status=$(echo "$selection_json" | jq -r '.status // "unknown"')
        selected_index=$(echo "$selection_json" | jq -r '.selected_index // 0')
        confidence=$(echo "$selection_json" | jq -r '.confidence // "unknown"')
        message=$(echo "$selection_json" | jq -r '.message // ""')
    fi
    
    # Kombiniere zu Frontend-Struktur
    jq -n \
        --arg status "$selection_status" \
        --argjson releases "$releases_json" \
        --argjson index "$selected_index" \
        --arg confidence "$confidence" \
        --arg message "$message" \
        '{
            status: $status,
            releases: $releases.releases,
            disc_id: $releases.disc_id,
            track_count: $releases.track_count,
            selected_index: $index,
            confidence: $confidence,
            message: $message
        }'
    
    return 0
}
```

**Python-Ersatz:** `/api/musicbrainz/releases` ruft `musicbrainz_get_frontend_data()` via subprocess

---

### Phase 5: Python-Migration (Priorität 🔴 HOCH, 6-8h)

**Ziel:** Python-Endpoints werden reine Bash-Delegatoren

**Aufgaben:**

1. **`/api/musicbrainz/releases`** (Zeilen 562-580)
   - ❌ **Vorher:** Python kombiniert JSON-Dateien
   - ✅ **Nachher:** `subprocess.run(['bash', '-c', 'musicbrainz_get_frontend_data "$disc_id"'])`

2. **`/api/musicbrainz/select`** (Zeilen 632-660)
   - ❌ **Vorher:** Python schreibt `musicbrainz_selection.json`
   - ✅ **Nachher:** `subprocess.run(['bash', '-c', 'musicbrainz_save_selection "$index"'])`

3. **`/api/musicbrainz/manual`** (Zeilen 662-689)
   - ❌ **Vorher:** Python schreibt `musicbrainz_manual.json`
   - ✅ **Nachher:** `subprocess.run(['bash', '-c', 'musicbrainz_save_manual "$artist" "$album" "$year"'])`

4. **`/api/metadata/musicbrainz/search`** (Zeilen 1857-1950)
   - ❌ **Vorher:** Python mounted ISO, zählt MP3s, ruft Bash auf
   - ✅ **Nachher:** `subprocess.run(['bash', '-c', 'musicbrainz_search_with_mp3_count "$iso_path"'])`

**Neue Bash-Funktionen:**
- `musicbrainz_save_selection(index)` – Schreibt `musicbrainz_selection.json`
- `musicbrainz_save_manual(artist, album, year)` – Schreibt `musicbrainz_manual.json`
- `musicbrainz_search_with_mp3_count(iso_path)` – Vollständiger Search-Flow (Mount → Count → Query → Unmount)

---

## 5. Zeitaufwand & Prioritäten

| Phase | Aufwand | Priorität | Abhängigkeiten |
|-------|---------|-----------|----------------|
| Phase 1: Track-Daten | 4-6h | 🔴 HOCH | - |
| Phase 2: Label-Infos | 2-3h | 🟡 MITTEL | - |
| Phase 3: ISO-Mounting | 5-7h | 🔴 HOCH | `/etc/sudoers` Anpassung |
| Phase 4: Frontend-Datenstruktur | 3-4h | 🟡 MITTEL | - |
| Phase 5: Python-Migration | 6-8h | 🔴 HOCH | Phase 1-4 abgeschlossen |

**Gesamt:** 20-28 Stunden

---

## 6. Risiken & Blockers

### 6.1 Technische Risiken

| Risiko | Auswirkung | Mitigation |
|--------|-----------|------------|
| **sudoers-Konfiguration** | ISO-Mounting schlägt fehl | `/etc/sudoers` muss `mount -o loop,ro` + `umount` ohne Passwort erlauben |
| **Track-Count-Validierung** | MusicBrainz-Track-Count ≠ ISO-MP3-Count | Validierung in `musicbrainz_parse_selection()` (Warning statt Fehler) |
| **JSON-Parsing-Fehler** | MusicBrainz API ändert Struktur | Defensive `jq` mit Fallbacks (`// "Unknown"`) |
| **ISO-Mount-Timeouts** | Große ISOs (>700MB) | Timeout erhöhen (aktuell: 600s), Fortschritts-Logging |

### 6.2 Abhängigkeiten

- ✅ **libmetadb.sh**: Bereits committed (576c667), `metadb_set_data()` verfügbar
- ✅ **libintegrity.sh**: `check_module_dependencies()` mit [modulefiles] DB-Loading
- ✅ **libfolders.sh**: `get_module_folder_path()` für Cache/Covers
- ⚠️ **libfiles.sh**: `mount_iso_readonly()`, `count_mp3_in_iso()` **müssen implementiert werden**
- ⚠️ **/etc/sudoers**: Muss angepasst werden für passwordless `mount`/`umount`

---

## 7. Implementierungsempfehlung

### Reihenfolge (nach Priorität):

1. **Phase 3 (ISO-Mounting)** → Basis für MusicBrainz-Suche
   - Implementiere `mount_iso_readonly()`, `count_mp3_in_iso()` in libfiles.sh
   - Teste mit vorhandenen ISOs
   - Konfiguriere `/etc/sudoers`

2. **Phase 1 (Track-Daten)** → Metadb-Befüllung
   - Erweitere `musicbrainz_parse_selection()` um Track-Loop
   - Teste mit echten MusicBrainz API Responses
   - Validiere `metadb_get_data()` für Track-Felder

3. **Phase 4 (Frontend-Datenstruktur)** → Python-Vorbereitung
   - Implementiere `musicbrainz_get_frontend_data()`
   - Teste JSON-Output gegen Python-Erwartungen

4. **Phase 5 (Python-Migration)** → Finale Umstellung
   - Ersetze Python-Logik durch Bash-Delegation
   - Teste alle 6 Endpoints
   - Aktualisiere Frontend (falls notwendig)

5. **Phase 2 (Label-Infos)** → Zusatzdaten (optional)
   - Kann nachgelagert implementiert werden
   - Nicht kritisch für Grundfunktion

---

## 8. Nächste Schritte

### Sofort (diese Session):
- [ ] Lese `lib/libaudio.sh` für vorhandene ISO-Mounting-Logik (falls vorhanden)
- [ ] Prüfe `/etc/sudoers` für bestehende `mount`-Berechtigungen
- [ ] Implementiere `mount_iso_readonly()` in libfiles.sh

### Diese Woche:
- [ ] Phase 3 komplett (ISO-Mounting + MP3-Counting)
- [ ] Phase 1 komplett (Track-Daten-Extraktion)
- [ ] Test mit echten Audio-CDs

### Nächste 2 Wochen:
- [ ] Phase 4 + 5 (Frontend-Datenstruktur + Python-Migration)
- [ ] Integration-Tests
- [ ] Update `doc/04-1_Audio-CD.md` mit neuen Funktionen

---

## 9. Offene Fragen

1. **Gibt es bereits ISO-Mounting-Logik in libaudio.sh?** → Muss geprüft werden
2. **Sollte `mount_iso_readonly()` in libfiles.sh oder libaudio.sh?** → Empfehlung: libfiles.sh (allgemeiner Helper)
3. **Track-Count-Validierung strikt oder Warning?** → Empfehlung: Warning (MusicBrainz kann mehr/weniger Tracks haben als ISO)
4. **Soll Python `send_file()` für Cover bleiben?** → Ja, Flask-Spezifisch (Bash liefert nur Pfad)

---

**Autor:** GitHub Copilot (Claude Sonnet 4.5)  
**Review:** Pending
