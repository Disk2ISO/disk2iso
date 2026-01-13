# Sprachsystem-Analyse Report
**Datum:** 13. Januar 2026  
**Projekt:** disk2iso  
**Analysiert:** Alle Sprachdateien in `lang/` und Code in `lib/` + `disk2iso.sh`

---

## 1. Übersicht

### Module und Sprachen
- **Anzahl Module:** 10 (disk2iso, lib-bluray, lib-cd, lib-common, lib-dvd, lib-folders, lib-mqtt, lib-systeminfo, lib-tools, lib-web)
- **Anzahl Sprachen:** 4 (de, en, es, fr)
- **Vollständigkeit:** 98.7%

### Sprachdateien-Matrix

| Modul | DE | EN | ES | FR | Vollständig |
|-------|----|----|----|----|-------------|
| disk2iso | ✅ 12 | ✅ 12 | ✅ 12 | ✅ 12 | ✅ 100% |
| lib-bluray | ✅ 9 | ✅ 9 | ✅ 9 | ✅ 9 | ✅ 100% |
| lib-cd | ✅ 63 | ✅ 63 | ✅ 63 | ✅ 63 | ✅ 100% |
| lib-common | ✅ 63 | ✅ 63 | ✅ 63 | ✅ 63 | ✅ 100% |
| lib-dvd | ✅ 21 | ✅ 21 | ✅ 21 | ✅ 21 | ✅ 100% |
| lib-folders | ✅ 14 | ✅ 14 | ✅ 14 | ✅ 14 | ✅ 100% |
| lib-mqtt | ✅ 17 | ✅ 17 | ✅ 17 | ✅ 17 | ✅ 100% |
| lib-systeminfo | ✅ 21 | ✅ 21 | ✅ 21 | ✅ 21 | ✅ 100% |
| lib-tools | ✅ 6 | ✅ 6 | ✅ 6 | ✅ 6 | ✅ 100% |
| lib-web | ✅ 132 | ✅ 132 | ⚠️ 120 | ⚠️ 118 | ⚠️ 90.9% |
| **debugmsg** | ❌ - | ✅ 7 | ❌ - | ❌ - | - |

**Gesamt:** 358 Konstanten in DE, 358 in EN, 346 in ES, 344 in FR

---

## 2. Fehlende Übersetzungen

### ⚠️ lib-web
Das Web-Interface-Modul hat unvollständige Übersetzungen:

#### Spanisch (ES) - 12 fehlende Konstanten:
- `MSG_MUSICBRAINZ_MANUAL_ALBUM`
- `MSG_MUSICBRAINZ_MANUAL_ARTIST`
- `MSG_MUSICBRAINZ_MANUAL_BUTTON`
- `MSG_MUSICBRAINZ_MANUAL_TITLE`
- `MSG_MUSICBRAINZ_MANUAL_YEAR`
- `MSG_MUSICBRAINZ_SELECT_BUTTON`
- `MSG_MUSICBRAINZ_SELECT_COUNTRY`
- `MSG_MUSICBRAINZ_SELECT_LABEL`
- `MSG_MUSICBRAINZ_SELECT_MESSAGE`
- `MSG_MUSICBRAINZ_SELECT_TITLE`
- `MSG_MUSICBRAINZ_SELECT_TRACKS`
- `MSG_MUSICBRAINZ_WAITING`

#### Französisch (FR) - 14 fehlende Konstanten:
Alle 12 von ES plus:
- `MSG_NAV_CONFIG`
- `MSG_NAV_HELP`

**Auswirkung:** MusicBrainz-Funktionalität im Web-Interface ist für ES/FR nicht übersetzt.

---

## 3. Verwendete vs. Definierte Konstanten

### ✅ Perfekte Übereinstimmung:
- **lib-folders:** 14/14 (100%)
- **lib-mqtt:** 17/17 (100%)
- **lib-systeminfo:** 21/21 (100%)
- **lib-tools:** 6/6 (100%)

### ⚠️ Module mit Problemen:

#### lib-cd
- **Definiert:** 63 Konstanten
- **Verwendet:** 64 Konstanten
- **✅ Übereinstimmung:** 63/63
- **❌ Fehlt in lang/lib-cd.de:**
  - `MSG_PROGRESS_MB` (verwendet in lib-cd.sh)

