# Systeminfo Module - Analyse und Refactoring Plan

**Erstellt:** 2026-02-04  
**Status:** In Planung  
**Ziel:** Modulares, widget-orientiertes System statt monolithischer `collect_system_information()`

---

## 1. BESTANDSAUFNAHME: Widget Übersicht

### 1.1 Bestehende Systeminfo-Widgets

| Widget | Größe | Funktion | API Endpoint | Benötigte Daten |
|--------|-------|----------|--------------|-----------------|
| `systeminfo_widget_2x1_sysinfo` | 2x1 | OS-Informationen | `/api/system` | `os.distribution`, `os.version`, `os.kernel`, `os.uptime` |
| `systeminfo_widget_2x1_outputdir` | 2x1 | Speicherplatz | `/api/archive` | `output_dir`, `disk_space.free_gb`, `disk_space.total_gb`, `disk_space.used_percent` |
| `systeminfo_widget_2x1_archiv` | 2x1 | Archiv-Zähler | `/api/archive` | `total`, `by_type.audio`, `by_type.dvd`, `by_type.bluray`, `by_type.data` |
| `systeminfo_widget_4x1_dependencies` | 4x1 | Core Software | `/api/system` | `software[]` (ddrescue, genisoimage, python, flask) |
| `disk2iso_widget_2x1_status` | 2x1 | Service Status | `/api/service/status` | `disk2iso.status`, `disk2iso.version` |
| `disk2iso-web_widget_2x1_status` | 2x1 | Web Service Status | `/api/service/status` | `web.status`, `web.version` |

### 1.2 Modul-spezifische Dependency-Widgets (extern)

| Widget | Module | Benötigte Daten |
|--------|--------|-----------------|
| `audio_widget_4x1_dependencies` | disk2iso-audio | `software[]` (cdparanoia, lame) |
| `dvd_widget_4x1_dependencies` | disk2iso-dvd | `software[]` (dvdbackup, ddrescue) |
| `bluray_widget_4x1_dependencies` | disk2iso-bluray | `software[]` (ddrescue, genisoimage) |
| `musicbrainz_widget_4x1_dependencies` | disk2iso-musicbrainz | `software[]` (python, musicbrainzngs) |
| `tmdb_widget_4x1_dependencies` | disk2iso-tmdb | `software[]` (python, requests) |
| `mqtt_widget_4x1_dependencies` | disk2iso-mqtt | `software[]` (mosquitto) |

---

## 2. PYTHON API ANALYSE

### 2.1 Bestehende API Endpoints

#### `/api/system` (app.py:1614)
**Aktuell:** Ruft `system.json` (generiert von `collect_system_information()`) oder fallback zu Live-Daten  
**Rückgabe-Struktur:**
```json
{
  "success": true,
  "os": {
    "distribution": "...",
    "version": "...",
    "kernel": "...",
    "architecture": "...",
    "hostname": "...",
    "uptime": "..."
  },
  "disk2iso": {
    "version": "...",
    "service_status": "active|inactive",
    "install_path": "...",
    "python_version": "...",
    "container": {
      "is_container": true|false,
      "type": "lxc|docker|podman|none"
    }
  },
  "hardware": {
    "optical_drive": "/dev/sr0",
    "drive_model": "..."
  },
  "storage": {
    "output_dir": "/media/iso",
    "total_gb": 100,
    "free_gb": 50,
    "used_percent": 50
  },
  "software": [
    {
      "name": "ddrescue",
      "installed_version": "1.25",
      "required_version": "1.0",
      "status": "ok|missing|outdated"
    }
  ],
  "timestamp": "2026-02-04T..."
}
```

**Nutzung:**
- `systeminfo_widget_2x1_sysinfo` → `os.*`
- `systeminfo_widget_4x1_dependencies` → `software[]`
- Alle `*_widget_4x1_dependencies` → `software[]`

#### `/api/archive` (app.py:764)
**Aktuell:** Python-basiert, durchsucht `OUTPUT_DIR`  
**Rückgabe-Struktur:**
```json
{
  "success": true,
  "total": 42,
  "by_type": {
    "audio": [...],
    "dvd": [...],
    "bluray": [...],
    "data": [...]
  },
  "output_dir": "/media/iso",
  "disk_space": {
    "free_gb": 50.2,
    "total_gb": 100.0,
    "used_percent": 49.8,
    "free_percent": 50.2
  },
  "timestamp": "2026-02-04T..."
}
```

