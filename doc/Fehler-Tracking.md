# DVD Fehler-Tracking & Intelligenter Fallback

## Übersicht

Das Fehler-Tracking-System in `disk2iso` bietet eine intelligente Fehlerbehandlung für problematische DVDs mit automatischem Fallback auf fehlertolerante Methoden.

## Funktionsweise

### Drei-Stufen-System

```
1. Versuch: dvdbackup (schnell, entschlüsselt)
    ↓ Fehler
2. Versuch: ddrescue (robust, fehlertoleranter)
    ↓ Fehler
3. Versuch: ABLEHNUNG (DVD ist unlesbar)
```

### Workflow

#### **Szenario 1: Erfolgreicher erster Versuch**
```
DVD einlegen → dvdbackup kopiert → ISO erstellt → Erfolg ✓
```

#### **Szenario 2: Fehler beim ersten Versuch**
```
1. DVD einlegen → dvdbackup fehlschlägt → Fehler registriert
   Ausgabe: "ℹ DVD wird beim nächsten Versuch mit ddrescue kopiert"

2. DVD reinigen → DVD erneut einlegen
   Ausgabe: "⚠ Diese DVD ist beim letzten Versuch fehlgeschlagen"
   Ausgabe: "→ Automatischer Fallback auf ddrescue (fehlertolerante Methode)"
   → ddrescue kopiert → ISO erstellt → Erfolg ✓
   → Fehler-Historie wird gelöscht
```

#### **Szenario 3: Mehrfacher Fehler**
```
1. DVD einlegen → dvdbackup fehlschlägt → Fehler registriert

2. DVD reinigen → DVD erneut einlegen
   → ddrescue fehlschlägt → Zweiter Fehler registriert
   Ausgabe: "✗ DVD endgültig fehlgeschlagen - wird beim nächsten Einlegen abgelehnt"

3. DVD erneut einlegen
   Ausgabe: "✗ DVD wird abgelehnt: Bereits 2x fehlgeschlagen"
   Ausgabe: "Hinweis: DVD reinigen/ersetzen und .failed_dvds Datei löschen zum Zurücksetzen"
   → Kopiervorgang wird NICHT gestartet
```

## Technische Details

### Fehler-Datei

- **Speicherort**: `${IMAGE_PATH}/.failed_dvds`
- **Format**: `disc_label:disc_type|timestamp|method`
- **Beispiel**:
  ```
  supernatural_season_10_disc_3:dvd-video|2026-01-10 00:11:48|dvdbackup
  supernatural_season_10_disc_3:dvd-video|2026-01-10 00:52:09|ddrescue
  ```

### Funktionen

| Funktion | Beschreibung |
|----------|--------------|
| `get_dvd_identifier()` | Erstellt eindeutigen ID aus Label + Typ |
| `get_dvd_failure_count()` | Prüft Anzahl bisheriger Fehlversuche (0-2) |
| `register_dvd_failure()` | Registriert Fehlschlag mit Timestamp |
| `clear_dvd_failures()` | Löscht Fehler-Historie nach Erfolg |

### Methodenauswahl

```bash
failure_count = 0  → dvdbackup
failure_count = 1  → ddrescue (automatisch)
failure_count ≥ 2  → ABLEHNUNG
```

## Benutzung

### DVD nach Fehler zurücksetzen

Wenn eine DVD fälschlicherweise abgelehnt wird (z.B. nach Reinigung/Reparatur):

```bash
# Option 1: Gesamte Fehler-Historie löschen
rm /path/to/images/.failed_dvds

# Option 2: Nur eine spezifische DVD zurücksetzen
sed -i '/supernatural_season_10_disc_3/d' /path/to/images/.failed_dvds
```

### Fehler-Historie anzeigen

```bash
cat /path/to/images/.failed_dvds
```

## Vorteile

✅ **Nutzerfreundlich**: Automatischer Fallback ohne manuelle Konfiguration  
✅ **Intelligent**: Lernt aus Fehlern und passt Strategie an  
✅ **Sicher**: Verhindert endlose Versuche bei kaputten DVDs  
✅ **Transparent**: Klare Meldungen über den aktuellen Status  
✅ **Wartbar**: Einfache Reset-Möglichkeit über Dateilöschung  

## Log-Beispiele

### Erster Fehler
```
2026-01-10 12:34:56 - FEHLER: dvdbackup fehlgeschlagen (Exit-Code: 255)
2026-01-10 12:34:56 - ℹ DVD wird beim nächsten Versuch mit ddrescue kopiert
```

### Automatischer Fallback
```
2026-01-10 12:45:12 - ⚠ Diese DVD ist beim letzten Versuch fehlgeschlagen
2026-01-10 12:45:12 - → Automatischer Fallback auf ddrescue (fehlertolerante Methode)
2026-01-10 12:45:12 - Methode: Verschlüsseltes Kopieren (ddrescue)
```

### Finale Ablehnung
```
2026-01-10 13:00:00 - ✗ DVD wird abgelehnt: Bereits 2x fehlgeschlagen
2026-01-10 13:00:00 - Hinweis: DVD reinigen/ersetzen und .failed_dvds Datei löschen zum Zurücksetzen
```

## Kompatibilität

- ✅ Funktioniert mit allen DVD-Typen (video-dvd, data-dvd)
- ✅ Mehrsprachig (DE, EN, ES, FR)
- ✅ Container-sicher (LXC, Docker)
- ✅ MQTT-Integration (Statusmeldungen werden übermittelt)

## Version

Eingeführt in: **disk2iso v1.2.1**  
Letzte Aktualisierung: 10.01.2026