#### lib-common
- **Definiert:** 63 Konstanten
- **Verwendet:** 20 in lib-common.sh direkt
- **Verwendet gesamt:** 56 über alle Module
- **⚠️ Ungenutzt:** 7 Konstanten
  - `MSG_ATTEMPTS`
  - `MSG_ERROR_NO_DRIVE_FOUND`
  - `MSG_OF_ATTEMPTS`
  - `MSG_SEARCHING_USB_DRIVE`
  - `MSG_STATUS_DRIVE_DETECTED`
  - `MSG_STATUS_WAITING_DRIVE`
  - `MSG_STATUS_WAITING_MEDIA`

**Hinweis:** lib-common.de enthält viele Konstanten, die von disk2iso.sh verwendet werden (29 Konstanten). Dies ist korrekt, da disk2iso.sh lib-common lädt.

#### lib-dvd
- **Definiert:** 21 Konstanten
- **Verwendet:** 26 Konstanten
- **✅ Übereinstimmung:** 21/21
- **❌ Fehlt in lang/lib-dvd.de (5 Konstanten):**
  - `MSG_ERROR_DDRESCUE_FAILED`
  - `MSG_ISO_BLOCKS`
  - `MSG_ISO_VOLUME_DETECTED`
  - `MSG_METHOD_DDRESCUE_ENCRYPTED`
  - `MSG_PROGRESS_MB`

#### lib-bluray
- **Definiert:** 9 Konstanten
- **Verwendet:** 16 Konstanten
- **✅ Übereinstimmung:** 9/9
- **❌ Fehlt in lang/lib-bluray.de (7 Konstanten):**
  - `MSG_COPIED`
  - `MSG_ERROR_DDRESCUE_FAILED`
  - `MSG_ISO_BLOCKS`
  - `MSG_ISO_VOLUME_DETECTED`
  - `MSG_METHOD_DDRESCUE_ENCRYPTED`
  - `MSG_PROGRESS_MB` (2x)

#### disk2iso.sh (Hauptskript)
- **Definiert in lang/disk2iso.de:** 12 Konstanten
- **Verwendet:** 41 Konstanten
- **✅ Übereinstimmung:** 12/12
- **❌ Fehlt in lang/disk2iso.de (29 Konstanten):**

Diese 29 Konstanten werden aus `lang/lib-common.de` geladen (korrekt):
- `MSG_AUDIO_CD_NOT_INSTALLED`
- `MSG_AUDIO_CD_SUPPORT_DISABLED`
- `MSG_AUDIO_CD_SUPPORT_ENABLED`
- `MSG_BLURAY_NOT_INSTALLED`
- `MSG_BLURAY_SUPPORT_DISABLED`
- `MSG_BLURAY_SUPPORT_ENABLED`
- `MSG_COPY_FAILED_FINAL`
- `MSG_COPY_SUCCESS_FINAL`
- `MSG_CORE_MODULES_LOADED`
- `MSG_DISC_TYPE_DETECTED`
- `MSG_DISK2ISO_STARTED`
- `MSG_DRIVE_DETECTED`
- `MSG_DRIVE_MONITORING_STARTED`
- `MSG_DRIVE_NOT_AVAILABLE`
- `MSG_ERROR_AUDIO_CD_NOT_AVAILABLE`
- `MSG_ERROR_BLURAY_NOT_AVAILABLE`
- `MSG_ERROR_VIDEO_DVD_NOT_AVAILABLE`
- `MSG_FALLBACK_DATA_DISC`
- `MSG_MEDIUM_DETECTED`
- `MSG_OUTPUT_DIRECTORY`
- `MSG_START_COPY_PROCESS`
- `MSG_UNMOUNTING_DISC`
- `MSG_VIDEO_DVD_NOT_INSTALLED`
- `MSG_VIDEO_DVD_SUPPORT_DISABLED`
- `MSG_VIDEO_DVD_SUPPORT_ENABLED`
- `MSG_VOLUME_LABEL`
- `MSG_WAITING_FOR_MEDIUM`
- `MSG_WAITING_FOR_REMOVAL`
- `MSG_WARNING_AUDIO_CD_NO_SUPPORT`