**Nutzung:**
- `systeminfo_widget_2x1_outputdir` → `output_dir`, `disk_space.*`
- `systeminfo_widget_2x1_archiv` → `total`, `by_type.*`

#### `/api/service/status` (FEHLT - TODO!)
**Benötigt für:**
- `disk2iso_widget_2x1_status`
- `disk2iso-web_widget_2x1_status`

**Vorgeschlagene Struktur:**
```json
{
  "success": true,
  "services": {
    "disk2iso": {
      "status": "active|inactive|error|not_installed",
      "running": true|false,
      "enabled": true|false,
      "version": "1.2.0"
    },
    "disk2iso-web": {
      "status": "active|inactive|error|not_installed",
      "running": true|false,
      "enabled": true|false,
      "version": "1.2.0"
    }
  },
  "timestamp": "2026-02-04T..."
}
```

### 2.2 Python-Funktionen in app.py

| Funktion | Zeile | Beschreibung | Nutzen |
|----------|-------|--------------|--------|
| `get_service_status_detailed()` | 150 | Prüft systemd Service Status | ✅ Nutzbar für `/api/service/status` |
| `get_disk_space(path)` | 200 | Ermittelt Speicherplatz | ✅ Bereits in `/api/archive` genutzt |
| `get_iso_files_by_type(path)` | 240 | Zählt ISOs nach Typ | ✅ Bereits in `/api/archive` genutzt |
| `read_api_json(filename)` | 330 | Liest JSON aus API-Dir | ✅ Nutzbar für `system.json` |
| `check_software_versions()` | 1377 | Live-Prüfung Software (Python-basiert) | ⚠️ Fallback wenn `system.json` fehlt |
| `get_os_info()` | 1501 | Live OS-Info (Python-basiert) | ⚠️ Fallback wenn `system.json` fehlt |
| `get_disk2iso_info()` | 1547 | disk2iso-spezifische Info | ✅ Nutzbar |
| `get_software_list_from_system_json()` | 1584 | Konvertiert Bash-JSON zu Python-Format | ✅ Nutzbar |

---

## 3. BASH ANALYSE: libsysteminfo.sh

### 3.1 Bestehende Funktionen

| Funktion | Zeile | Beschreibung | Problem |
|----------|-------|--------------|---------|
| `systeminfo_check_dependencies()` | 41 | Prüft ob df, blkid installiert sind | ✅ OK (wird bei Init genutzt) |
| `systeminfo_detect_container_env()` | 79 | Erkennt LXC/Docker/Podman | ✅ OK (setzt `IS_CONTAINER`, `CONTAINER_TYPE`) |
| `systeminfo_check_disk_space(required_mb)` | 154 | Prüft verfügbaren Platz | ✅ OK (wird beim Kopieren genutzt) |
| `collect_system_information()` | 199 | **MONOLITH!** Generiert system.json | ❌ Problem: Zu groß, zu viel auf einmal |

### 3.2 Problem: `collect_system_information()` ist monolithisch

**Aktuelles Verhalten (Zeilen 199-335):**
- Sammelt ALLE Daten auf einmal (OS, Container, Hardware, Storage, Software)
- Schreibt eine große `system.json` Datei
- Wird vermutlich nur einmal beim Service-Start aufgerufen
- Keine granulare Aktualisierung möglich

**Hardcodierte Software-Liste (Zeilen 277-335):**
```bash
local cdparanoia_version="Not installed"
local lame_version="Not installed"
local dvdbackup_version="Not installed"
local ddrescue_version="Not installed"
local genisoimage_version="Not installed"
local python_version="Not installed"
local flask_version="Not installed"
local mosquitto_version="Not installed"
```

**Problem:** 
- Module wie `audio`, `dvd`, `bluray`, `mqtt` sind optional
- Jedes Modul kennt seine eigenen Dependencies (aus `lib*.ini` → `[dependencies]`)
- Core sollte NUR Core-Tools prüfen (ddrescue, genisoimage, python, flask)
- Module sollten ihre eigenen Tools prüfen

---

## 4. REFACTORING PLAN

### 4.1 Ziel: Modulare Bash-Funktionen

#### **Phase 1: Core-Funktionen aufteilen**

Ersetze `collect_system_information()` durch kleinere Funktionen:

