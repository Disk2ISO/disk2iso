# disk2iso WEB-Server - Konzept und Planung

## Übersicht

Der disk2iso WEB-Server ist eine webbasierte Anwendung zur Verwaltung und Durchführung von Disk-zu-ISO-Konvertierungen. Er ermöglicht es Benutzern, über eine intuitive Weboberfläche Disks auszuwählen, Konvertierungsjobs zu erstellen, deren Fortschritt zu überwachen und die resultierenden ISO-Dateien zu verwalten.

## Hauptfunktionen

### 1. Disk-Verwaltung
- Automatische Erkennung verfügbarer optischer Laufwerke
- Anzeige von Disk-Informationen (Typ, Label, Größe)
- Live-Status-Updates bei eingelegten/entnommenen Disks
- Unterstützung für mehrere Laufwerke gleichzeitig

### 2. Job-Verwaltung
- Erstellen neuer Konvertierungsjobs mit konfigurierbaren Optionen
- Warteschlangen-Management für mehrere Jobs
- Prioritätsverwaltung
- Job-History mit Filterung und Suche

### 3. Konvertierungs-Engine
- Asynchrone Verarbeitung mit Worker-Prozessen
- Echtzeit-Fortschrittsanzeige
- Fehlerbehandlung und Recovery-Optionen
- Multiple Konvertierungsmodi (Standard, Rescue, Clone)

### 4. ISO-Verwaltung
- Übersicht aller erstellten ISO-Dateien
- Datei-Browser mit Vorschau
- Download-Management
- Archivierung und Komprimierung

### 5. System-Überwachung
- Ressourcen-Monitoring (CPU, RAM, Disk I/O)
- Laufwerk-Status
- Worker-Status
- System-Logs

## System-Anforderungen und Installation

### Allgemeine Anforderungen

**Hardware:**
- CPU: Mindestens 2 Kerne empfohlen
- RAM: Mindestens 2 GB
- Speicher: Ausreichend Platz für ISO-Ausgaben (abhängig von Nutzung)
- Optische Laufwerke: Zugriff auf /dev/sr* Geräte erforderlich

**Software:**
- Python 3.11 oder höher
- Python-Pakete: Flask, SQLite3-Unterstützung
- Disk-Imaging-Tools: ddrescue, cdrdao, cdrtools, genisoimage
- Optional: Redis für Task-Queue und Caching
- System-Tools: udev, udisks2

### Installation

**1. Abhängigkeiten installieren**

```bash
# Debian/Ubuntu
apt-get update
apt-get install -y python3 python3-pip python3-venv \
    ddrescue cdrdao cdrtools genisoimage \
    python3-flask redis-server \
    udev udisks2
```

**2. Anwendung bereitstellen**

```bash
cd /opt/disk2iso
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**3. Systemd Service einrichten**

```ini
[Unit]
Description=disk2iso Web Service
After=network.target redis.service

[Service]
Type=simple
User=disk2iso
Group=disk2iso
WorkingDirectory=/opt/disk2iso
Environment="PATH=/opt/disk2iso/venv/bin"
ExecStart=/opt/disk2iso/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**4. Service aktivieren und starten**

```bash
systemctl daemon-reload
systemctl enable disk2iso
systemctl start disk2iso
```

### Besonderheiten bei LXC-Container-Betrieb

Wenn disk2iso in einem LXC-Container betrieben werden soll, sind folgende zusätzliche Konfigurationen erforderlich:

**Container-Konfiguration für Gerätezugriff:**

```bash
# In der LXC-Konfigurationsdatei (/var/lib/lxc/<container>/config)
# Optische Laufwerke durchreichen
lxc.mount.entry = /dev/sr0 dev/sr0 none bind,optional,create=file
lxc.mount.entry = /dev/sr1 dev/sr1 none bind,optional,create=file

# Optional: Ressourcen-Limits
lxc.cgroup2.memory.max = 2G
lxc.cgroup2.cpu.max = 200000 100000  # 2 CPU-Kerne
```

**Speicher-Mount für ISO-Ausgabe (optional):**

```bash
# Wenn ISOs außerhalb des Containers gespeichert werden sollen
lxc config device add disk2iso storage disk \
    source=/storage/isos \
    path=/opt/disk2iso/output
```

## Technologie-Stack

### Backend
- **Framework:** Flask (Python)
- **Datenbank:** SQLite für Job-Verwaltung und Metadaten
- **Task Queue:** Redis + RQ (Redis Queue) für asynchrone Jobs
- **Hardware-Integration:** pyudev für Device-Detection
- **Process Management:** subprocess für externe Tools

### Frontend
- **UI Framework:** Bootstrap 5
- **JavaScript:** Vanilla JS mit modernen ES6+ Features
- **Real-time Updates:** Server-Sent Events (SSE) oder WebSockets
- **Charts:** Chart.js für Visualisierungen

### System-Integration
- **ddrescue:** Für problematische Disks mit Lesefehlern
- **cdrdao:** Für Audio-CDs und präzise Disk-Images
- **genisoimage:** Für ISO-Erstellung
- **udisks2:** Für Disk-Management und -Information

## Architektur

