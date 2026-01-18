# GitHub Issues - disk2iso v1.2.0
**Stand:** 18.01.2026  
**Quelle:** https://github.com/DirkGoetze/disk2iso/issues  
**Status:** 14 Open, 6 Closed/Teilweise behoben

---

## 📊 ÜBERSICHT NACH KATEGORIEN

### 🎵 AUDIO-CD / MP3 TAGGING (lib-cd.sh, lib-cd-metadata.sh)
- [#22](https://github.com/DirkGoetze/disk2iso/issues/22) - Taggen von MP3 bei mehreren Interpreten (enhancement)
- [#21](https://github.com/DirkGoetze/disk2iso/issues/21) - Taggen von MP3 bei Samplern (enhancement)

### 📀 DVD/BLU-RAY METADATEN (lib-dvd.sh, lib-bluray.sh, lib-dvd-metadata.sh)
- [#6](https://github.com/DirkGoetze/disk2iso/issues/6) - DVD Metadaten (feat)
- [#4](https://github.com/DirkGoetze/disk2iso/issues/4) - Archiv - Metadaten hinzufügen funktioniert nicht (bug)

### 🌐 WEB-UI INTERFACE (www/app.py, www/templates/, www/static/)
- [#19](https://github.com/DirkGoetze/disk2iso/issues/19) - Archivierte Logs über WEB-UI öffnen
- [#13](https://github.com/DirkGoetze/disk2iso/issues/13) - Anzeige zum Service (enhancement)
- [#12](https://github.com/DirkGoetze/disk2iso/issues/12) - Home Seite unruhig (enhancement)
- [#10](https://github.com/DirkGoetze/disk2iso/issues/10) - Feat. Anzeige kompakter machen (feat)
- [#9](https://github.com/DirkGoetze/disk2iso/issues/9) - Anzeige von ISO Dateien (bug)
- [#8](https://github.com/DirkGoetze/disk2iso/issues/8) - Einstellungen Ausgabeverzeichnis (feat)

### 🐛 SYSTEM / SERVICE (disk2iso.sh, lib-common.sh)
- [#15](https://github.com/DirkGoetze/disk2iso/issues/15) - Fehlgeschlagene Kopiervorgänge (feat)

### 📡 MQTT INTEGRATION (lib-mqtt.sh)
- [#11](https://github.com/DirkGoetze/disk2iso/issues/11) - MQTT Meldungen kommen doppelt (bug)

---

## 🔥 KRITISCH - BUGS (Priorität: HOCH)

### #11 - MQTT Meldungen kommen doppelt ❌ BUG
**Bereich:** lib-mqtt.sh  
**Beschreibung:**  
MQTT-Nachrichten werden doppelt gesendet

**Mögliche Ursachen:**
- `publish_mqtt()` wird zweimal aufgerufen
- Mehrere MQTT-Clients aktiv
- Retain-Flag verursacht Echo

**Betroffene Dateien:**
- `lib/lib-mqtt.sh`
- Alle Stellen die MQTT-Funktionen aufrufen

**Status:** Offen - Diagnose nötig: Logging aktivieren, MQTT-Broker Logs prüfen

---

### #9 - Anzeige von ISO Dateien ❌ BUG
**Bereich:** www/app.py / www/templates/archive.html  
**Beschreibung:**  
ISO-Dateien werden nicht korrekt angezeigt im Archiv

**Betroffene Dateien:**
- `www/app.py` - `/archive` Route
- `www/templates/archive.html`
- Möglicherweise `get_iso_files_by_type()` Funktion

**Status:** Offen - Diagnose nötig: Detaillierte Beschreibung was nicht funktioniert

---

### #4 - Archiv - Metadaten hinzufügen funktioniert nicht ❌ BUG
**Bereich:** www/app.py - Archiv-Management  
**Beschreibung:**  
Nachträgliches Hinzufügen von Metadaten über Web-UI schlägt fehl

**Betroffene Dateien:**
- `www/app.py` - Metadata-Update Endpoints
- `www/templates/archive.html`

**Status:** Offen - Diagnose nötig: Detaillierte Beschreibung, Error-Logs

---

## ⚡ WICHTIG - SERVICE / SYSTEM

### #15 - Fehlgeschlagene Kopiervorgänge ✨ FEATURE
**Bereich:** lib-common.sh / disk2iso.sh  
**Beschreibung:**  
Bessere Behandlung fehlgeschlagener Kopiervorgänge
- Wiederholungsversuche
- Fehler-Logging
- Benachrichtigung via MQTT

**Betroffene Dateien:**
- `lib/lib-common.sh` - Copy-Funktionen
- `disk2iso.sh` - State-Machine
- `lib/lib-mqtt.sh` - Error-Notifications

**Status:** Offen - Enhancement für Robustness-Verbesserungen

---

## 🎨 UI/UX VERBESSERUNGEN

### #19 - Archivierte Logs über WEB-UI öffnen ✨ FEATURE
**Bereich:** www/app.py + www/templates/logs.html  
**Beschreibung:**  
Archivierte Logs können gesucht, aber nicht angezeigt werden

**Betroffene Dateien:**
- `www/app.py` - Neue Route `/logs/view/<filename>`
- `www/templates/logs.html` - Link zu archivierten Logs

**Status:** Offen - Endpoint zum Anzeigen archivierter Log-Dateien fehlt

---

### #13 - Anzeige zum Service ✨ ENHANCEMENT
**Bereich:** www/templates/index.html  
**Beschreibung:**  
Bessere Visualisierung des Service-Status

**Ideen:**
- Service läuft seit: Uptime
- Letzte Aktivität: Zeitstempel
- Status-Icon: Grün/Gelb/Rot

**Betroffene Dateien:**
- `www/app.py` - `/api/status` erweitern
- `www/templates/index.html`

**Status:** Offen - Enhancement

---

### #12 - Home Seite unruhig ✨ ENHANCEMENT
**Bereich:** www/static/js/index.js  
**Beschreibung:**  
AJAX-Polling verursacht flackernde UI-Updates

**Lösung:**
- Diff-basierte Updates (nur Änderungen)
- CSS-Transitions für sanfte Übergänge
- Debouncing

**Betroffene Dateien:**
- `www/static/js/index.js` - `updateStatus()`

**Status:** Offen - UX-Verbesserung

---

### #10 - Feat. Anzeige kompakter machen ✨ FEATURE
**Bereich:** www/templates/ + www/static/css/style.css  
**Beschreibung:**  
UI optimieren für weniger Scrolling

**Ideen:**
- Kollapsbare Sektionen
- Kompaktere Layouts
- Responsive Design verbessern

**Status:** Offen - Enhancement

---

### #8 - Einstellungen Ausgabeverzeichnis ✨ FEATURE
**Bereich:** www/templates/config.html + www/app.py  
**Beschreibung:**  
Ausgabeverzeichnis in Web-UI änderbar machen

**Betroffene Dateien:**
- `www/templates/config.html` - Input für `DEFAULT_OUTPUT_DIR`
- `www/app.py` - `/api/config` POST erweitern
- `lib/lib-config.sh` - `update_config_value()` nutzen

**Status:** Offen - Validierung ob Pfad existiert & beschreibbar!

---

## 🎵 AUDIO-CD ENHANCEMENTS

### #22 - Taggen von MP3 bei mehreren Interpreten ✨ ENHANCEMENT
**Bereich:** lib-cd-metadata.sh  
**Beschreibung:**  
Besseres Tagging bei "feat." Artists:
```
Titel: "Driving Home for Christmas"
Artist: "Chris Rea feat. XYZ"

Soll werden:
- Album: Original Album von Chris Rea
- AlbumArtist: Chris Rea
- Title: Driving Home for Christmas
- Artist: Chris Rea feat. XYZ

Ordnerstruktur: /Chris Rea/Album/Track.mp3
```

**Betroffene Dateien:**
- `lib/lib-cd-metadata.sh` - Tag-Logik
- MusicBrainz API - Artist-Parsing

**Status:** Offen - Komplexität: Mittel - MusicBrainz Artist-Credits nutzen

---

### #21 - Taggen von MP3 bei Samplern ✨ ENHANCEMENT
**Bereich:** lib-cd-metadata.sh  
**Beschreibung:**  
Sampler mit "AlbumArtist: Various Artists" besser handhaben:
```
Aktuell (schlecht):
/Various Artists/Rock Christmas/01 - Driving Home.mp3
/Various Artists/Rock Christmas/02 - Last Christmas.mp3

Soll werden:
/Chris Rea/Original Album/01 - Driving Home.mp3
/Wham!/Original Album/02 - Last Christmas.mp3
```

**Logik:**
1. Erkenne `AlbumArtist == "Various Artists"`
2. Für jeden Track: Suche Original-Album des Künstlers
3. Erstelle Ordner: `/Artist/OriginalAlbum/Track.mp3`
4. Generiere Album-Cover pro Artist-Album
5. Tags: AlbumArtist = Artist, Album = OriginalAlbum

**Betroffene Dateien:**
- `lib/lib-cd-metadata.sh`
- `lib/lib-folders.sh` - Mehrere Ordner pro CD
- MusicBrainz API - Recording-Lookup

**Status:** Offen - Komplexität: HOCH - Erfordert zusätzliche API-Calls pro Track

---

### #6 - DVD Metadaten (feat)
**Bereich:** lib-dvd-metadata.sh  
**Beschreibung:** Details unklar

**Status:** Offen - Detaillierte Beschreibung erforderlich

---

## 📋 PRIORITÄTEN-EMPFEHLUNG

### 🔴 KRITISCH (Sofort)
1. **#11** - MQTT doppelte Meldungen (Funktionalität)
2. **#9** - ISO-Dateien Anzeige-Bug (Details unklar)
3. **#4** - Metadaten nachträglich hinzufügen

### 🟡 HOCH (Bald)
4. **#15** - Fehlerbehandlung verbessern
5. **#19** - Archivierte Logs anzeigen
6. **#8** - Ausgabeverzeichnis über UI ändern

### 🟢 MITTEL (Geplant)
7. **#13** - Service-Anzeige verbessern
8. **#12** - UI-Flackern reduzieren
9. **#10** - Kompaktere Anzeige
10. **#6** - DVD Metadaten (Details unklar)

### 🎨 ENHANCEMENTS (Features)
11. **#22** - MP3-Tagging feat. Artists (Komplex)
12. **#21** - MP3-Tagging Sampler (Sehr komplex)

---

## ✅ ERLEDIGTE ISSUES

### #18 - LOG oder CODE Fehler (Doppelter Slash im Pfad) ✅ BEHOBEN
**Status:** ✅ **BEHOBEN**  
**Behoben am:** 18.01.2026

**Ursprüngliches Problem:**
Doppelter Slash im Ausgabepfad: `/mnt/pve/Public/images//dvd/...`

**Lösung implementiert:**
- [lib-folders.sh:45](l:\clouds\onedrive\Dirk\projects\disk2iso\lib\lib-folders.sh#L45): `"${OUTPUT_DIR%/}/"` verwendet
- Alle anderen Stellen bereits korrekt: `"${OUTPUT_DIR}/${SUBFOLDER}"`
- lib-logging.sh, lib-dvd.sh, lib-bluray.sh, lib-dvd-metadata.sh geprüft

**Verifikation:** ✅ Kein doppelter Slash mehr möglich

---

### #17 - Fehlender Neustart nach Config-Änderung ✅ BEHOBEN
**Status:** ✅ **BEHOBEN**  
**Behoben am:** 18.01.2026

**Ursprüngliches Problem:**
Nach Speichern der Einstellungen wurde Service nicht automatisch neu gestartet

**Lösung implementiert:**
- [lib-config.sh:190-275](l:\clouds\onedrive\Dirk\projects\disk2iso\lib\lib-config.sh#L190-L275): `apply_config_changes()` Funktion
- [lib-config.sh:246-275](l:\clouds\onedrive\Dirk\projects\disk2iso\lib\lib-config.sh#L246-L275): `perform_service_restarts()` Funktion
- Intelligente Service-Neustarts basierend auf geänderten Config-Keys
- Config-Handler mit Service-Mapping (disk2iso vs disk2iso-web)
- [www/app.py:714-800](l:\clouds\onedrive\Dirk\projects\disk2iso\www\app.py#L714-L800): Integration via Bash-Funktion

**Verifikation:** ✅ Services werden automatisch neu gestartet wenn nötig

---

### #16 - Passwort Feld nicht verschlüsselt ✅ BEHOBEN
**Status:** ✅ **BEHOBEN**  
**Behoben am:** 18.01.2026

**Ursprüngliches Problem:**
MQTT-Passwort wurde als Klartext angezeigt statt als `<input type="password">`

**Lösung implementiert:**
- [www/templates/config.html:230](l:\clouds\onedrive\Dirk\projects\disk2iso\www\templates\config.html#L230): Korrektes `type="password"` Feld vorhanden

**Verifikation:** ✅ Passwort-Feld ist maskiert

---

### #14 - Menü verschwindet wenn Seite länger ✅ BEHOBEN
**Status:** ✅ **BEHOBEN**  
**Behoben am:** 18.01.2026

**Ursprüngliches Problem:**
Sticky-Navigation fehlte - Menü scrollte weg bei langen Seiten

**Lösung implementiert:**
- [www/static/css/style.css:29-31](l:\clouds\onedrive\Dirk\projects\disk2iso\www\static\css\style.css#L29-L31): Sticky Header mit `position: sticky; top: 0; z-index: 1000;`

**Verifikation:** ✅ Navigation bleibt beim Scrollen sichtbar

---

### #20 - Formatierungsproblem Fortschritt ⚠️ TEILWEISE BEHOBEN
**Status:** ⚠️ **TEILWEISE BEHOBEN**  
**Problem noch vorhanden am:** 18.01.2026

**Ursprüngliches Problem:**
Fortschrittsbalken Speicherplatz zeigte falsche Richtung:
- Aktuell: Balken wird kleiner bei mehr Belegung (falsch)
- Soll: Balken wächst von links nach rechts mit Belegung

**Aktueller Code:**
```html
<div class="progress-bar" data-label="{{ disk_space.used_percent }}% belegt">
    <div class="progress-background"></div>
    <div class="progress-overlay" style="width: {{ disk_space.free_percent }}%"></div>
</div>
```

**Problem:** `width: {{ disk_space.free_percent }}%` → sollte `width: {{ disk_space.used_percent }}%` sein

**Betroffene Dateien:**
- [www/templates/index.html:65-67](l:\clouds\onedrive\Dirk\projects\disk2iso\www\templates\index.html#L65-L67)

**Noch zu tun:** Template korrigieren: `free_percent` → `used_percent`

---

### #7 - DVD/BD Metadaten funktioniert nicht ⚠️ TEILWEISE BEHOBEN
**Status:** ⚠️ **TEILWEISE BEHOBEN**  
**Verbessert am:** 18.01.2026

**Ursprüngliches Problem:**
TMDB-Metadaten-Abruf für DVDs/Blu-rays funktionierte nicht

**Implementierte Verbesserungen:**
- [lib-dvd-metadata.sh:90-118](l:\clouds\onedrive\Dirk\projects\disk2iso\lib\lib-dvd-metadata.sh#L90-L118): `check_dvd_metadata_dependencies()` Funktion
- Runtime-Prüfung von jq, curl und TMDB_API_KEY
- User-Agent Header bei allen TMDB API-Calls
- Klare Fehlermeldungen bei fehlenden Dependencies
- Integration in disk2iso.sh Startup

**Noch offen:**
- **Laufzeit-Tests erforderlich** mit realem TMDB_API_KEY
- Error-Handling bei API-Fehlern könnte verbessert werden
- Diagnose warum Metadaten konkret nicht funktionieren

**Nächste Schritte:**
1. TMDB_API_KEY konfigurieren
2. Live-Test mit DVD/Blu-ray
3. Log-Analyse bei Fehlern

---

### #5 - Audio CD - Meta Daten erfassen ⚠️ TEILWEISE BEHOBEN
**Status:** ⚠️ **TEILWEISE BEHOBEN**  
**Verbessert am:** 18.01.2026

**Ursprüngliches Problem:**
MusicBrainz-Metadaten für Audio-CDs wurden nicht korrekt abgerufen

**Implementierte Verbesserungen:**
- [lib-cd-metadata.sh:40-69](l:\clouds\onedrive\Dirk\projects\disk2iso\lib\lib-cd-metadata.sh#L40-L69): `check_audio_metadata_dependencies()` Funktion
- Runtime-Prüfung von jq, curl, eyeD3, id3v2
- User-Agent Header in allen MusicBrainz API-Calls (RFC-konform)
- URL-Encoding Funktion für sichere API-Requests
- API-Konstanten (MUSICBRAINZ_API_BASE_URL, COVERART_API_BASE_URL)
- Cache-basierte API-Funktionen (`fetch_musicbrainz_raw()`, `fetch_coverart()`)
- Artist-Sanitization für sichere Dateinamen
- Integration in disk2iso.sh Startup

**Noch offen:**
- **Laufzeit-Tests erforderlich** mit realen Audio-CDs
- Diagnose warum Metadaten konkret nicht funktionieren
- Cover-Art Download könnte optimiert werden

**Nächste Schritte:**
1. Live-Test mit Audio-CD
2. Log-Analyse bei Fehlern
3. MusicBrainz API Response prüfen

---

## 📝 HINWEISE FÜR BEARBEITUNG

- **Bugs zuerst!** Funktionalität > Features
- **MQTT #11:** Benötigt Debugging mit MQTT-Broker Logs
- **ISO-Anzeige #9:** Detaillierte Fehlerbeschreibung erforderlich
- **Komplexe Features (#21, #22):** Erfordern MusicBrainz-Expertise
- **Metadaten-Issues (#5, #7):** Teilweise behoben, Runtime-Tests ausstehend

**Empfohlene Reihenfolge:** #20 Template-Fix → #11 MQTT Debug → #9 ISO-Anzeige → #4 Metadaten nachträglich → #5/#7 Runtime-Tests