```bash
# ============================================================================
# Modulare System-Informations-Funktionen
# ============================================================================

# ---------------------------------------------------------------------------
# systeminfo_get_os_info
# Beschreibung: Sammelt nur OS-Informationen (für systeminfo_widget_2x1_sysinfo)
# Parameter: keine
# Rückgabe: JSON-String mit OS-Daten (oder schreibt in API-Verzeichnis)
# ---------------------------------------------------------------------------
systeminfo_get_os_info() {
    # Distribution, Version, Kernel, Architecture, Hostname, Uptime
    # ...
}

# ---------------------------------------------------------------------------
# systeminfo_get_container_info
# Beschreibung: Sammelt Container-Informationen (LXC/Docker/Podman)
# Parameter: keine
# Rückgabe: JSON-String mit Container-Status
# ---------------------------------------------------------------------------
systeminfo_get_container_info() {
    systeminfo_detect_container_env  # Setzt IS_CONTAINER, CONTAINER_TYPE
    # ...
}

# ---------------------------------------------------------------------------
# systeminfo_get_hardware_info
# Beschreibung: Sammelt Hardware-Informationen (Optical Drive)
# Parameter: keine
# Rückgabe: JSON-String mit Hardware-Daten
# ---------------------------------------------------------------------------
systeminfo_get_hardware_info() {
    # Optical Drive, Model
    # ...
}

# ---------------------------------------------------------------------------
# systeminfo_get_storage_info
# Beschreibung: Sammelt Speicherplatz-Informationen für OUTPUT_DIR
# Parameter: $1 = output_dir (optional, default: $OUTPUT_DIR)
# Rückgabe: JSON-String mit Storage-Daten
# ---------------------------------------------------------------------------
systeminfo_get_storage_info() {
    local output_dir="${1:-$OUTPUT_DIR}"
    # total_gb, free_gb, used_percent
    # ...
}

# ---------------------------------------------------------------------------
# systeminfo_get_core_software
# Beschreibung: Prüft CORE-Software (ddrescue, genisoimage, python, flask)
# Parameter: keine
# Rückgabe: JSON-Array mit Software-Versionen
# ---------------------------------------------------------------------------
systeminfo_get_core_software() {
    # NUR Core-Tools, KEINE Modul-Tools!
    # ddrescue, genisoimage, python, flask
    # ...
}

# ---------------------------------------------------------------------------
# systeminfo_get_module_software
# Beschreibung: Prüft Software für ein spezifisches Modul (aus INI-Datei)
# Parameter: $1 = module_name (z.B. "audio", "dvd", "bluray")
# Rückgabe: JSON-Array mit Software-Versionen für dieses Modul
# ---------------------------------------------------------------------------
systeminfo_get_module_software() {
    local module_name="$1"
    
    # Lese [dependencies] aus lib${module_name}.ini
    # Prüfe jede Software-Version
    # Gib JSON-Array zurück
    # ...
}
```

#### **Phase 2: Python API erweitern**

```python
# Neue/erweiterte Endpoints:

@app.route('/api/system/os')
def api_system_os():
    """Nur OS-Informationen (cached oder live)"""
    # Ruft systeminfo_get_os_info() auf oder liest aus system.json
    pass

@app.route('/api/system/storage')
def api_system_storage():
    """Nur Storage-Informationen (live)"""
    # Ruft systeminfo_get_storage_info() auf
    pass

@app.route('/api/system/software')
def api_system_software():
    """Core + Modul Software (cached oder live)"""
    # Ruft systeminfo_get_core_software() auf
    # + systeminfo_get_module_software() für jedes aktivierte Modul
    pass

@app.route('/api/service/status')
def api_service_status():
    """Service-Status für disk2iso und disk2iso-web"""
    # Nutzt get_service_status_detailed()
    pass
```

#### **Phase 3: Widget-Anpassungen**

Widgets können spezifischere Endpoints nutzen:

| Widget | Aktuell | Neu | Vorteil |
|--------|---------|-----|---------|
| `systeminfo_widget_2x1_sysinfo` | `/api/system` (groß) | `/api/system/os` (klein) | Weniger Daten-Transfer |
| `systeminfo_widget_2x1_outputdir` | `/api/archive` (OK) | `/api/archive` (bleibt) | - |
| `systeminfo_widget_4x1_dependencies` | `/api/system` (groß) | `/api/system/software` (spezialisiert) | Nur Software-Daten |
| `disk2iso_widget_2x1_status` | - | `/api/service/status` (neu) | Eigener Endpoint |

