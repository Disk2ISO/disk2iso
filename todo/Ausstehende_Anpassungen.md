# disk2iso - Ausstehende Anpassungen

**Stand:** 26. Januar 2026  
**Erstellt:** Automatische Konsolidierung aller TODO-Dateien  
**Quelle:** Analyse von ForNextRelease.md, Frontend-Modularisierung.md, GitHub-Issues.md, Metadata-Cache-DB.md, Metadata-PlugIn_Konzept.md

---

## � GITHUB ISSUES ZUSAMMENFASSUNG

**Stand:** 26. Januar 2026 (Online-Abgleich)  
**Gesamt:** 10 Open, 10 Closed

**OPEN (10):**
- 🔴 **3 kritische Bugs** (#11, #9, #4)
- 🟡 **3 Verbesserungen** (#15, #19, #10)
- 🟢 **3 Enhancements** (#22, #21, #6)
- ⚠️ **1 teilweise behoben** (#5) - Runtime-Tests ausstehend

**CLOSED (10):**
- ✅ #20 - Formatierungsproblem Fortschritt
- ✅ #18 - LOG oder CODE Fehler
- ✅ #17 - Fehlender Neustart
- ✅ #16 - Passwort Feld nicht verschlüsselt
- ✅ #14 - Menü verschwindet wenn Seite länger
- ✅ #13 - Anzeige zum Service
- ✅ #12 - Home Seite unruhig
- ✅ #8 - Einstellungen Ausgabeverzeichnis
- ✅ #7 - DVD/BD Metadaten funktioniert nicht

---

## �📋 ÜBERSICHT NACH PRIORITÄT

### 🔴 KRITISCH - Bugs (Sofort beheben)

#### 1. GitHub #11 - MQTT Meldungen kommen doppelt
**Bereich:** [lib/libmqtt.sh](../lib/libmqtt.sh)  
**Problem:** MQTT-Nachrichten werden doppelt gesendet  
**Mögliche Ursachen:**

- `publish_mqtt()` wird zweimal aufgerufen
- Mehrere MQTT-Clients aktiv
- Retain-Flag verursacht Echo

**Diagnose nötig:**

- MQTT-Logging aktivieren
- MQTT-Broker Logs prüfen
- Alle `publish_mqtt()` Aufrufe durchsuchen

---

#### 2. GitHub #9 - Anzeige von ISO Dateien
**Bereich:** [www/app.py](../www/app.py), [www/templates/archive.html](../www/templates/archive.html)  
**Problem:** ISO-Dateien werden nicht korrekt angezeigt im Archiv  
**Betroffene Dateien:**

- `www/app.py` - `/archive` Route
- `www/templates/archive.html`
- Möglicherweise `get_iso_files_by_type()` Funktion

**Diagnose nötig:** Detaillierte Beschreibung was genau nicht funktioniert

---

#### 3. GitHub #4 - Archiv - Metadaten hinzufügen funktioniert nicht
**Bereich:** [www/app.py](../www/app.py) - Archiv-Management  
**Problem:** Nachträgliches Hinzufügen von Metadaten über Web-UI schlägt fehl  
**Betroffene Dateien:**

- `www/app.py` - Metadata-Update Endpoints
- `www/templates/archive.html`

**Diagnose nötig:** Detaillierte Fehlerbeschreibung, Error-Logs

---

---

### 🟡 WICHTIG - Verbesserungen (Bald umsetzen)

#### 4. GitHub #15 - Fehlgeschlagene Kopiervorgänge
**Bereich:** [lib/libcommon.sh](../lib/libcommon.sh), [disk2iso.sh](../disk2iso.sh)  
**Features:**
- Wiederholungsversuche bei Fehlern
- Besseres Fehler-Logging
- Benachrichtigung via MQTT

**Betroffene Dateien:**
- `lib/libcommon.sh` - Copy-Funktionen
- `disk2iso.sh` - State-Machine
- `lib/libmqtt.sh` - Error-Notifications

---

#### 5. ForNextRelease - Auto-Cleanup Cronjob
**Bereich:** System-Wartung  
**Problem:**
- Fehlgeschlagene Operationen hinterlassen Temp-Ordner in `/media/iso/.temp/`
- Cover-Cache wächst unbegrenzt in `/opt/disk2iso/.temp/`
- Alte Logs füllen Festplatte

**Lösung:** Cronjob `/etc/cron.daily/disk2iso-cleanup`
```bash
#!/bin/bash
# Alte Temp-Operationen löschen (> 7 Tage)
find /media/iso/.temp -maxdepth 1 -type d -mtime +7 -name "*_*" -exec rm -rf {} \; 2>/dev/null

# Alte Cover-Cache löschen (> 30 Tage)
find /opt/disk2iso/.temp -name "cover_*.jpg" -mtime +30 -delete 2>/dev/null

# Alte Logs komprimieren (> 30 Tage)
find /media/iso/.log -name "disk2iso_*.log" -mtime +30 -exec gzip {} \; 2>/dev/null

# Komprimierte Logs löschen (> 90 Tage)
find /media/iso/.log -name "*.log.gz" -mtime +90 -delete 2>/dev/null
```

**Integration:** In `install.sh` installieren

---

#### 6. GitHub #19 - Archivierte Logs über WEB-UI öffnen
**Bereich:** [www/app.py](../www/app.py), [www/templates/logs.html](../www/templates/logs.html)  
**Problem:** Archivierte Logs können gesucht, aber nicht angezeigt werden

**Lösung:**
- Neue Route `/logs/view/<filename>` in app.py
- Link zu archivierten Logs in logs.html

---

---

### 🟢 MITTEL - Neue Features (Geplant)

#### 7. GitHub #10 - Feat. Anzeige kompakter machen
**Bereich:** [www/templates/](../www/templates/), [www/static/css/style.css](../www/static/css/style.css)  
**Ziel:** UI optimieren für weniger Scrolling

**Ideen:**
- Kollapsbare Sektionen
- Kompaktere Layouts
- Responsive Design verbessern

---

#### 8. GitHub #22 - Taggen von MP3 bei mehreren Interpreten
**Bereich:** [lib/libaudio.sh](../lib/libaudio.sh) (Metadata-Teil)  
**Komplexität:** MITTEL  
**Ziel:** Besseres Tagging bei "feat." Artists

**Beispiel:**
```
Aktuell:
Titel: "Driving Home for Christmas"
Artist: "Chris Rea feat. XYZ"

Soll werden:
- AlbumArtist: Chris Rea
- Artist: Chris Rea feat. XYZ
- Ordner: /Chris Rea/Album/Track.mp3
```

**Lösung:** MusicBrainz Artist-Credits nutzen

---

#### 9. GitHub #21 - Taggen von MP3 bei Samplern
**Bereich:** [lib/libaudio.sh](../lib/libaudio.sh) (Metadata-Teil)  
**Komplexität:** HOCH  
**Ziel:** Sampler mit "AlbumArtist: Various Artists" besser handhaben

**Beispiel:**
```
Aktuell (schlecht):
/Various Artists/Rock Christmas/01 - Driving Home.mp3

Soll werden:
/Chris Rea/Original Album/01 - Driving Home.mp3
```

**Logik:**
1. Erkenne `AlbumArtist == "Various Artists"`
2. Für jeden Track: Suche Original-Album des Künstlers
3. Erstelle Ordner: `/Artist/OriginalAlbum/Track.mp3`
4. Generiere Album-Cover pro Artist-Album

**Betroffene Dateien:**
- `lib/libaudio.sh` (Metadata-Teil)
- `lib/libfolders.sh` - Mehrere Ordner pro CD
- MusicBrainz API - Recording-Lookup

---

#### 10. GitHub #6 - DVD Metadaten
**Bereich:** [lib/libdvd.sh](../lib/libdvd.sh) (Metadata-Teil)  
**Beschreibung:** Details unklar - Issue-Beschreibung benötigt

**Status:** Offen - Detaillierte Anforderungen klären

---

### 🎯 OPTIONAL - Nice-to-Have Features

#### 11. ForNextRelease - Metadaten-Edit-Wrapper für normale User
**Bereich:** System-Tools  
**Problem:** ISOs/Metadaten gehören root:root, User können `.nfo` nicht direkt bearbeiten

**Lösung:** Helper-Script `/usr/local/bin/disk2iso-edit`
```bash
#!/bin/bash
case "$1" in
    nfo)
        sudo -u root nano "$2"
        ;;
    cover)
        sudo -u root cp "$2" "$3"
        ;;
esac
```

**Sudoers-Regel:**
```
%users ALL=(root) NOPASSWD: /usr/local/bin/disk2iso-edit
```

**Aufwand:** Mittel  
**Impact:** Niedrig - Quality-of-Life Verbesserung

---

#### 12. ForNextRelease - Audio-CD Normalization
**Bereich:** [lib/libaudio.sh](../lib/libaudio.sh)  
**Feature:** MP3-Lautstärke normalisieren mit ReplayGain

```bash
# Nach MP3-Konvertierung
if command -v mp3gain &>/dev/null; then
    log_message "INFO" "Normalisiere Lautstärke mit mp3gain..."
    mp3gain -r -k "$temp_dir"/*.mp3 2>&1 | tee -a "$LOGFILE"
fi
```

**Voraussetzung:** `mp3gain` installieren

---

#### 13. ForNextRelease - Email-Benachrichtigungen
**Bereich:** [lib/libcommon.sh](../lib/libcommon.sh)  
**Feature:** Email bei Operation-Ende (Erfolg/Fehler)

**Config:**
```bash
NOTIFY_EMAIL=""  # Leer = deaktiviert
```

**Implementation:**
```bash
send_notification() {
    local status=$1
    local disc_label=$2
    
    if [[ -n "$NOTIFY_EMAIL" ]]; then
        echo "Disc: $disc_label - Status: $status" | \
            mail -s "[disk2iso] Operation $status" "$NOTIFY_EMAIL"
    fi
}
```

---

#### 14. ForNextRelease - ISO-Scanning-Caching
**Bereich:** [www/app.py](../www/app.py)  
**Problem:** `/api/archive` scannt bei jedem Request alle ISOs neu

**Lösung:** Cache ISO-Liste für 60 Sekunden
```python
from functools import lru_cache
import time

_iso_cache = None
_iso_cache_time = 0

@app.route('/api/archive')
def api_archive():
    global _iso_cache, _iso_cache_time
    
    if time.time() - _iso_cache_time < 60 and _iso_cache:
        return jsonify(_iso_cache)
    
    # Scan durchführen...
    _iso_cache = result
    _iso_cache_time = time.time()
    
    return jsonify(result)
```

---

## 📚 LANGFRISTIGE PROJEKTE

### 15. Frontend-Modularisierung - Dynamisches JS-Loading
**Status:** Konzept vorhanden, nicht implementiert  
**Ziel:** Nur aktivierte Module laden JS-Dateien

**Komponenten:**
1. Backend: `/api/modules` Endpoint (Module-Status)
2. Frontend: `module-loader.js` (Zentrale Koordination)
3. Manifeste: `conf/lib-*.json` (Modul-Definitionen)

**Vorteile:**
- Keine unnötigen Downloads (deaktivierte Module)
- Keine Runtime-Fehler (fehlende APIs)
- Offline-fähig (gecachte Module)

**Siehe:** [Frontend-Modularisierung.md](Frontend-Modularisierung.md)

---

### 16. Metadata Cache-DB
**Status:** Konzept vorhanden, nicht implementiert  
**Ziel:** Lokale Metadaten-Datenbank für schnelle Suche ohne API-Calls

**Struktur:**
```
.temp/musicbrainz/
├── ronan_keating_ronan_de_2000_mercury_14tracks_9767fd7e.nfo
├── ronan_keating_ronan_de_2000_mercury_14tracks_9767fd7e-thumb.jpg
```

**Vorteile:**
- ✅ **10-40x schneller** (grep vs. API-Call)
- ✅ **API-schonend** (nur bei echten Neusuchen)
- ✅ **Offline-fähig** (Web-UI funktioniert ohne Internet)
- ✅ **Wiederverwendung** (zweite Supernatural-Disc → Instant-Results)

**Implementierungs-Phasen:**
1. Cache-Befüllung (2 Tage)
2. Cache-First-Suche (2 Tage)
3. Web-UI Integration (1 Tag)
4. Cache-Verwaltung (1 Tag)

**Siehe:** [Metadata-Cache-DB.md](Metadata-Cache-DB.md)

---

### 17. Plugin-System Architektur
**Status:** Teilweise implementiert (INI-basierte Manifeste)  
**Ziel:** Vollständige Modularität für ALLE Komponenten

**Bereits implementiert:**
- ✅ INI-basiertes Manifest-System für Module
- ✅ Einheitliche Dependency-Checks via `check_module_dependencies()`
- ✅ Modul-Selbstverwaltung (`*_SUPPORT` Flags)
- ✅ TMDB/MusicBrainz API-Konfiguration externalisiert

**Noch ausstehend:**
- ⏳ Backend-Routing Modularisierung (Flask Blueprints)
- ⏳ Frontend-Komponenten (DOM-Injection)
- ⏳ Vollständige Manifest-Dateien (`conf/lib-*.json`)

**Siehe:** [Metadata-PlugIn_Konzept.md](Metadata-PlugIn_Konzept.md)

---

## ⚠️ TEILWEISE ERLEDIGTE GITHUB ISSUES

Die folgenden Issues sind **Code fertig**, aber noch als OPEN auf GitHub:

### ⚠️ GitHub #5 - Audio CD - Meta Daten erfassen
**Status:** ⚠️ **Code implementiert, Runtime-Tests ausstehend**  
**GitHub-Status:** OPEN  
**Implementiert:** 18. Januar 2026

**Code fertig:**

- ✅ `check_audio_metadata_dependencies()` Funktion
- ✅ Runtime-Prüfung von jq, curl, eyeD3, id3v2
- ✅ User-Agent Header in MusicBrainz API-Calls (RFC-konform)
- ✅ URL-Encoding Funktion
- ✅ Cache-basierte API-Funktionen
- ✅ Artist-Sanitization für sichere Dateinamen

**Noch ausstehend:**

- ⏳ Laufzeit-Tests mit realen Audio-CDs
- ⏳ Log-Analyse bei Fehlern
- ⏳ MusicBrainz API Response prüfen
- ⏳ Issue auf GitHub schließen nach Tests

---

## ✅ KOMPLETT ERLEDIGTE GITHUB ISSUES

Die folgenden Issues sind **vollständig gelöst** und auf GitHub als CLOSED markiert:

### ✅ GitHub #20 - Formatierungsproblem Fortschritt
**Behoben:** Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:** Template korrigiert, Fortschrittsbalken zeigt korrekte Richtung  
**Verifikation:** ✅ UI zeigt Speicherbelegung korrekt an

---

### ✅ GitHub #18 - LOG oder CODE Fehler (Doppelter Slash im Pfad)
**Behoben:** 18. Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:** `"${OUTPUT_DIR%/}/"` in [lib/libfolders.sh:45](../lib/libfolders.sh#L45)  
**Verifikation:** ✅ Kein doppelter Slash mehr möglich

---

### ✅ GitHub #17 - Fehlender Neustart nach Config-Änderung
**Behoben:** 18. Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:**

- `apply_config_changes()` Funktion in [lib/libconfig.sh:190-275](../lib/libconfig.sh#L190-L275)
- `perform_service_restarts()` Funktion
- Intelligente Service-Neustarts basierend auf Config-Keys

**Verifikation:** ✅ Services werden automatisch neu gestartet

---

### ✅ GitHub #16 - Passwort Feld nicht verschlüsselt
**Behoben:** 18. Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:** `type="password"` in [www/templates/config.html:230](../www/templates/config.html#L230)  
**Verifikation:** ✅ Passwort-Feld ist maskiert

---

### ✅ GitHub #13 - Anzeige zum Service
**Behoben:** Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:** Service-Status Visualisierung implementiert  
**Verifikation:** ✅ Uptime und Status-Informationen werden angezeigt

---

### ✅ GitHub #12 - Home Seite unruhig
**Behoben:** Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:** UI-Updates optimiert, Flackern reduziert  
**Verifikation:** ✅ Sanfte Übergänge implementiert

---

### ✅ GitHub #8 - Einstellungen Ausgabeverzeichnis
**Behoben:** Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:** Ausgabeverzeichnis in Web-UI änderbar  
**Verifikation:** ✅ Path-Validierung funktioniert

---

### ✅ GitHub #7 - DVD/BD Metadaten funktioniert nicht
**Behoben:** Januar 2026  
**GitHub-Status:** ✅ CLOSED  
**Lösung:** TMDB-Integration komplett überarbeitet  
**Verifikation:** ✅ Metadata-Abruf funktioniert

---

## 📚 ABGESCHLOSSENE AUFGABEN (NICHT GITHUB)

Die folgenden Dateien enthalten **nur erledigte Aufgaben** und wurden archiviert:

### ✅ Logging-Konvertierung.md
**Status:** ✅ Vollständig abgeschlossen (20. Januar 2026)  
**Aufgabe:** Alle 248 `log_message` Aufrufe auf kategorisierte Logging-Funktionen umgestellt
- log_error: 58× (23%)
- log_warning: 14× (6%)
- log_info: 176× (71%)

**Ergebnis:** System läuft produktiv, keine weiteren Aufgaben

---

### ✅ Metadata-BEFORE-vs-AFTER.md
**Status:** ✅ Vollständig implementiert (19.-20. Januar 2026)  
**Aufgabe:** Metadata-Abfrage VOR Copy-Vorgang durchführen

**Implementiert:**
- ✅ Audio-CD (MusicBrainz): BEFORE Copy mit Modal, Countdown, Skip-Button
- ✅ DVD/Blu-ray (TMDB): BEFORE Copy mit Modal, Countdown, Skip-Button
- ✅ Frontend: index.js Status-Handling, Auto-Polling alle 3 Sek
- ✅ Config: `METADATA_SELECTION_TIMEOUT` (0-300 Sek, Default: 60)

**Ausstehend:** Systematische Tests mit echten Discs (Phase 4)

---

### ✅ load-order-analysis.md
**Status:** ✅ Analyse abgeschlossen und umgesetzt (26. Januar 2026)  
**Aufgabe:** Ladereihenfolge vs. Prüfreihenfolge analysieren und korrigieren

**Umgesetzt:**
- Optimale Ladereihenfolge implementiert
- Prüfreihenfolge an Ladereihenfolge angepasst
- Abhängigkeiten dokumentiert

**Keine weiteren Aufgaben**

---

### ✅ module_dependencies_analysis.md
**Status:** ✅ Analyse abgeschlossen (26. Januar 2026)  
**Aufgabe:** Modul-Abhängigkeiten dokumentieren

**Ergebnis:** 
- Abhängigkeits-Matrix erstellt
- Kritische Pfade identifiziert
- Defensive Programmierung dokumentiert

**Keine weiteren Aufgaben**

---

## 🔧 HILFS-SCRIPTS (Archiviert)

Die folgenden Dateien sind **Einmal-Tools** und können gelöscht werden:

### convert_logging.py
**Status:** Erfolgreich ausgeführt, nicht mehr benötigt  
**Zweck:** Automatische Konvertierung von log_message zu kategorisierten Funktionen  
**Ergebnis:** 248 Konvertierungen durchgeführt

### convert-logging.sh
**Status:** Nicht verwendet, wurde durch Python-Script ersetzt  
**Kann gelöscht werden**

---

## � PYTHON-BASH-INTEGRATION (NEU - 27. Januar 2026)

### Hintergrund
Nach Implementierung von `libmetadb.sh` (Commit 576c667) muss das Python-Backend an die neue modulare Bash-Struktur angepasst werden. **Ziel:** Python wird reiner HTTP-Gateway/Übersetzer zwischen Web-UI und Bash-Modulen.

---

### **PHASE 1: Archive-Metadata via libmetadb.sh** 🔴 KRITISCH
**Aufwand:** 4-6 Stunden  
**Priorität:** 🔴 HOCH  
**Löst:** Basis für GitHub #4

**Problem:**
- Python parst .nfo-Dateien manuell (app.py:238-254)
- Keine Nutzung von `metadb_export_json()`
- Duplikation zwischen Python-Parsing und Bash-NFO-Logik

**Lösung:**

1. **Neue Bash-Funktionen in lib/libmetadb.sh:**
   ```bash
   metadb_load_from_nfo()      # Lade .nfo in DISC_METADATA + DISC_DATA
   archive_get_iso_metadata_json()  # Export Metadaten als JSON für Python
   ```

2. **Python-Refactoring in app.py:**
   ```python
   # ERSETZE: Manuelle NFO-Parsing-Schleife
   # MIT: Bash-Aufruf
   def get_iso_metadata_via_bash(iso_path):
       script = """
       source lib/libmetadb.sh
       archive_get_iso_metadata_json "{iso_path}"
       """
       result = subprocess.run(['/bin/bash', '-c', script], ...)
       return json.loads(result.stdout)
   ```

**Vorteile:**
- ✅ XML + Key-Value NFO unterstützt
- ✅ Konsistente Metadaten-API
- ✅ -30 Zeilen Python-Code

**Betroffene Dateien:**
- `lib/libmetadb.sh` (erweitern)
- `www/app.py` - `get_iso_files_by_type()` (refactoring)

---

### **PHASE 2: TMDB-Integration vereinfachen** 🔴 HOCH
**Aufwand:** 3-4 Stunden  
**Priorität:** 🔴 HOCH  
**Impact:** -60 Zeilen Python

**Problem:**
- Python macht TMDB-API-Calls mit `requests` (app.py:1621-1800)
- Poster-Downloads in Python
- JSON-Parsing-Duplikation (Python + Bash)

**Lösung:**

1. **Bash-Funktion in lib/libtmdb.sh:**
   ```bash
   tmdb_search_for_archive()  # Vollständige TMDB-Suche + Poster-Download
   ```

2. **Python-Vereinfachung:**
   ```python
   # VORHER: 80 Zeilen (API-Call, Poster-Download, Parsing)
   # NACHHER: 20 Zeilen (Bash-Aufruf + JSON-Rückgabe)
   @app.route('/api/metadata/tmdb/search', methods=['POST'])
   def api_tmdb_search():
       result = subprocess.run(['/bin/bash', '-c', 
           'source lib/libtmdb.sh; tmdb_search_for_archive ...'])
       return jsonify(json.loads(result.stdout))
   ```

**Vorteile:**
- ✅ -60 Zeilen Python
- ✅ Konsistente TMDB-API (Service + Web-UI)
- ✅ Wiederverwendbar in anderen Kontexten

**Betroffene Dateien:**
- `lib/libtmdb.sh` (erweitern)
- `www/app.py` - `api_tmdb_search()` (vereinfachen)

---

### **PHASE 3: MusicBrainz-Integration vereinfachen** 🟡 MITTEL
**Aufwand:** 2-3 Stunden  
**Priorität:** 🟡 MITTEL  
**Impact:** -40 Zeilen Python

**Lösung:**
Analog zu Phase 2 - TMDB

1. **Bash-Funktion in lib/libmusicbrainz.sh:**
   ```bash
   musicbrainz_search_for_archive()
   ```

2. **Python-Vereinfachung:**
   - Entferne Cover-Download-Logik
   - Delegiere an Bash

**Betroffene Dateien:**
- `lib/libmusicbrainz.sh` (erweitern)
- `www/app.py` - MusicBrainz-Endpoints (vereinfachen)

---

### **PHASE 4: Update-Metadata Endpoint (GitHub #4)** 🔴 KRITISCH
**Aufwand:** 4-6 Stunden  
**Priorität:** 🔴 HOCH  
**Löst:** GitHub #4 komplett

**Problem:**
- Kein `/api/archive/update-metadata` Endpoint vorhanden
- User können Metadaten im Archiv nicht bearbeiten

**Lösung:**

1. **Bash-Funktion in lib/libmetadb.sh:**
   ```bash
   archive_update_metadata()  # Lädt JSON → metadb → NFO-Export
   ```

2. **Neuer Python-Endpoint:**
   ```python
   @app.route('/api/archive/update-metadata', methods=['POST'])
   def api_archive_update_metadata():
       data = request.get_json()
       script = f"""
       source lib/libmetadb.sh
       archive_update_metadata "{iso_path}" '{json_metadata}'
       """
       result = subprocess.run(['/bin/bash', '-c', script], ...)
       return jsonify({'success': True, 'new_path': result.stdout})
   ```

3. **Frontend-Integration:**
   - `www/static/js/archive.js` - Bestehende Modal nutzen
   - POST zu neuem Endpoint

**Vorteile:**
- ✅ GitHub #4 vollständig gelöst
- ✅ Nutzt libmetadb.sh konsistent
- ✅ Optional: ISO-Umbenennung basierend auf neuen Metadaten

**Betroffene Dateien:**
- `lib/libmetadb.sh` (erweitern)
- `www/app.py` (neuer Endpoint)
- `www/static/js/archive.js` (Hook zu neuem Endpoint)

---

### **PHASE 5: ISO-Scanning via Bash** 🟢 OPTIONAL
**Aufwand:** 6-8 Stunden  
**Priorität:** 🟢 NIEDRIG  
**Impact:** -55 Zeilen Python, Performance-Optimierung

**Problem:**
- Python macht `os.walk()` + Datei-Statistiken (app.py:215-270)
- Langsam bei großen Archiven
- Duplikation von Logik

**Lösung:**

1. **Neue Bash-Bibliothek lib/libarchive.sh:**
   ```bash
   archive_scan_isos_json()  # Scannt ISOs, nutzt metadb für Metadaten
   ```

2. **Python wird minimal:**
   ```python
   def get_iso_files_by_type(path):
       result = subprocess.run(['/bin/bash', '-c',
           'source lib/libarchive.sh; archive_scan_isos_json ...'])
       return json.loads(result.stdout)
   ```

**Vorteile:**
- ✅ -55 Zeilen Python
- ✅ Potentiell schneller (paralleles find)
- ✅ Caching in Bash möglich

**Betroffene Dateien:**
- `lib/libarchive.sh` (neu)
- `www/app.py` - `get_iso_files_by_type()` (ersetzen)

---

### **ZUSAMMENFASSUNG Python-Bash-Integration**

| Phase | Aufwand | Impact | Priorität | Löst |
|-------|---------|--------|-----------|------|
| **1 - Archive-Metadata** | 4-6h | ⭐⭐⭐⭐⭐ | 🔴 HOCH | Basis #4 |
| **2 - TMDB** | 3-4h | ⭐⭐⭐⭐ | 🔴 HOCH | -60 Zeilen |
| **3 - MusicBrainz** | 2-3h | ⭐⭐⭐ | 🟡 MITTEL | -40 Zeilen |
| **4 - Update-Endpoint** | 4-6h | ⭐⭐⭐⭐⭐ | 🔴 HOCH | #4 komplett |
| **5 - ISO-Scanning** | 6-8h | ⭐⭐⭐ | 🟢 NIEDRIG | -55 Zeilen |
| **GESAMT** | 19-27h | - | - | #4 + -155 Zeilen |

**Gesamtergebnis nach allen Phasen:**
- ✅ Python: -155 bis -200 Zeilen Code
- ✅ Python wird reines HTTP-Gateway
- ✅ Alle Logik in testbaren Bash-Modulen
- ✅ `metadb_export_json()` = Single Source of Truth
- ✅ GitHub #4 vollständig gelöst

---

## 📋 EMPFOHLENE ARBEITSREIHENFOLGE

### Sofort (diese Woche):

1. **Python-Bash Phase 1** (4-6h) - Archive-Metadata via libmetadb.sh
2. **Python-Bash Phase 4** (4-6h) - Update-Metadata Endpoint → **GitHub #4 GELÖST** ✅
3. **#11 MQTT Debug** (2 Std) - Logging aktivieren, Broker-Logs prüfen

### Kurzfristig (nächste 2 Wochen):

4. **Python-Bash Phase 2** (3-4h) - TMDB-Integration vereinfachen (-60 Zeilen)
5. **Python-Bash Phase 3** (2-3h) - MusicBrainz-Integration vereinfachen (-40 Zeilen)
6. **#5 Runtime-Tests + GitHub schließen** (4 Std) - Audio-CD mit echten Discs testen
7. **Auto-Cleanup Cronjob** (1 Tag) - install.sh erweitern
8. **#15 Fehlerbehandlung** (2 Tage) - Retry-Logik implementieren
9. **#19 Archivierte Logs** (1 Tag) - Neue Route + Template

### Mittelfristig (nächste 4 Wochen):

10. **#9 ISO-Anzeige Debug** (4 Std) - Detaillierte Diagnose
11. **#10 Kompaktere Anzeige** (2 Tage) - Kollapsbare Sektionen
12. **#6 DVD Metadaten** (Details klären, dann umsetzen)
13. **Python-Bash Phase 5** (6-8h) - ISO-Scanning via Bash (OPTIONAL)

### Langfristig (nächste 3 Monate):

14. **Frontend-Modularisierung** (1 Woche) - Dynamisches JS-Loading
15. **Metadata Cache-DB** (1 Woche) - 10-40x schneller
16. **Plugin-System Backend** (2 Wochen) - Flask Blueprints

### Features (nach Bedarf):

17. **#22 MP3 feat. Artists** (1 Tag mit libmetadb.sh) - MusicBrainz Artist-Credits
18. **#21 MP3 Sampler** (1 Woche mit libmetadb.sh) - Komplexe MusicBrainz-Logik

---

## 📝 DATEIEN ZUM LÖSCHEN

Nach Erstellung dieser konsolidierten Übersicht können **folgende Dateien gelöscht werden**:

- ❌ `convert_logging.py` - Script wurde erfolgreich ausgeführt
- ❌ `convert-logging.sh` - Wurde nicht verwendet
- 📁 **Archivieren** (nach doc/archive/):
  - `Logging-Konvertierung.md` - Alle Aufgaben erledigt
  - `Metadata-BEFORE-vs-AFTER.md` - Implementierung abgeschlossen
  - `load-order-analysis.md` - Analyse umgesetzt
  - `module_dependencies_analysis.md` - Analyse abgeschlossen

**Behalten:**
- ✅ `ForNextRelease.md` - Enthält noch offene Features
- ✅ `Frontend-Modularisierung.md` - Konzept für zukünftiges Feature
- ✅ `GitHub-Issues.md` - Aktive Bug-Tracking-Liste
- ✅ `Metadata-Cache-DB.md` - Konzept für zukünftiges Feature
- ✅ `Metadata-PlugIn_Konzept.md` - Konzept für zukünftiges Feature
- ✅ `Ausstehende_Anpassungen.md` - Diese Datei (Master-Übersicht)

---

## 📝 CHANGELOG

### 27. Januar 2026
- ✅ **libmetadb.sh implementiert** (Commit 576c667)
  - In-Memory Metadaten-Datenbank mit CRUD-API
  - NFO-Export für Audio/Video/Data
  - JSON-Export für Python-Integration
  - Provider-Refactoring (libmusicbrainz.sh, libtmdb.sh, libaudio.sh)
  - -300 Zeilen Code-Duplikation entfernt
  
- 📋 **Python-Bash-Integration geplant** (5 Phasen, 19-27h)
  - Phase 1-4: KRITISCH (GitHub #4 Lösung)
  - Phase 5: Optional
  - Ziel: Python als reines HTTP-Gateway

### 26. Januar 2026
- Initiale Konsolidierung aller TODO-Dateien

---

**Zuletzt aktualisiert:** 27. Januar 2026  
**Nächste Aktualisierung:** Nach Abschluss einer Aufgabe aus der Liste
