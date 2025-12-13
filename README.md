# disk2iso

**Automatisches CD/DVD/Blu-ray Archivierungstool für Linux**

`disk2iso` ist ein intelligentes Bash-Skript, das optische Medien automatisch erkennt, archiviert und als ISO-Images oder MP3-Dateien (bei Audio-CDs) speichert. Ideal für Heimserver und automatische Backup-Lösungen.

## ✨ Features

### Unterstützte Medientypen
- 🎵 **Audio-CDs** - Rippen zu MP3 mit automatischen Metadaten (MusicBrainz/CD-TEXT) und Album-Cover
- 💿 **CD-ROM** - ISO-Erstellung mit MD5-Checksummen
- 📀 **DVD-Video** - Struktur-erhaltende Backups mit dvdbackup
- 💾 **DVD-ROM** - Standard ISO-Images
- 🎬 **Blu-ray Video** - Entschlüsselte Backups mit MakeMKV
- 📁 **Blu-ray ROM** - Daten-Blu-ray ISO-Images

### Intelligente Funktionen
- ✅ **Automatische Typ-Erkennung** - 6 spezialisierte Detection-Algorithmen
- ✅ **Mehrfache Fallback-Strategien** - ddrescue → dd für maximale Erfolgsrate
- ✅ **MD5-Checksummen** - Automatische Integritätsprüfung
- ✅ **Service-Modus** - systemd-Integration für unbeaufsichtigten Betrieb
- ✅ **Robuste Fehlerbehandlung** - Cleanup und Recovery bei Problemen
- ✅ **Fortschrittsanzeige** - Optional mit `pv`

### Architektur
- 📦 **Modulare Struktur** - 10 spezialisierte Bibliotheken
- 🚀 **Lazy Loading** - Module werden nur bei Bedarf geladen
- 🌍 **Internationalisierung** - Deutsche Sprachdatei (erweiterbar)
- 📝 **Umfangreiches Logging** - Alle Operationen werden protokolliert

## 📋 Voraussetzungen

### Kritische Abhängigkeiten
- `dd` (coreutils)
- `md5sum` (coreutils)
- `lsblk` (util-linux)
- `isoinfo` (genisoimage)

### Optionale Tools (erweiterte Funktionen)
- `ddrescue` - Robustes Kopieren mit Fehlerbehandlung
- `dvdbackup` - Video-DVD Backup
- `makemkvcon` - Blu-ray Video Backup
- `cdparanoia` + `lame` - Audio-CD Ripping
- `cd-discid` + `curl` + `jq` - MusicBrainz Metadaten-Lookup
- `cdrdao` - CD-TEXT Extraktion
- `eyeD3` oder `mid3v2` - MP3-Tag-Editor
- `pv` - Fortschrittsanzeige

## 🚀 Installation

### Automatische Installation (empfohlen)

```bash
# Repository klonen
git clone https://github.com/IhrUsername/disk2iso.git
cd disk2iso

# Installation mit sudo ausführen
sudo ./install.sh
```

Das Installations-Script:
- ✅ Erkennt automatisch den Paketmanager (apt/dnf/yum/pacman/zypper)
- ✅ Installiert fehlende Abhängigkeiten
- ✅ Kopiert Dateien nach `/usr/local/bin`
- ✅ Richtet optional den systemd-Service ein

### Manuelle Installation

```bash
# Kopiere Hauptskript
sudo cp disk2iso.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/disk2iso.sh

# Kopiere Bibliotheken
sudo cp -r disk2iso-lib /usr/local/bin/

# Passe Pfad im Hauptskript an
sudo sed -i 's|SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE\[0\]}")" && pwd)"|SCRIPT_DIR="/usr/local/bin/disk2iso-lib"|' /usr/local/bin/disk2iso.sh
```

## 💻 Verwendung

### Manueller Modus

```bash
# Laufwerk wird automatisch erkannt
sudo disk2iso.sh
```

### Service-Modus (Automatisch)

```bash
# Service aktivieren und starten
sudo systemctl enable disk2iso.service
sudo systemctl start disk2iso.service

# Status prüfen
sudo systemctl status disk2iso.service

# Logs verfolgen
sudo journalctl -u disk2iso.service -f
```