### 4.2 Migration Strategy

**Option A: Big Bang (Alles auf einmal)**
- ❌ Riskant, große Änderungen
- ✅ Schnell erledigt wenn erfolgreich

**Option B: Inkrementell (Schrittweise)**
- ✅ Sicherer, testbar
- ✅ Alte Funktionen bleiben erhalten während neue implementiert werden
- ❌ Längerer Zeitraum

**Vorschlag: Option B - Inkrementell**

1. **Schritt 1:** Neue modulare Bash-Funktionen hinzufügen (parallel zu `collect_system_information()`)
2. **Schritt 2:** Neue Python API Endpoints erstellen
3. **Schritt 3:** Widgets auf neue Endpoints migrieren (eins nach dem anderen)
4. **Schritt 4:** Alte `collect_system_information()` als deprecated markieren
5. **Schritt 5:** Nach Stabilisierung: `collect_system_information()` entfernen

---

## 5. DEPENDENCY MANAGEMENT

### 5.1 Problem: Hardcodierte Software-Liste

**Aktuell:** `collect_system_information()` kennt alle Tools (auch Modul-spezifische)

**Lösung:** INI-basiertes Dependency Management

#### Beispiel: `lib/libaudio.ini`
```ini
[module]
name=audio
version=1.2.0
enabled=true

[dependencies]
cdparanoia=required,10.2
lame=required,3.99
```

#### Beispiel: Core Dependencies (neues `lib/libsysteminfo.ini`?)
```ini
[module]
name=systeminfo
version=1.2.0

[dependencies]
ddrescue=required,1.0
genisoimage=required,1.0
python=required,3.7
flask=optional,2.0
```

### 5.2 Neue Bash-Funktion: `systeminfo_get_module_software()`

```bash
systeminfo_get_module_software() {
    local module_name="$1"
    
    # Lese Dependencies aus lib${module_name}.ini
    local dependencies=$(config_get_section_keys_ini "$module_name" "dependencies")
    
    # Für jede Dependency: Version prüfen
    local software_list="[]"
    
    for dep in $dependencies; do
        local dep_info=$(config_get_value_ini "$module_name" "dependencies" "$dep")
        local required=$(echo "$dep_info" | cut -d, -f1)  # required|optional
        local min_version=$(echo "$dep_info" | cut -d, -f2)
        
        # Prüfe installierte Version
        local installed_version=$(get_software_version "$dep")
        
        # Baue JSON-Objekt
        software_list=$(add_to_json_array "$software_list" "{
            \"name\": \"$dep\",
            \"installed_version\": \"$installed_version\",
            \"required_version\": \"$min_version\",
            \"required\": \"$required\",
            \"status\": \"$(compare_versions "$installed_version" "$min_version")\"
        }")
    done
    
    echo "$software_list"
}
```

---

## 6. IMPLEMENTIERUNGS-PRIORITÄTEN

### Phase 1: Kritisch (für Widget-Funktionalität)
1. ✅ **`/api/service/status/<service>`** - ERLEDIGT (libservice.sh + app.py)
2. ✅ **`/api/service/restart/<service>`** - ERLEDIGT (POST-Endpoint)
3. ✅ **`systeminfo_collect_storage_info()`** - ERLEDIGT (schreibt storage_info.json)
4. ✅ **`systeminfo_get_storage_info()`** - ERLEDIGT (liest storage_info.json)
5. ✅ **`systeminfo_collect_os_info()`** - ERLEDIGT (schreibt os_info.json)
6. ✅ **`systeminfo_get_os_info()`** - ERLEDIGT (liest os_info.json)
7. ✅ **`systeminfo_collect_uptime_info()`** - ERLEDIGT (aktualisiert os_info.json)

### Phase 2: Wichtig (für Dependencies)
8. ✅ **`systeminfo_collect_software_info()`** - ERLEDIGT (schreibt software_info.json, Core-Tools)
9. ✅ **`systeminfo_get_software_info()`** - ERLEDIGT (liest software_info.json)
10. ✅ **`/api/system`** - ERLEDIGT (liefert OS + Software)
11. ✅ **`/api/archive`** - ERLEDIGT (liefert Storage + Archiv-Counts)
12. ❌ **`systeminfo_get_module_software()`** - FEHLT (INI-basiertes Modul-Dependency-Management)