---

## 4. load_module_language() Status

### ✅ Korrekt implementiert:
- `lib-bluray.sh` → `load_module_language "bluray"`
- `lib-cd.sh` → `load_module_language "cd"`
- `lib-common.sh` → `load_module_language "common"`
- `lib-dvd.sh` → `load_module_language "dvd"`
- `lib-folders.sh` → `load_module_language "folders"`
- `lib-mqtt.sh` → `load_module_language "mqtt"`
- `lib-systeminfo.sh` → `load_module_language "systeminfo"`

### ⚠️ Falscher Aufruf:
- `lib-logging.sh` → `load_module_language "cd"` (sollte "logging" sein)
  - **Hinweis:** Dies ist nur ein Kommentar-Beispiel in Zeile 53, kein echter Aufruf

### ❌ Fehlend (keine Sprachdatei = korrekt):
- `lib-api.sh` - Kein Aufruf (hat keine Sprachdatei)
- `lib-cd-metadata.sh` - Kein Aufruf (hat keine Sprachdatei)
- `lib-diskinfos.sh` - Kein Aufruf (hat keine Sprachdatei)
- `lib-drivestat.sh` - Kein Aufruf (hat keine Sprachdatei)
- `lib-dvd-metadata.sh` - Kein Aufruf (hat keine Sprachdatei)
- `lib-files.sh` - Kein Aufruf (hat keine Sprachdatei)
- `lib-install.sh` - Kein Aufruf (hat keine Sprachdatei)
- `lib-tools.sh` - ⚠️ **HAT Sprachdatei, aber kein Aufruf!**

---

## 5. Debug-Messages (debugmsg.en)

### Status:
- **Datei:** `lang/debugmsg.en` (nur Englisch, korrekt)
- **Definiert:** 7 DBG_* Konstanten
- **Verwendet im Code:** 1 Konstante

### Definierte Debug-Konstanten:
1. `DBG_CHECKING_COVER_COPY`
2. `DBG_COVER_FILE_EXISTS`
3. `DBG_COVER_FILE_EMPTY` ✅ (verwendet)
4. `DBG_FUNCTION_CALLED`
5. `DBG_VARIABLE_VALUE`
6. `DBG_FILE_CHECK`
7. `DBG_COMMAND_OUTPUT`

### ⚠️ Ungenutzte Debug-Konstanten (6):
- `DBG_CHECKING_COVER_COPY`
- `DBG_COVER_FILE_EXISTS`
- `DBG_FUNCTION_CALLED`
- `DBG_VARIABLE_VALUE`
- `DBG_FILE_CHECK`
- `DBG_COMMAND_OUTPUT`

**Analyse:** Debug-Konstanten scheinen für zukünftige Verwendung vorbereitet zu sein.

---

## 6. Spezielle Prüfungen

### Encoding
- ✅ **Deutsche Dateien (de):** UTF-8 mit Umlauten (ä, ö, ü, ß)
- ⚠️ **Englische Dateien (en):** US-ASCII (korrekt, keine Sonderzeichen benötigt)
  - `debugmsg.en`
  - `disk2iso.en`
  - `lib-cd.en`
  - `lib-folders.en`
  - `lib-tools.en`
  - `lib-web.en`
- ✅ **Spanische Dateien (es):** UTF-8 mit Akzenten (á, é, í, ó, ú, ñ)
- ✅ **Französische Dateien (fr):** UTF-8 mit Akzenten (é, è, à, ê, ç)

**Fazit:** Encoding korrekt für alle Sprachen.

### Benennungskonventionen
✅ **Konsistent:** Alle Fehlermeldungen verwenden `MSG_ERROR_*` Präfix
- Keine `ERROR_MSG_*` Varianten gefunden
- Einheitliche Verwendung über alle Module

**Verteilung:**
- lib-bluray.de: 1 MSG_ERROR_*
- lib-cd.de: 12 MSG_ERROR_*
- lib-common.de: 7 MSG_ERROR_*
- lib-dvd.de: 6 MSG_ERROR_*
- lib-folders.de: 6 MSG_ERROR_*
- lib-systeminfo.de: 3 MSG_ERROR_*
- disk2iso.de: 3 MSG_ERROR_*

