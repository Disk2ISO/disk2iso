# ============================================================================
# disk2iso MQTT Module Repository Setup
# ============================================================================
# Erstellt ein separates Git-Repository für das MQTT-Modul
# Autor: GitHub Copilot
# Datum: 2026-01-29
# ============================================================================

param(
    [string]$SourceDir = "L:\clouds\onedrive\Dirk\projects\disk2iso",
    [string]$TargetDir = "L:\clouds\onedrive\Dirk\projects\disk2iso-mqtt",
    [switch]$Force
)

# Farben für Output
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "disk2iso MQTT Module Repository Setup" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# ============================================================================
# SCHRITT 1: Prüfungen
# ============================================================================

Write-Info "Prüfe Voraussetzungen..."

# Prüfe ob Source-Dir existiert
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source-Verzeichnis nicht gefunden: $SourceDir"
    exit 1
}

# Prüfe ob Target-Dir bereits existiert
if (Test-Path $TargetDir) {
    if (-not $Force) {
        Write-Warning "Ziel-Verzeichnis existiert bereits: $TargetDir"
        $answer = Read-Host "Möchten Sie es löschen und neu erstellen? (y/N)"
        if ($answer -ne 'y') {
            Write-Info "Abgebrochen."
            exit 0
        }
    }
    Write-Info "Lösche bestehendes Verzeichnis..."
    Remove-Item -Recurse -Force $TargetDir
}

Write-Success "Voraussetzungen erfüllt"

# ============================================================================
# SCHRITT 2: Ordnerstruktur erstellen
# ============================================================================

Write-Info "Erstelle Ordnerstruktur..."

$Directories = @(
    "$TargetDir",
    "$TargetDir\lib",
    "$TargetDir\lang",
    "$TargetDir\conf",
    "$TargetDir\www",
    "$TargetDir\www\routes",
    "$TargetDir\www\static",
    "$TargetDir\www\static\js",
    "$TargetDir\www\static\js\widgets",
    "$TargetDir\www\templates",
    "$TargetDir\www\templates\widgets",
    "$TargetDir\.github",
    "$TargetDir\.github\workflows"
)

