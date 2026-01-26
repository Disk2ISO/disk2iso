# Analyse: Ladereihenfolge vs. Prüfreihenfolge in disk2iso.sh

**Datum:** 2026-01-26  
**Status:** Analyse - noch keine Anpassungen

## Aktuelle Ladereihenfolge (source-Befehle)

```bash
1.  libconfig.sh
2.  liblogging.sh
3.  libapi.sh
4.  libfiles.sh
5.  libfolders.sh
6.  libintegrity.sh
7.  libdiskinfos.sh
8.  libdrivestat.sh
9.  libsysteminfo.sh
10. libcommon.sh
```

## Aktuelle Prüfreihenfolge (check_dependencies_*)

```bash
1.  check_dependencies_config
2.  check_dependencies_logging
3.  check_dependencies_folders
4.  check_dependencies_files
5.  check_dependencies_api
6.  check_dependencies_integrity
7.  check_dependencies_diskinfos
8.  check_dependencies_drivestat
9.  check_dependencies_systeminfo
10. check_dependencies_common
```

## Modul-Abhängigkeiten (laut Header)

| Modul | Dependencies |
|-------|-------------|
| **libconfig** | Keine (POSIX: awk, sed, grep) |
| **liblogging** | Optional: libfolders (für LOG_DIR) |
| **libapi** | Keine (nur Bash) |
| **libfiles** | Keine (nur Bash) |
| **libfolders** | liblogging (für log_*) |
| **libintegrity** | libconfig (INI), liblogging, libfolders |
| **libdiskinfos** | liblogging |
| **libdrivestat** | liblogging |
| **libsysteminfo** | liblogging |
| **libcommon** | liblogging, libfolders |

## 🔴 Erkannte Diskrepanzen

### 1. **libfolders vs. liblogging - Zirkuläre Abhängigkeit**

**Problem:**
- **liblogging** (Zeile 87) wird VOR **libfolders** (Zeile 89) geladen
- **libfolders** Header sagt: `Dependencies: liblogging (für log_* Funktionen)`
- **liblogging** Header sagt: `Dependencies: Optional libfolders (für LOG_DIR)`

**Auswirkung:**
- Wenn liblogging beim Laden libfolders braucht, ist das problematisch
- ABER: liblogging sagt "Optional" → sollte funktionieren
- libfolders kann beim Laden log_* nicht nutzen → könnte echo statt log_* nutzen

**Analyse:**
- liblogging sollte KEINE harte Abhängigkeit von libfolders haben
- libfolders KANN liblogging nutzen wenn es bereits geladen ist
- **Prüfreihenfolge:** folders vor logging ist FALSCH (Zeile 118 vs 113)

### 2. **libintegrity - Ladereihenfolge stimmt NICHT mit Dependencies**

**Problem:**
- **libintegrity** benötigt: libconfig, liblogging, libfolders
- Geladen wird libintegrity an Position 6 (nach allen Dependencies ✅)
- ABER: Geprüft wird integrity an Position 6, NACH folders (Position 3)
- libintegrity braucht libfolders → folders muss VOR integrity geprüft werden ✅

**Auswirkung:**
- Ladereihenfolge ist korrekt
- Prüfreihenfolge ist korrekt
- ✅ KEINE Diskrepanz

### 3. **libcommon - Als LETZTES geladen, aber braucht liblogging + libfolders**

**Problem:**
- **libcommon** wird als LETZTES geladen (Position 10)
- **libcommon** benötigt: liblogging, libfolders
- Beide sind bereits geladen ✅

**ABER:**
- libcommon enthält Kern-Funktionen wie `copy_disc()`, `eject_disc()`, `check_disk_space()`
- Diese werden von anderen Modulen benötigt (libaudio, libdvd, libbluray)
- libcommon sollte FRÜHER geladen werden, BEVOR die optionalen Module

**Auswirkung:**
- Kern-Module sind OK
- ABER: Optionale Module (audio, dvd, bluray) brauchen libcommon
- libcommon wird NACH allen Kern-Modulen, ABER VOR optionalen Modulen geladen ✅

### 4. **Prüfreihenfolge stimmt NICHT mit Ladereihenfolge überein**

**Diskrepanz:**

| Laden (source) | Prüfen (check) | Stimmt überein? |
|----------------|----------------|-----------------|
| 1. config | 1. config | ✅ |
| 2. logging | 2. logging | ✅ |
| 3. api | 5. api | ❌ |
| 4. files | 4. files | ❌ (Reihenfolge vertauscht) |
| 5. folders | 3. folders | ❌ |
| 6. integrity | 6. integrity | ✅ |
| 7. diskinfos | 7. diskinfos | ✅ |
| 8. drivestat | 8. drivestat | ✅ |
| 9. systeminfo | 9. systeminfo | ✅ |
| 10. common | 10. common | ✅ |