### Komponenten-Übersicht

```
┌─────────────────────────────────────────────────────────────┐
│                        Web Browser                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Flask Web Server                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Routes     │  │   API        │  │   SSE        │      │
│  │   Handler    │  │   Endpoints  │  │   Streaming  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Job        │  │   Disk       │  │   ISO        │      │
│  │   Manager    │  │   Manager    │  │   Manager    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
┌──────────────────┐  ┌─────────────┐  ┌──────────────┐
│   SQLite DB      │  │   Redis     │  │   Worker     │
│   (Metadata)     │  │   Queue     │  │   Processes  │
└─���────────────────┘  └─────────────┘  └──────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │  External Tools  │
                                    │  (ddrescue,      │
                                    │   cdrdao, etc.)  │
                                    └──────────────────┘
```

### Datenbankschema

```sql
-- Jobs Tabelle
CREATE TABLE jobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT UNIQUE NOT NULL,
    disk_device TEXT NOT NULL,
    disk_label TEXT,
    disk_type TEXT,
    output_path TEXT NOT NULL,
    status TEXT NOT NULL, -- queued, running, completed, failed, cancelled
    mode TEXT NOT NULL, -- standard, rescue, clone
    options TEXT, -- JSON für zusätzliche Optionen
    progress REAL DEFAULT 0,
    size_total INTEGER,
    size_processed INTEGER,
    speed REAL,
    error_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ISOs Tabelle
CREATE TABLE isos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_uuid TEXT,
    filename TEXT NOT NULL,
    filepath TEXT NOT NULL,
    size INTEGER NOT NULL,
    md5sum TEXT,
    sha256sum TEXT,
    disk_type TEXT,
    disk_label TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_uuid) REFERENCES jobs(uuid)
);

-- System Logs
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_uuid TEXT,
    level TEXT NOT NULL, -- DEBUG, INFO, WARNING, ERROR
    message TEXT NOT NULL,
    details TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_uuid) REFERENCES jobs(uuid)
);
```

## API-Endpunkte

### Disk-Management
- `GET /api/disks` - Liste aller erkannten Laufwerke
- `GET /api/disks/<device>` - Details zu einem spezifischen Laufwerk
- `POST /api/disks/<device>/eject` - Disk auswerfen

### Job-Management
- `GET /api/jobs` - Liste aller Jobs (mit Filterung)
- `GET /api/jobs/<uuid>` - Job-Details
- `POST /api/jobs` - Neuen Job erstellen
- `PUT /api/jobs/<uuid>` - Job-Optionen aktualisieren
- `DELETE /api/jobs/<uuid>` - Job löschen/abbrechen
- `POST /api/jobs/<uuid>/pause` - Job pausieren
- `POST /api/jobs/<uuid>/resume` - Job fortsetzen
- `POST /api/jobs/<uuid>/retry` - Fehlgeschlagenen Job wiederholen

### ISO-Management
- `GET /api/isos` - Liste aller ISO-Dateien
- `GET /api/isos/<id>` - ISO-Details
- `GET /api/isos/<id>/download` - ISO herunterladen
- `DELETE /api/isos/<id>` - ISO löschen
- `POST /api/isos/<id>/verify` - Checksumme verifizieren

### System
- `GET /api/system/status` - System-Status (CPU, RAM, etc.)
- `GET /api/system/logs` - System-Logs
- `GET /api/system/config` - Konfiguration abrufen
- `PUT /api/system/config` - Konfiguration aktualisieren

### Real-time Updates
- `GET /events/jobs/<uuid>` - SSE-Stream für Job-Updates
- `GET /events/system` - SSE-Stream für System-Events

## Web-Interface Design

### Dashboard (Startseite)
- Übersichtskarten: Aktive Jobs, Warteschlange, Abgeschlossene Jobs, Verfügbare Laufwerke
- Schnellzugriff: Neue Konvertierung starten
- Aktuelle Aktivität: Liste laufender Jobs mit Fortschritt
- System-Status: CPU, RAM, Disk I/O

### Laufwerke-Ansicht
- Grid oder Liste aller erkannten Laufwerke
- Für jedes Laufwerk:
  - Status (leer, Disk eingelegt, lesend)
  - Disk-Information (wenn eingelegt)
  - Aktion: "ISO erstellen" Button
  - Eject-Button

### Job-Erstellung Dialog
- Laufwerk-Auswahl (wenn nicht vorgegeben)
- Ausgabe-Optionen:
  - Dateiname (auto-generiert, editierbar)
  - Ausgabepfad
  - Komprimierung
- Konvertierungs-Modus:
  - Standard (schnell, für fehlerfreie Disks)
  - Rescue (ddrescue, für beschädigte Disks)
  - Clone (bitgenaue Kopie)
- Erweiterte Optionen (aufklappbar):
  - Retry-Versuche
  - Block-Größe
  - Verify nach Abschluss

### Job-Übersicht
- Tabelle mit allen Jobs
- Filter: Status, Datum, Disk-Typ
- Sortierung: Nach Datum, Status, Priorität
- Für jeden Job:
  - Status-Badge
  - Fortschrittsbalken
  - Disk-Info
  - Aktionen (Pause, Abbrechen, Details)