foreach ($dir in $Directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

Write-Success "Ordnerstruktur erstellt"

# ============================================================================
# SCHRITT 3: Dateien kopieren
# ============================================================================

Write-Info "Kopiere MQTT-Modul-Dateien..."

# lib/libmqtt.sh
Copy-Item "$SourceDir\lib\libmqtt.sh" "$TargetDir\lib\" -Force

# lang/libmqtt.*
Copy-Item "$SourceDir\lang\libmqtt.de" "$TargetDir\lang\" -Force
Copy-Item "$SourceDir\lang\libmqtt.en" "$TargetDir\lang\" -Force
Copy-Item "$SourceDir\lang\libmqtt.es" "$TargetDir\lang\" -Force
Copy-Item "$SourceDir\lang\libmqtt.fr" "$TargetDir\lang\" -Force

# conf/libmqtt.ini
Copy-Item "$SourceDir\conf\libmqtt.ini" "$TargetDir\conf\" -Force

# www/routes/routes_mqtt.py
Copy-Item "$SourceDir\www\routes\routes_mqtt.py" "$TargetDir\www\routes\" -Force

# www/static/js/widgets/mqtt*.js
Copy-Item "$SourceDir\www\static\js\widgets\mqtt.js" "$TargetDir\www\static\js\widgets\" -Force
Copy-Item "$SourceDir\www\static\js\widgets\mqtt_config.js" "$TargetDir\www\static\js\widgets\" -Force

# www/templates/widgets/mqtt*.html
Copy-Item "$SourceDir\www\templates\widgets\mqtt_widget.html" "$TargetDir\www\templates\widgets\" -Force
Copy-Item "$SourceDir\www\templates\widgets\mqtt_config_widget.html" "$TargetDir\www\templates\widgets\" -Force

Write-Success "Dateien kopiert"

# ============================================================================
# SCHRITT 4: README.md erstellen
# ============================================================================

Write-Info "Erstelle README.md..."

$ReadmeContent = @"
# disk2iso MQTT Module

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/DirkGoetze/disk2iso-mqtt)](https://github.com/DirkGoetze/disk2iso-mqtt/releases)

MQTT Integration Plugin für [disk2iso](https://github.com/DirkGoetze/disk2iso) - ermöglicht Home Assistant Integration und Echtzeit-Monitoring.

## 🚀 Features

- **Home Assistant Auto-Discovery** - Automatische Sensor-Erkennung
- **Echtzeit-Status-Updates** - idle, copying, waiting, completed, error
- **Fortschritts-Tracking** - Prozent, MB, ETA
- **Medium-Informationen** - Label, Typ, Größe
- **Availability-Monitoring** - Online/Offline Status

## 📋 Voraussetzungen

- **disk2iso** >= v1.2.0 ([Installation](https://github.com/DirkGoetze/disk2iso))
- **mosquitto-clients** (MQTT Client-Tools)
- **MQTT Broker** (z.B. Mosquitto, Home Assistant)

## 📦 Installation

### Automatisch (empfohlen)

``````bash
# Download neueste Version
curl -L https://github.com/DirkGoetze/disk2iso-mqtt/releases/latest/download/mqtt-module.zip -o /tmp/mqtt.zip

# Entpacken nach disk2iso
cd /opt/disk2iso
sudo unzip /tmp/mqtt.zip

# Service neu starten
sudo systemctl restart disk2iso-web
``````

### Manuell

1. Download [neueste Release](https://github.com/DirkGoetze/disk2iso-mqtt/releases/latest)
2. Entpacke nach ``/opt/disk2iso/``
3. Setze Berechtigungen: ``sudo chown -R root:root /opt/disk2iso/``
4. Restart Service: ``sudo systemctl restart disk2iso-web``

### Via Web-UI (ab v1.3.0)

1. Öffne disk2iso Web-UI
2. Gehe zu **Einstellungen → Module**
3. Klicke auf **MQTT → Installieren**

## ⚙️ Konfiguration

### Via Web-UI (empfohlen)

1. Öffne disk2iso Web-UI
2. Gehe zu **Einstellungen**
3. Aktiviere **MQTT Integration**
4. Konfiguriere MQTT Broker:
   - **Broker:** IP-Adresse deines MQTT Brokers
   - **Port:** 1883 (Standard)
   - **User/Password:** Optional, falls Auth erforderlich
5. Klicke auf **Verbindung testen**
6. Speichern (Auto-Save bei Fokus-Verlust)

### Via Konfigurationsdatei

Bearbeite ``/opt/disk2iso/conf/disk2iso.conf``:

``````bash
# MQTT Integration
MQTT_ENABLED=true
MQTT_BROKER="192.168.20.13"
MQTT_PORT=1883
MQTT_USER=""           # Optional
MQTT_PASSWORD=""       # Optional
``````

Erweiterte Einstellungen in ``/opt/disk2iso/conf/libmqtt.ini``:

``````ini
[api]
topic_prefix=homeassistant/sensor/disk2iso
client_id=disk2iso-hostname
qos=0
retain=true
``````

## 🏠 Home Assistant Integration

### Automatische Sensor-Erkennung

Das Modul nutzt Home Assistant Auto-Discovery. Sensoren werden automatisch erkannt:

- ``sensor.disk2iso_status`` - Aktueller Status
- ``sensor.disk2iso_progress`` - Fortschritt in %
- ``sensor.disk2iso_disc_label`` - Medium-Label
- ``sensor.disk2iso_disc_type`` - Medium-Typ (audio-cd, dvd-video, bluray)

### Manuelle YAML-Konfiguration

Falls Auto-Discovery nicht funktioniert:

``````yaml
# configuration.yaml
sensor:
  - platform: mqtt
    name: "disk2iso Status"
    state_topic: "homeassistant/sensor/disk2iso/state"
    value_template: "{{ value_json.status }}"
    json_attributes_topic: "homeassistant/sensor/disk2iso/attributes"
    availability_topic: "homeassistant/sensor/disk2iso/availability"
``````

Beispiel-Konfiguration: [homeassistant-configuration.yaml](https://github.com/DirkGoetze/disk2iso/blob/master/samples/homeassistant-configuration.yaml)

## 🔧 CLI-Interface

Das Modul bietet ein CLI-Interface für Scripting:

``````bash
# Konfiguration exportieren (JSON)
/opt/disk2iso/lib/libmqtt.sh export-config

# Konfiguration updaten (JSON via stdin)
echo '{"mqtt_enabled": true, "mqtt_broker": "192.168.20.10"}' | \
  /opt/disk2iso/lib/libmqtt.sh update-config

# Verbindung testen
echo '{"broker": "192.168.20.10", "port": 1883}' | \
  /opt/disk2iso/lib/libmqtt.sh test-connection
``````

## 📊 MQTT Topics

### Status Topic
``````
homeassistant/sensor/disk2iso/state
{"status": "copying", "timestamp": "2026-01-29T21:30:00"}
``````

### Attributes Topic
``````
homeassistant/sensor/disk2iso/attributes
{
  "disc_label": "The Dark Knight",
  "disc_type": "bluray",
  "disc_size_mb": 45000,
  "progress_percent": 67,
  "progress_mb": 30150,
  "total_mb": 45000,
  "eta": "00:15:30",
  "filename": "The_Dark_Knight.mkv",
  "method": "makemkvcon",
  "container_type": "mkv"
}
``````

### Progress Topic
``````
homeassistant/sensor/disk2iso/progress
67
``````

### Availability Topic
``````
homeassistant/sensor/disk2iso/availability
online
``````

## 🐛 Troubleshooting

### MQTT-Verbindung schlägt fehl

1. **Broker erreichbar?**
   ``````bash
   mosquitto_pub -h 192.168.20.13 -p 1883 -t test -m "hello"
   ``````

2. **Authentifizierung korrekt?**
   - Prüfe User/Password in Web-UI
   - Teste mit mosquitto_pub: ``-u user -P password``

3. **Firewall-Regeln?**
   - Port 1883 muss offen sein

### Keine Sensoren in Home Assistant

1. **Auto-Discovery aktiviert?**
   ``````yaml
   # configuration.yaml
   mqtt:
     discovery: true
     discovery_prefix: homeassistant
   ``````

2. **MQTT Integration installiert?**
   - Home Assistant → Einstellungen → Geräte & Dienste → MQTT

3. **Topic-Prefix korrekt?**
   - Standard: ``homeassistant/sensor/disk2iso``
   - Prüfe in ``/opt/disk2iso/conf/libmqtt.ini``

### Logs prüfen

``````bash
# Web-UI Logs
sudo journalctl -u disk2iso-web -f

# disk2iso Service Logs
sudo journalctl -u disk2iso -f

# MQTT Debug
tail -f /opt/disk2iso/logs/disk2iso.log | grep MQTT
``````

## 📖 Dokumentation

- **Hauptdokumentation:** [disk2iso Handbuch](https://github.com/DirkGoetze/disk2iso/blob/master/doc/Handbuch.md)
- **MQTT-Modul Kapitel:** [04-5_MQTT.md](https://github.com/DirkGoetze/disk2iso/blob/master/doc/04_Module/04-5_MQTT.md)
- **Entwickler-Guide:** [06_Entwickler.md](https://github.com/DirkGoetze/disk2iso/blob/master/doc/06_Entwickler.md)

## 🤝 Contributing

Beiträge sind willkommen! Bitte beachte:

1. **Issues:** Bug-Reports und Feature-Requests via [GitHub Issues](https://github.com/DirkGoetze/disk2iso-mqtt/issues)
2. **Pull Requests:** Fork → Branch → Changes → PR
3. **Code-Style:** Folge dem [Modul-CLI-Interface-Pattern](https://github.com/DirkGoetze/disk2iso/blob/master/todo/Modul-CLI-Interface-Pattern.md)

## 📝 Changelog

Siehe [CHANGELOG.md](CHANGELOG.md) für Änderungen.

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE)

## 🔗 Links

- **Haupt-Repository:** [disk2iso](https://github.com/DirkGoetze/disk2iso)
- **Issues:** [GitHub Issues](https://github.com/DirkGoetze/disk2iso-mqtt/issues)
- **Releases:** [GitHub Releases](https://github.com/DirkGoetze/disk2iso-mqtt/releases)

---

**Entwickelt mit ❤️ für die disk2iso Community**
"@

Set-Content -Path "$TargetDir\README.md" -Value $ReadmeContent -Encoding UTF8

Write-Success "README.md erstellt"

# ============================================================================
# SCHRITT 5: LICENSE erstellen
# ============================================================================

Write-Info "Erstelle LICENSE..."

$LicenseContent = @"
MIT License

Copyright (c) 2026 Dirk Götze

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@

Set-Content -Path "$TargetDir\LICENSE" -Value $LicenseContent -Encoding UTF8

Write-Success "LICENSE erstellt"

# ============================================================================
# SCHRITT 6: VERSION erstellen
# ============================================================================

Write-Info "Erstelle VERSION..."

Set-Content -Path "$TargetDir\VERSION" -Value "1.0.0" -Encoding UTF8

Write-Success "VERSION erstellt"

# ============================================================================
# SCHRITT 7: install.sh erstellen
# ============================================================================

Write-Info "Erstelle install.sh..."

$InstallScriptContent = @'
#!/bin/bash
# ============================================================================
# disk2iso MQTT Module Installer
# ============================================================================
# Installiert das MQTT-Modul in eine bestehende disk2iso Installation
# ============================================================================

set -e

# Farben
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}disk2iso MQTT Module Installer${NC}"
echo -e "${CYAN}================================================${NC}\n"

# Prüfe Root-Rechte
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Dieses Script muss als root ausgeführt werden${NC}"
   exit 1
fi

# Prüfe ob disk2iso installiert ist
INSTALL_DIR="/opt/disk2iso"
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo -e "${RED}❌ disk2iso ist nicht installiert: $INSTALL_DIR nicht gefunden${NC}"
    echo -e "${YELLOW}ℹ️  Installiere zuerst disk2iso: https://github.com/DirkGoetze/disk2iso${NC}"
    exit 1
fi

echo -e "${GREEN}✅ disk2iso gefunden: $INSTALL_DIR${NC}"

# Prüfe disk2iso Version
VERSION_FILE="$INSTALL_DIR/VERSION"
if [[ -f "$VERSION_FILE" ]]; then
    DISK2ISO_VERSION=$(cat "$VERSION_FILE")
    echo -e "${GREEN}✅ disk2iso Version: $DISK2ISO_VERSION${NC}"
    
    # Prüfe Mindestversion (1.2.0)
    REQUIRED_VERSION="1.2.0"
    if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$DISK2ISO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
        echo -e "${RED}❌ MQTT-Modul benötigt disk2iso >= $REQUIRED_VERSION${NC}"
        echo -e "${YELLOW}ℹ️  Aktuelle Version: $DISK2ISO_VERSION${NC}"
        exit 1
    fi
fi

# Prüfe mosquitto_pub
if ! command -v mosquitto_pub &> /dev/null; then
    echo -e "${YELLOW}⚠️  mosquitto_pub nicht gefunden${NC}"
    echo -e "${CYAN}ℹ️  Installiere mosquitto-clients...${NC}"
    apt-get update && apt-get install -y mosquitto-clients
fi

echo -e "${GREEN}✅ mosquitto-clients installiert${NC}"

# Installiere Modul-Dateien
echo -e "${CYAN}ℹ️  Kopiere MQTT-Modul Dateien...${NC}"

# Bestimme Script-Verzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kopiere Dateien
cp -v "$SCRIPT_DIR/lib/libmqtt.sh" "$INSTALL_DIR/lib/"
cp -v "$SCRIPT_DIR/lang/libmqtt."* "$INSTALL_DIR/lang/"
cp -v "$SCRIPT_DIR/conf/libmqtt.ini" "$INSTALL_DIR/conf/"

# Erstelle www-Verzeichnisse falls nötig
mkdir -p "$INSTALL_DIR/www/routes"
mkdir -p "$INSTALL_DIR/www/static/js/widgets"
mkdir -p "$INSTALL_DIR/www/templates/widgets"

cp -v "$SCRIPT_DIR/www/routes/routes_mqtt.py" "$INSTALL_DIR/www/routes/"
cp -v "$SCRIPT_DIR/www/static/js/widgets/mqtt.js" "$INSTALL_DIR/www/static/js/widgets/"
cp -v "$SCRIPT_DIR/www/static/js/widgets/mqtt_config.js" "$INSTALL_DIR/www/static/js/widgets/"
cp -v "$SCRIPT_DIR/www/templates/widgets/mqtt_widget.html" "$INSTALL_DIR/www/templates/widgets/"
cp -v "$SCRIPT_DIR/www/templates/widgets/mqtt_config_widget.html" "$INSTALL_DIR/www/templates/widgets/"

# Setze Berechtigungen
chmod 644 "$INSTALL_DIR/lib/libmqtt.sh"
chmod 644 "$INSTALL_DIR/lang/libmqtt."*
chmod 644 "$INSTALL_DIR/conf/libmqtt.ini"
chmod 644 "$INSTALL_DIR/www/routes/routes_mqtt.py"
chmod 644 "$INSTALL_DIR/www/static/js/widgets/mqtt.js"
chmod 644 "$INSTALL_DIR/www/static/js/widgets/mqtt_config.js"
chmod 644 "$INSTALL_DIR/www/templates/widgets/mqtt_widget.html"
chmod 644 "$INSTALL_DIR/www/templates/widgets/mqtt_config_widget.html"

chown root:root "$INSTALL_DIR/lib/libmqtt.sh"
chown root:root "$INSTALL_DIR/lang/libmqtt."*
chown root:root "$INSTALL_DIR/conf/libmqtt.ini"
chown root:root "$INSTALL_DIR/www/routes/routes_mqtt.py"
chown root:root "$INSTALL_DIR/www/static/js/widgets/mqtt.js"
chown root:root "$INSTALL_DIR/www/static/js/widgets/mqtt_config.js"
chown root:root "$INSTALL_DIR/www/templates/widgets/mqtt_widget.html"
chown root:root "$INSTALL_DIR/www/templates/widgets/mqtt_config_widget.html"

echo -e "${GREEN}✅ MQTT-Modul Dateien installiert${NC}"

# Restart Web-Service
if systemctl is-active --quiet disk2iso-web; then
    echo -e "${CYAN}ℹ️  Starte disk2iso-web Service neu...${NC}"
    systemctl restart disk2iso-web
    echo -e "${GREEN}✅ Service neu gestartet${NC}"
fi

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}✅ MQTT-Modul erfolgreich installiert!${NC}"
echo -e "${GREEN}================================================${NC}\n"
echo -e "${CYAN}📝 Nächste Schritte:${NC}"
echo -e "   1. Öffne Web-UI: ${YELLOW}http://localhost:5000${NC}"
echo -e "   2. Gehe zu ${YELLOW}Einstellungen${NC}"
echo -e "   3. Aktiviere ${YELLOW}MQTT Integration${NC}"
echo -e "   4. Konfiguriere MQTT Broker\n"
echo -e "${CYAN}📖 Dokumentation:${NC}"
echo -e "   https://github.com/DirkGoetze/disk2iso-mqtt\n"
'@

Set-Content -Path "$TargetDir\install.sh" -Value $InstallScriptContent -Encoding UTF8

Write-Success "install.sh erstellt"

# ============================================================================
# SCHRITT 8: CHANGELOG.md erstellen
# ============================================================================

Write-Info "Erstelle CHANGELOG.md..."

$ChangelogContent = @"
# Changelog

Alle wichtigen Änderungen am MQTT-Modul werden hier dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

## [1.0.0] - 2026-01-29

### Added
- 🎉 Initiales Release des MQTT-Moduls
- Observer Pattern für automatische Status-Updates
- CLI-Interface für Scripting (export-config, update-config, test-connection)
- Helper-Funktionen für Code-Wiederverwendung
- Single Source of Truth für Default-Werte
- Web-UI Widget für Index-Seite (Service-Status)
- Web-UI Config-Widget mit Auto-Save Funktion
- Blueprint-System für modulare Flask-Routen
- Home Assistant Auto-Discovery Support
- Echtzeit-Status-Updates (idle, copying, waiting, completed, error)
- Fortschritts-Tracking (Prozent, MB, ETA)
- Medium-Informationen (Label, Typ, Größe)
- Availability-Monitoring (online/offline)
- Internationalisierung (de, en, es, fr)

### Changed
- Python nutzt jetzt CLI-Interface statt direkter Config-Zugriffe
- MQTT-Config aus Haupt-App ausgelagert in Blueprint
- Compliance: 55% → 100% (Zero Business-Logic in Python)

### Technical
- Observer Pattern: mqtt_publish_from_api() triggert via API-Änderungen
- Three-Flag Pattern: SUPPORT_MQTT, INITIALIZED_MQTT, ACTIVATED_MQTT
- Code-Reduktion: -35 Zeilen durch DRY-Prinzip
- 100% Nutzung von libconfig.sh (get_ini_value + Setter)

[Unreleased]: https://github.com/DirkGoetze/disk2iso-mqtt/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/DirkGoetze/disk2iso-mqtt/releases/tag/v1.0.0
"@

Set-Content -Path "$TargetDir\CHANGELOG.md" -Value $ChangelogContent -Encoding UTF8

Write-Success "CHANGELOG.md erstellt"

# ============================================================================
# SCHRITT 9: .gitignore erstellen
# ============================================================================

Write-Info "Erstelle .gitignore..."

$GitignoreContent = @"
# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
*.egg-info/
.venv/
venv/

# Logs
*.log

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Temp
*.tmp
*.bak
"@

Set-Content -Path "$TargetDir\.gitignore" -Value $GitignoreContent -Encoding UTF8

Write-Success ".gitignore erstellt"

# ============================================================================
# SCHRITT 10: GitHub Actions Workflow erstellen
# ============================================================================

Write-Info "Erstelle GitHub Actions Workflow..."

$WorkflowContent = @"
name: Release MQTT Module

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
      
      - name: Get Version from Tag
        id: get_version
        run: echo "VERSION=`${GITHUB_REF#refs/tags/}" >> `$GITHUB_OUTPUT
      
      - name: Create Module ZIP
        run: |
          # Erstelle temporären Build-Ordner
          mkdir -p build/mqtt-module
          
          # Kopiere Modul-Dateien
          cp -r lib build/mqtt-module/
          cp -r lang build/mqtt-module/
          cp -r conf build/mqtt-module/
          cp -r www build/mqtt-module/
          cp install.sh build/mqtt-module/
          cp README.md build/mqtt-module/
          cp LICENSE build/mqtt-module/
          cp VERSION build/mqtt-module/
          
          # Erstelle ZIP
          cd build
          zip -r mqtt-module.zip mqtt-module/
          mv mqtt-module.zip ../
          
          # Info
          echo "📦 ZIP erstellt:"
          ls -lh ../mqtt-module.zip
      
      - name: Generate Checksums
        run: |
          sha256sum mqtt-module.zip > mqtt-module.zip.sha256
          cat mqtt-module.zip.sha256
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            mqtt-module.zip
            mqtt-module.zip.sha256
          body: |
            ## 🚀 MQTT Module `${{ steps.get_version.outputs.VERSION }}`
            
            ### 📦 Installation
            
            **Automatisch:**
            ``````bash
            curl -L https://github.com/DirkGoetze/disk2iso-mqtt/releases/download/`${{ steps.get_version.outputs.VERSION }}/mqtt-module.zip -o /tmp/mqtt.zip
            cd /opt/disk2iso
            sudo unzip /tmp/mqtt.zip
            sudo systemctl restart disk2iso-web
            ``````
            
            **Manuell:**
            1. Download ``mqtt-module.zip``
            2. Entpacke nach ``/opt/disk2iso/``
            3. Restart Service: ``sudo systemctl restart disk2iso-web``
            
            ### 📋 Voraussetzungen
            
            - disk2iso >= v1.2.0
            - mosquitto-clients
            
            ### 🔍 Checksum Verification
            
            ``````bash
            sha256sum -c mqtt-module.zip.sha256
            ``````
            
            ### 📖 Dokumentation
            
            - [README](https://github.com/DirkGoetze/disk2iso-mqtt/blob/main/README.md)
            - [CHANGELOG](https://github.com/DirkGoetze/disk2iso-mqtt/blob/main/CHANGELOG.md)
            - [disk2iso Handbuch](https://github.com/DirkGoetze/disk2iso/blob/master/doc/Handbuch.md)
        env:
          GITHUB_TOKEN: `${{ secrets.GITHUB_TOKEN }}
"@

Set-Content -Path "$TargetDir\.github\workflows\release.yml" -Value $WorkflowContent -Encoding UTF8

Write-Success "GitHub Actions Workflow erstellt"

# ============================================================================
# SCHRITT 11: Git Repository initialisieren
# ============================================================================

Write-Info "Initialisiere Git Repository..."

Set-Location $TargetDir

# Git init
git init

# Git config
git config user.name "Dirk Götze"
git config user.email "dirk.goetze@example.com"  # TODO: Anpassen

# Alle Dateien hinzufügen
git add .

# Ersten Commit
git commit -m "feat: Initial MQTT Module Release v1.0.0

MQTT Integration Plugin für disk2iso mit folgenden Features:

- Observer Pattern für automatische API-Updates
- CLI-Interface (export-config, update-config, test-connection)
- Helper-Funktionen für Code-Wiederverwendung
- Web-UI Widgets (Index + Config) mit Auto-Save
- Blueprint-System für modulare Flask-Routen
- Home Assistant Auto-Discovery Support
- Echtzeit-Status-Updates
- Fortschritts-Tracking
- Internationalisierung (de, en, es, fr)
- GitHub Actions Workflow für automatische Releases

Technical:
- Three-Flag Pattern: SUPPORT_MQTT, INITIALIZED_MQTT, ACTIVATED_MQTT
- Code-Reduktion: -35 Zeilen durch DRY-Prinzip
- 100% libconfig.sh Nutzung
- Zero Business-Logic in Python (100% Compliance)"

# Tag erstellen
git tag -a v1.0.0 -m "Release v1.0.0 - Initial MQTT Module"

Write-Success "Git Repository initialisiert"

# ============================================================================
# SCHRITT 12: Zusammenfassung
# ============================================================================

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "✅ MQTT-Modul Repository erfolgreich erstellt!" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Green

Write-Info "Repository-Pfad: $TargetDir"
Write-Info "Git-Status: Initialisiert mit v1.0.0 Tag"
Write-Info ""
Write-Host "📝 Nächste Schritte:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1. GitHub Repository erstellen:" -ForegroundColor Yellow
Write-Host "      - Gehe zu: https://github.com/new" -ForegroundColor White
Write-Host "      - Name: disk2iso-mqtt" -ForegroundColor White
Write-Host "      - Beschreibung: MQTT Integration Plugin für disk2iso" -ForegroundColor White
Write-Host "      - Public" -ForegroundColor White
Write-Host "      - KEINE README, LICENSE, .gitignore hinzufügen (bereits vorhanden)" -ForegroundColor White
Write-Host ""
Write-Host "   2. Lokales Repo mit GitHub verbinden:" -ForegroundColor Yellow
Write-Host "      cd $TargetDir" -ForegroundColor White
Write-Host "      git remote add origin https://github.com/DirkGoetze/disk2iso-mqtt.git" -ForegroundColor White
Write-Host "      git branch -M master" -ForegroundColor White
Write-Host "      git push -u origin master" -ForegroundColor White
Write-Host "      git push --tags" -ForegroundColor White
Write-Host ""
Write-Host "   3. GitHub Actions aktivieren:" -ForegroundColor Yellow
Write-Host "      - GitHub → Settings → Actions → General" -ForegroundColor White
Write-Host "      - Allow all actions" -ForegroundColor White
Write-Host ""
Write-Host "   4. Erstes Release erstellen:" -ForegroundColor Yellow
Write-Host "      - GitHub → Releases → Create a new release" -ForegroundColor White
Write-Host "      - Choose tag: v1.0.0" -ForegroundColor White
Write-Host "      - Title: MQTT Module v1.0.0 - Initial Release" -ForegroundColor White
Write-Host "      - Publish release" -ForegroundColor White
Write-Host "      - GitHub Actions baut automatisch mqtt-module.zip" -ForegroundColor White
Write-Host ""
Write-Host "📖 Dokumentation:" -ForegroundColor Cyan
Write-Host "   README.md: $TargetDir\README.md" -ForegroundColor White
Write-Host "   CHANGELOG.md: $TargetDir\CHANGELOG.md" -ForegroundColor White
Write-Host ""

Write-Host "================================================`n" -ForegroundColor Green

# ============================================================================
# ENDE
# ============================================================================