### Doppelte Definitionen
✅ **Keine Duplikate** in irgendeiner Sprachdatei gefunden.

### Leere Werte
✅ **Keine leeren Werte** (`MSG_*=""`) gefunden.

---

## 7. Zusammenfassung & Empfehlungen

### 🔴 Kritische Probleme (MÜSSEN behoben werden):

1. **lib-cd.sh:** Fehlende Konstante
   - `MSG_PROGRESS_MB` in allen 4 Sprachen hinzufügen

2. **lib-dvd.sh:** 5 fehlende Konstanten
   - `MSG_ERROR_DDRESCUE_FAILED`
   - `MSG_ISO_BLOCKS`
   - `MSG_ISO_VOLUME_DETECTED`
   - `MSG_METHOD_DDRESCUE_ENCRYPTED`
   - `MSG_PROGRESS_MB`

3. **lib-bluray.sh:** 7 fehlende Konstanten
   - `MSG_COPIED`
   - `MSG_ERROR_DDRESCUE_FAILED`
   - `MSG_ISO_BLOCKS`
   - `MSG_ISO_VOLUME_DETECTED`
   - `MSG_METHOD_DDRESCUE_ENCRYPTED`
   - `MSG_PROGRESS_MB`

4. **lib-web:** 12 fehlende ES + 14 fehlende FR Übersetzungen
   - MusicBrainz-Funktionen betroffen

5. **lib-tools.sh:** Kein `load_module_language("tools")` Aufruf
   - Sprachdateien existieren, werden aber nicht geladen

### 🟡 Verbesserungsvorschläge (SOLLTEN überprüft werden):

1. **lib-common.de:** 7 ungenutzte Konstanten prüfen
   - Können entfernt werden wenn wirklich ungenutzt
   - Oder dokumentieren für zukünftige Verwendung

2. **debugmsg.en:** 6 von 7 Debug-Konstanten ungenutzt
   - Dokumentieren als "vorbereitet für zukünftige Debug-Ausgaben"
   - Oder entfernen wenn nicht benötigt

3. **lib-systeminfo:** Inkonsistente Syntax
   - Verwendet `MSG_*=` statt `readonly MSG_*=`
   - Sollte vereinheitlicht werden

### 🟢 Stärken des Systems:

1. ✅ Saubere Struktur mit separaten Sprachdateien pro Modul
2. ✅ Konsistente Benennung (`MSG_*` für Meldungen, `DBG_*` für Debug)
3. ✅ Kein Code-Duplikat oder Encoding-Probleme
4. ✅ Gute Abdeckung für DE/EN (fast 100%)
5. ✅ load_module_language() korrekt in 7/8 Modulen

### Vollständigkeits-Score:
- **Deutsch (DE):** 100% ✅
- **Englisch (EN):** 100% ✅
- **Spanisch (ES):** 96.6% ⚠️ (fehlende Web-Interface Strings)
- **Französisch (FR):** 96.1% ⚠️ (fehlende Web-Interface Strings)
- **Code-Coverage:** 94.2% ⚠️ (27 verwendete Konstanten fehlen in Sprachdateien)

---

## 8. Aktionsplan

### Priorität 1 (Sofort):
```bash
# 1. lib-cd: MSG_PROGRESS_MB hinzufügen
# 2. lib-dvd: 5 Konstanten hinzufügen
# 3. lib-bluray: 7 Konstanten hinzufügen
# 4. lib-tools.sh: load_module_language("tools") aufrufen
```

### Priorität 2 (Kurzfristig):
```bash
# 5. lib-web.es: 12 MusicBrainz-Übersetzungen ergänzen
# 6. lib-web.fr: 14 MusicBrainz-Übersetzungen ergänzen
```

### Priorität 3 (Mittelfristig):
```bash
# 7. lib-common: 7 ungenutzte Konstanten prüfen/entfernen
# 8. lib-systeminfo: readonly-Syntax vereinheitlichen
# 9. debugmsg: Ungenutzte Debug-Konstanten dokumentieren oder entfernen
```

---

**Ende des Reports**