Im Service-Modus:
1. Medium einlegen
2. Automatische Erkennung und Archivierung
3. Medium wird automatisch ausgeworfen
4. Bereit für nächstes Medium

## ⚙️ Konfiguration

Konfiguration in `disk2iso-lib/config.sh`:

```bash
# Ausgabe-Verzeichnis
OUTPUT_DIR="/mnt/pve/Public/images"

# Audio-CD Einstellungen
AUDIO_QUALITY="V2"              # LAME VBR Qualität (V0-V9)
AUDIO_USE_MUSICBRAINZ=true      # MusicBrainz Metadaten-Lookup
AUDIO_USE_CDTEXT=true           # CD-TEXT Extraktion
AUDIO_DOWNLOAD_COVER=true       # Album-Cover herunterladen
```

## 📁 Projekt-Struktur

```
disk2iso/
├── disk2iso.sh              # Hauptskript
├── install.sh               # Installations-Script
├── uninstall.sh             # Deinstallations-Script
└── disk2iso-lib/            # Bibliotheken
    ├── config.sh            # Konfiguration
    ├── lib-bluray.sh        # Blu-ray Funktionen
    ├── lib-cd.sh            # CD Funktionen
    ├── lib-common.sh        # Gemeinsame Kopierfunktionen
    ├── lib-diskinfos.sh     # Disc-Informationen
    ├── lib-drivestat.sh     # Laufwerk-Status
    ├── lib-dvd.sh           # DVD Funktionen
    ├── lib-files.sh         # Dateinamen-Verwaltung
    ├── lib-folders.sh       # Ordner-Verwaltung
    ├── lib-logging.sh       # Logging-System
    ├── lib-tools.sh         # Tool-Validierung
    └── lang/
        └── messages.de      # Deutsche Sprachdatei
```

## 🔧 Deinstallation

```bash
sudo ./uninstall.sh
```

Das Skript:
- ✅ Stoppt und deaktiviert den Service
- ✅ Entfernt alle installierten Dateien
- ✅ Optional: Löscht archivierte Daten

## 📝 Ausgabe-Dateien

### ISO-Images
- **Dateiname:** `disc_label.iso` (Kleinbuchstaben)
- **MD5-Checksumme:** `disc_label.md5`
- **Log-Datei:** `disc_label.log`

### Audio-CDs
- **Verzeichnis:** `OUTPUT_DIR/Artist - Album/`
- **Dateien:** `01 - Track Title.mp3`, `folder.jpg` (Cover)
- **Tags:** Artist, Album, Title, Track, Year, Genre

## 🛡️ Fehlerbehandlung

- **Robustes Kopieren:** Automatischer Fallback von ddrescue → dd
- **Error Recovery:** Automatisches Cleanup bei Fehlern
- **Signal-Handling:** Sauberes Beenden bei SIGTERM/SIGINT
- **Mount-Point Safety:** Sichere Pfade in OUTPUT_DIR statt /tmp

## 🤝 Beitragen

Beiträge sind willkommen! Bitte:
1. Forken Sie das Repository
2. Erstellen Sie einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Committen Sie Ihre Änderungen (`git commit -m 'Add AmazingFeature'`)
4. Pushen Sie zum Branch (`git push origin feature/AmazingFeature`)
5. Öffnen Sie einen Pull Request

## 📜 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

## 🙏 Danksagungen

- MusicBrainz für die Metadaten-API
- MakeMKV für Blu-ray Unterstützung
- Alle Open-Source Tool-Entwickler

## 📞 Support

Bei Problemen oder Fragen:
- Öffnen Sie ein Issue auf GitHub
- Prüfen Sie die Logs: `journalctl -u disk2iso.service`

## 🗺️ Roadmap

- [ ] Weitere Sprachen (EN, FR, ES)
- [ ] Web-Interface für Monitoring
- [ ] Konfigurierbares Qualitätsprofil pro Medium-Typ
- [ ] Automatische Discogs-Integration
- [ ] Docker-Container
- [ ] Batch-Processing-Modus

---

**Version:** 1.0.0  
**Autor:** Dirk  
**Status:** Production Ready (95%)