### Job-Details Ansicht
- Vollständige Job-Information
- Live-Fortschritt mit:
  - Prozentsatz
  - Geschwindigkeit
  - Verbleibende Zeit
  - Gelesene/Gesamtgröße
- Fehler-Log (wenn vorhanden)
- Konvertierungs-Parameter
- Timeline der Events

### ISO-Bibliothek
- Grid-Ansicht mit Thumbnails (für Disk-Typen)
- Liste mit Details
- Filter: Disk-Typ, Datum, Größe
- Suche
- Für jede ISO:
  - Vorschau-Info
  - Größe
  - Checksumme
  - Download-Button
  - Löschen-Button
  - Verify-Button

### System-Einstellungen
- Allgemein:
  - Standard-Ausgabepfad
  - Temporäre Dateien
  - Max. gleichzeitige Jobs
- Laufwerke:
  - Auto-Detection ein/aus
  - Spezifische Laufwerke aktivieren/deaktivieren
- Benachrichtigungen:
  - Email bei Job-Abschluss
  - Webhook-URLs
- Erweitert:
  - Logging-Level
  - Worker-Konfiguration
  - Cache-Einstellungen

## Implementierungs-Phasen

### Phase 1: Grundgerüst (MVP)
- [ ] Flask-Projekt aufsetzen
- [ ] Grundlegende Routen und Templates
- [ ] SQLite-Datenbank initialisieren
- [ ] Einfache Disk-Detection
- [ ] Basis-Job-Verwaltung
- [ ] Einfache ISO-Erstellung mit einem Tool (z.B. dd)

### Phase 2: Kern-Funktionalität
- [ ] Redis und RQ integrieren
- [ ] Worker-Prozesse implementieren
- [ ] Alle Konvertierungs-Modi (ddrescue, cdrdao)
- [ ] Fortschritts-Tracking
- [ ] SSE für Live-Updates
- [ ] Umfassende Fehlerbehandlung

### Phase 3: Erweiterte Features
- [ ] ISO-Bibliothek mit Verwaltung
- [ ] Checksummen-Berechnung und -Verifizierung
- [ ] Job-Warteschlange mit Priorisierung
- [ ] System-Monitoring
- [ ] Konfigurationsverwaltung

### Phase 4: UI/UX-Verbesserungen
- [ ] Responsive Design optimieren
- [ ] Drag-and-drop für Job-Priorisierung
- [ ] Erweiterte Filterung und Suche
- [ ] Bulk-Operationen
- [ ] Keyboard-Shortcuts

### Phase 5: Zusätzliche Features
- [ ] Benachrichtigungssystem (Email, Webhooks)
- [ ] Mehrbenutzerverwaltung
- [ ] Zugriffskontrolle
- [ ] API-Dokumentation (Swagger/OpenAPI)
- [ ] Export/Import von Konfigurationen

## Sicherheitsüberlegungen

- Input-Validierung für alle User-Eingaben
- Path-Traversal-Schutz bei Dateioperationen
- Rate-Limiting für API-Endpunkte
- CSRF-Protection für Forms
- Sichere Passwort-Speicherung (wenn Multi-User)
- HTTPS in Produktionsumgebung
- Logging von sicherheitsrelevanten Events

## Performance-Optimierungen

- Caching von Disk-Informationen
- Lazy-Loading für große Listen
- Pagination für Job-History und ISO-Bibliothek
- Komprimierung von API-Responses
- Static-Asset-Optimierung
- Database-Indizierung für häufige Queries

## Monitoring und Logging

- Strukturiertes Logging (JSON-Format)
- Verschiedene Log-Level (DEBUG, INFO, WARNING, ERROR)
- Rotation von Log-Dateien
- System-Metriken sammeln
- Error-Tracking (optional: Sentry-Integration)
- Audit-Log für kritische Operationen

## Testing-Strategie

- Unit-Tests für Business Logic
- Integration-Tests für API-Endpunkte
- E2E-Tests für kritische User-Flows
- Mock für externe Tools in Tests
- Coverage-Ziel: >80%

## Deployment und Wartung

- Systemd Service für automatischen Start
- Logrotate-Konfiguration
- Backup-Strategie für Datenbank
- Update-Prozedur dokumentieren
- Health-Check-Endpunkt für Monitoring

## Offene Fragen und Entscheidungen

- [ ] Authentifizierung: Benötigt oder nicht?
- [ ] Max. Anzahl gleichzeitiger Jobs
- [ ] Aufbewahrungsrichtlinie für alte Jobs
- [ ] Automatisches Löschen von ISOs nach X Tagen?
- [ ] Cloud-Storage-Integration (S3, etc.)?
- [ ] Docker-Container als Alternative zu LXC?

## Ressourcen und Referenzen

- Flask Dokumentation: https://flask.palletsprojects.com/
- RQ (Redis Queue): https://python-rq.org/
- pyudev: https://pyudev.readthedocs.io/
- ddrescue Manual: https://www.gnu.org/software/ddrescue/manual/
- cdrdao Manual: http://cdrdao.sourceforge.net/
