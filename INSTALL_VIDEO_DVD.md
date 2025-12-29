# Installation: Video-DVD Unterstützung

## Option 1: Entschlüsselte ISOs (empfohlen, benötigt externes Repository)

Erstellt vollständig entschlüsselte ISOs ohne Kopierschutz.

### Pakete installieren

```bash
su -c 'apt-get update && apt-get install -y genisoimage'
```

### libdvdcss2 aus deb-multimedia.org

Da libdvdcss2 nicht in Debian Standard-Repos ist:

```bash
# Repository hinzufügen
su -c 'echo "deb http://www.deb-multimedia.org trixie main" > /etc/apt/sources.list.d/deb-multimedia.list'

# GPG-Key importieren
su -c 'apt-get update -oAcquire::AllowInsecureRepositories=true'
su -c 'apt-get install -y deb-multimedia-keyring'

# Pakete installieren
su -c 'apt-get update && apt-get install -y libdvdcss2 dvdbackup'
```

**Vorteile:**
- ✓ Entschlüsselte ISOs (direkt verarbeitbar)
- ✓ Schnell: ~10-15 Minuten für 4,7 GB DVD
- ✓ Überspringt Kopierschutz-Bereiche

**Nachteile:**
- ✗ Externes Repository erforderlich

---

## Option 2: Verschlüsselte ISOs mit ddrescue (nur Debian Standard-Repos)

Erstellt verschlüsselte aber vollständige ISOs.

### Pakete installieren

```bash
su -c 'apt-get update && apt-get install -y gddrescue genisoimage'
```

**Vorteile:**
- ✓ Nur Standard-Repos
- ✓ Deutlich schneller als dd: ~15-30 Minuten
- ✓ Intelligente Fehlerbehandlung

**Nachteile:**
- ✗ ISOs bleiben verschlüsselt (Weiterverarbeitung benötigt libdvdcss)

---

## Option 3: Fallback ohne zusätzliche Installation

Das Script nutzt automatisch `dd` als Fallback.

**Nachteile:**
- ✗ Sehr langsam bei kopiergeschützten DVDs (Stunden!)
- ✗ ISOs bleiben verschlüsselt

---

## Automatische Methoden-Wahl im Script

Das Script wählt automatisch die beste verfügbare Methode:

1. **dvdbackup + genisoimage** (schnell, entschlüsselt) ← wenn installiert
2. **ddrescue** (schnell, verschlüsselt) ← wenn installiert
3. **dd** (langsam, verschlüsselt) ← immer verfügbar

## Status prüfen

```bash
# Prüfe verfügbare Methoden
command -v dvdbackup && echo "✓ Option 1: dvdbackup (entschlüsselt)"
command -v ddrescue && echo "✓ Option 2: ddrescue (verschlüsselt, schnell)"
echo "✓ Option 3: dd (verschlüsselt, langsam) - immer verfügbar"
```