**Problem:**
- **folders** wird geladen NACH api/files, aber geprüft DAVOR
- **api** wird geladen VOR folders, aber geprüft DANACH

## 📊 Optimale Reihenfolge (nach Abhängigkeiten)

### Empfohlene Ladereihenfolge:

```
Level 0 (Keine Dependencies):
  1. libconfig.sh       # Keine Dependencies
  2. libfiles.sh        # Keine Dependencies
  
Level 1 (Nur POSIX/Bash):
  3. liblogging.sh      # Optional: libfolders (funktioniert ohne)
  
Level 2 (Benötigen liblogging):
  4. libfolders.sh      # Benötigt: liblogging
  5. libapi.sh          # Keine Dependencies (könnte auch früher)
  
Level 3 (Benötigen config/logging/folders):
  6. libintegrity.sh    # Benötigt: libconfig, liblogging, libfolders
  7. libdiskinfos.sh    # Benötigt: liblogging
  8. libdrivestat.sh    # Benötigt: liblogging
  9. libsysteminfo.sh   # Benötigt: liblogging
  
Level 4 (Benötigen mehrere Core-Module):
  10. libcommon.sh      # Benötigt: liblogging, libfolders
```

### Empfohlene Prüfreihenfolge (= Ladereihenfolge):

```
1. check_dependencies_config
2. check_dependencies_files
3. check_dependencies_logging
4. check_dependencies_folders
5. check_dependencies_api
6. check_dependencies_integrity
7. check_dependencies_diskinfos
8. check_dependencies_drivestat
9. check_dependencies_systeminfo
10. check_dependencies_common
```

## 🔧 Vorgeschlagene Korrekturen

### Option A: Prüfreihenfolge an Ladereihenfolge anpassen (minimal)

**Ändere nur die Prüfreihenfolge:**
```bash
# Aktuell:
folders (3) → files (4) → api (5)

# Neu:
api (3) → files (4) → folders (5)
```

**Vorteil:** Minimale Änderung  
**Nachteil:** Nicht logisch (folders braucht logging, wird aber später geprüft)

### Option B: Beide Reihenfolgen optimieren (empfohlen)

**Neue Lade- UND Prüfreihenfolge:**
```bash
1. libconfig      → check_dependencies_config
2. libfiles       → check_dependencies_files
3. liblogging     → check_dependencies_logging
4. libfolders     → check_dependencies_folders
5. libapi         → check_dependencies_api
6. libintegrity   → check_dependencies_integrity
7. libdiskinfos   → check_dependencies_diskinfos
8. libdrivestat   → check_dependencies_drivestat
9. libsysteminfo  → check_dependencies_systeminfo
10. libcommon     → check_dependencies_common
```

**Vorteil:** 
- Logisch konsistent
- Abhängigkeiten werden eingehalten
- Prüf- = Ladereihenfolge (einfacher zu warten)

**Nachteil:** 
- Mehr Änderungen
- libfiles wird früher geladen (aber hat keine Dependencies → kein Problem)

### Option C: Zirkuläre Abhängigkeit liblogging ↔ libfolders auflösen

**Problem:**
- liblogging nutzt optional libfolders (für LOG_DIR)
- libfolders nutzt liblogging (für log_*)

**Lösung:**
- liblogging sollte OHNE libfolders funktionieren (echo statt log falls LOG_DIR fehlt)
- libfolders sollte OHNE liblogging funktionieren (echo statt log_*)
- Beide Module sollten gegenseitig prüfen ob die Funktionen verfügbar sind

**Code-Beispiel libfolders.sh:**
```bash
# Statt:
log_info "Ordner erstellt: $folder"

# Besser:
if declare -f log_info >/dev/null 2>&1; then
    log_info "Ordner erstellt: $folder"
else
    echo "INFO: Ordner erstellt: $folder" >&2
fi
```

## ⚠️ Wichtige Hinweise

1. **liblogging**: Sollte früh geladen werden, da fast alle Module es nutzen
2. **libfolders**: Wird von vielen Modulen benötigt → muss NACH liblogging
3. **libintegrity**: Braucht config+logging+folders → muss nach allen dreien
4. **libcommon**: Kern-Funktionen für disc-Operationen → sollte vor optionalen Modulen

## 🎯 Empfehlung

**Option B** ist die beste Lösung:
- Verschiebe libfiles nach vorne (Position 2)
- Verschiebe libapi nach hinten (Position 5)
- Passe Prüfreihenfolge entsprechend an
- Beide Reihenfolgen sind dann identisch und logisch

**Zusätzlich:**
- Dokumentiere die Abhängigkeiten besser im Code
- Erwäge liblogging/libfolders robuster gegen fehlende Dependencies zu machen