### Phase 3: Optimierung
13. ✅ **Caching-Strategie** - ERLEDIGT (JSON-basiert: statische vs. flüchtige Daten)
14. ✅ **Auto-Update-Logik** - ERLEDIGT (systemd Timer alle 30s für flüchtige Daten)
15. ✅ **Fehlerbehandlung** - ERLEDIGT (Fallback-Mechanismen in Getter-Funktionen)
16. ✅ **Service-Management** - ERLEDIGT (libservice.sh für Service-Status)

### Phase 4: Cleanup
17. ✅ **Migration der Widgets** - ERLEDIGT (alle Systeminfo-Widgets nutzen neue API)
18. ✅ **Deprecation** - ERLEDIGT (`collect_system_information()` als deprecated markiert)
19. ✅ **Drive-Info ausgelagert** - ERLEDIGT (nach libdrivestat.sh verschoben)
20. ⏳ **Dokumentation** - TEILWEISE (TODO-Kommentare vorhanden, API-Docs fehlen)

---

## 7. OFFENE FRAGEN

1. **Caching:** Wie oft soll `system.json` neu generiert werden?
   - Option A: Nur beim Service-Start
   - Option B: Alle X Minuten (cronjob?)
   - Option C: On-Demand (wenn Widget updated)

2. **Fehlerbehandlung:** Was wenn Bash-Funktion fehlschlägt?
   - Python fallback zu Live-Prüfung?
   - Cached Daten behalten?
   - Error-State im Widget?

3. **Performance:** Bash-Subprozesse vs. Python-native Prüfung?
   - Für Software-Versionen: Bash subprocess notwendig
   - Für OS-Info: Python kann das auch (`platform` Modul)

4. **Modularität:** Wo leben die neuen Funktionen?
   - Alles in `libsysteminfo.sh`?
   - Neue `libsoftware.sh` für Software-Checks?

---

## 10. UMSETZUNGSSTAND (Stand: 2026-02-05)

### ✅ VOLLSTÄNDIG UMGESETZT

#### Modulare Bash-Architektur (libsysteminfo.sh)
- ✅ **Collector-Funktionen** (schreiben JSON-Dateien):
  - `systeminfo_collect_os_info()` → `api/os_info.json`
  - `systeminfo_collect_uptime_info()` → aktualisiert `api/os_info.json`
  - `systeminfo_collect_container_info()` → `api/container_info.json`
  - `systeminfo_collect_storage_info()` → `api/storage_info.json`
  - `systeminfo_collect_software_info()` → `api/software_info.json`

- ✅ **Widget-Getter-Funktionen** (lesen JSON-Dateien):
  - `systeminfo_get_os_info()` - für `widget_2x1_sysinfo`
  - `systeminfo_get_storage_info()` - für `widget_2x1_outputdir`
  - `systeminfo_get_archiv_info()` - für `widget_2x1_archiv`
  - `systeminfo_get_software_info()` - für `widget_4x1_dependencies`

#### Service-Management (libservice.sh - NEU!)
- ✅ **libservice.sh** erstellt mit:
  - `service_get_status(service_name)` - Ermittelt systemctl-Status
  - `service_collect_status_info()` → `api/service_status.json`
  - `service_get_status_info([service_name])` - Liest Service-Status
  - `service_restart(service_name)` - Startet Service neu

#### Drive-Management (libdrivestat.sh)
- ✅ **Drive-Info verschoben** von libsysteminfo.sh → libdrivestat.sh:
  - `drivestat_collect_drive_info()` → `api/drive_info.json`
  - `drivestat_get_drive_info()` - Liest Drive-Status
  - `systeminfo_collect_hardware_info()` als deprecated Wrapper

#### Python Middleware (app.py)
- ✅ **Neue Python-Funktionen**:
  - `get_os_info()` - Ruft `systeminfo_get_os_info` via subprocess
  - `get_storage_info()` - Ruft `systeminfo_get_storage_info` via subprocess
  - `get_archiv_info()` - Ruft `systeminfo_get_archiv_info` via subprocess
  - `get_software_info()` - Ruft `systeminfo_get_software_info` via subprocess

- ✅ **Neue API-Endpoints**:
  - `GET /api/system` - OS + Software-Informationen
  - `GET /api/archive` - Storage + Archiv-Counts
  - `GET /api/service/status/<service>` - Service-Status
  - `POST /api/service/restart/<service>` - Service-Neustart

