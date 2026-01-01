# TODO: Service-Konfiguration

## Problem
Die `disk2iso.service` Datei hat kein Ausgabeverzeichnis konfiguriert.

## Aktueller Stand
```ini
[Service]
ExecStart=/usr/local/bin/disk2iso.sh
```

## Lösung 1: Direkter Parameter
```ini
[Service]
ExecStart=/usr/local/bin/disk2iso.sh -o /pfad/zum/ausgabeverzeichnis
```

**Nachteil:** Hartcodierter Pfad in der Service-Datei

## Lösung 2: Konfigurationsdatei (empfohlen)
Erstelle `/etc/disk2iso/disk2iso.conf`:
```bash
OUTPUT_DIR=/pfad/zum/ausgabeverzeichnis
```

Ändere `disk2iso.sh` um Config-Datei zu lesen:
```bash
# Lade Konfiguration falls vorhanden
if [[ -f /etc/disk2iso/disk2iso.conf ]]; then
    source /etc/disk2iso/disk2iso.conf
fi
```

Service-Datei bleibt unverändert.

## Priorität
Nach Abschluss der Kopiertests

## Datum
2026-01-01