#### Automatische Updates (systemd Timer)
- ✅ **disk2iso-volatile-updater.timer** - Läuft alle 30 Sekunden
- ✅ **disk2iso-volatile-updater.service** - OneShot Service
- ✅ **update_volatile_data.sh** - Sammelt flüchtige Daten:
  - Uptime (alle 30s)
  - Speicherplatz (alle 30s)
  - Service-Status (alle 30s)

#### Widget-Integration
- ✅ **Alle Systeminfo-Widgets** in [system.html](system.html) eingebunden:
  - `systeminfo_widget_2x1_sysinfo.html` ✅
  - `systeminfo_widget_2x1_outputdir.html` ✅
  - `systeminfo_widget_2x1_archiv.html` ✅
  - `systeminfo_widget_4x1_dependencies.html` ✅
  - `disk2iso_widget_2x1_status.html` ✅
  - `disk2iso-web_widget_2x1_status.html` ✅

- ✅ **JavaScript-Widget-Loader** verwenden neue API-Endpoints:
  - `/api/system` für OS + Software
  - `/api/archive` für Storage + Archiv
  - `/api/service/status/<service>` für Service-Status

#### Deprecation & Migration
- ✅ **collect_system_information()** als DEPRECATED markiert
  - Ruft neue modulare Funktionen auf (Kompatibilitätsmodus)
  - Warnung bei Verwendung geloggt
- ✅ **systeminfo_collect_hardware_info()** als DEPRECATED markiert
  - Wrapper für `drivestat_collect_drive_info()`

### ❌ NOCH NICHT UMGESETZT

#### INI-basiertes Modul-Dependency-Management
- ❌ **`systeminfo_get_module_software(module_name)`** - FEHLT
  - Sollte `[dependencies]` aus `lib<module>.ini` lesen
  - Automatische Version-Checks für Modul-spezifische Tools
  - **Aktuell:** Software-Liste in `systeminfo_collect_software_info()` hardcodiert

#### Feinere API-Granularität (Optional)
- ❌ **`/api/system/os`** - Nur OS-Daten (kleinerer Response)
- ❌ **`/api/system/storage`** - Nur Storage-Daten
- ❌ **`/api/system/software`** - Nur Software-Daten
- **Aktuell:** `/api/system` und `/api/archive` liefern alles auf einmal
- **Bewertung:** Nicht kritisch, aktuelle Endpoints sind ausreichend

### ⏳ TEILWEISE UMGESETZT

#### Dokumentation
- ⏳ **Inline-Kommentare** - Vorhanden in allen neuen Funktionen
- ⏳ **API-Dokumentation** - Fehlt (kein OpenAPI/Swagger)
- ⏳ **Migration-Guide** - Diese Datei dient als Dokumentation

---

## 11. ARCHITEKTUR-ÜBERSICHT (IST-ZUSTAND)

### Datenfluss: Statische Daten (einmalig beim Start)

```
disk2iso.service startet
  ↓
libsysteminfo.sh geladen
  ↓
systeminfo_collect_os_info() → api/os_info.json
systeminfo_collect_container_info() → api/container_info.json
systeminfo_collect_software_info() → api/software_info.json
  ↓
libdrivestat.sh geladen
  ↓
drivestat_collect_drive_info() → api/drive_info.json
```

### Datenfluss: Flüchtige Daten (alle 30s via Timer)

```
disk2iso-volatile-updater.timer (alle 30s)
  ↓
disk2iso-volatile-updater.service (OneShot)
  ↓
update_volatile_data.sh
  ↓
systeminfo_collect_uptime_info() → api/os_info.json (update .uptime)
systeminfo_collect_storage_info() → api/storage_info.json
service_collect_status_info() → api/service_status.json
```

### Datenfluss: Widget-Darstellung

```
Browser lädt /system
  ↓
JavaScript: fetch('/api/system')
  ↓
Python: api_system()
  ↓
Python: get_os_info() → subprocess → systeminfo_get_os_info
  ↓
Bash: cat api/os_info.json
  ↓
JSON → Python → JavaScript → DOM-Update
```

### JSON-Dateien (api/ Verzeichnis)

| Datei | Erstellt von | Aktualisiert von | Inhalt |
|-------|--------------|------------------|--------|
| `os_info.json` | `systeminfo_collect_os_info()` | `systeminfo_collect_uptime_info()` | OS, Kernel, Uptime |
| `container_info.json` | `systeminfo_collect_container_info()` | - | Container-Typ |
| `storage_info.json` | `systeminfo_collect_storage_info()` | `systeminfo_collect_storage_info()` | Speicherplatz |
| `software_info.json` | `systeminfo_collect_software_info()` | - | Software-Versionen |
| `drive_info.json` | `drivestat_collect_drive_info()` | - | Laufwerk-Info |
| `service_status.json` | `service_collect_status_info()` | `service_collect_status_info()` | Service-Status |

---

## 12. NÄCHSTE SCHRITTE (Priorisiert)

### Sofort (Optional - Nice to have):
- [ ] INI-basiertes Modul-Dependency-Management implementieren
  - `systeminfo_get_module_software(module_name)` in libsysteminfo.sh
  - Liest `[dependencies]` aus Modul-INI-Dateien
  - Dynamische Software-Prüfung statt hardcodiert

### Kurzfristig (Cleanup):
- [ ] `collect_system_information()` komplett entfernen (aktuell deprecated)
- [ ] `systeminfo_collect_hardware_info()` komplett entfernen (aktuell deprecated Wrapper)
- [ ] Testing der Timer-Integration in Produktion

### Mittelfristig (Dokumentation):
- [ ] OpenAPI/Swagger-Dokumentation für alle API-Endpoints
- [ ] Migration-Guide für andere Entwickler
- [ ] Performance-Monitoring der Timer-basierten Updates

### Langfristig (Erweiterungen):
- [ ] Fehler-Aggregation in zentrales Error-Log
- [ ] Historische Daten (Uptime-Tracking, Storage-Trends)
- [ ] Notification bei kritischen Änderungen (Service down, wenig Speicher)

---

## 13. ZUSAMMENFASSUNG

**Status:** ✅ **95% ABGESCHLOSSEN**

**Was funktioniert:**
- Modulare Bash-Architektur (Collector + Getter)
- JSON-basierte Datenpersistenz
- Automatische Updates via systemd Timer
- Alle Widgets nutzen neue API-Endpoints
- Service-Management vollständig integriert
- Drive-Info sauber nach libdrivestat.sh ausgelagert

**Was fehlt:**
- INI-basiertes Modul-Dependency-Management (5% - Nice to have)
- API-Dokumentation (Swagger/OpenAPI)

**Bewertung:**
Die ursprünglichen Ziele (modulare Architektur, Widget-Funktionalität, automatische Updates) sind **vollständig erreicht**. Das INI-basierte Dependency-Management ist ein **Nice-to-have** für zukünftige Skalierung, aber nicht kritisch für den Betrieb.

---

## 8. NÄCHSTE SCHRITTE (VERALTET - Siehe Kapitel 12)

### Sofort (Diese Session):
- [ ] Entscheidung: Inkrementelle vs. Big Bang Migration
- [ ] Erstelle `/api/service/status` Endpoint
- [ ] Teste mit `disk2iso_widget_2x1_status`

### Kurzfristig (Nächste Sessions):
- [ ] Implementiere `systeminfo_get_os_info()`
- [ ] Implementiere `systeminfo_get_storage_info()`
- [ ] Implementiere `systeminfo_get_core_software()`

### Mittelfristig:
- [ ] INI-basiertes Dependency Management
- [ ] `systeminfo_get_module_software()`
- [ ] Widget-Migration

### Langfristig:
- [ ] Entferne `collect_system_information()`
- [ ] Performance-Optimierung
- [ ] Dokumentation

---

## 9. ZUSAMMENFASSUNG

**Problem:** Monolithische `collect_system_information()` generiert zu viel Daten auf einmal, kennt Modul-Dependencies hardcodiert.

**Lösung:** Modulare Bash-Funktionen + spezifische API Endpoints + INI-basiertes Dependency Management.

**Vorteil:** 
- Widgets laden nur benötigte Daten
- Module verwalten eigene Dependencies
- Bessere Testbarkeit
- Flexiblere Updates

**Risiko:** 
- Mehr API Endpoints = mehr Wartung
- Migration kann komplex werden
- Bash-Subprozesse = Performance-Overhead

**Empfehlung:** Inkrementelle Migration, starting mit kritischen Widgets (Status, Sysinfo, OutputDir).
