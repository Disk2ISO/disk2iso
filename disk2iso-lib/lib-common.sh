#!/bin/bash
################################################################################
# Common Functions Library - Minimal (nur Debian Standard-Tools)
# Filepath: disk2iso-lib/lib-common.sh
#
# Beschreibung:
#   Nur dd-basiertes Kopieren (Standard-Tool)
#   - copy_data_disc() - Daten-Disc kopieren mit dd
#   - reset_disc_variables, cleanup_disc_operation
#
# Vereinfacht: 24.12.2025
################################################################################

# ============================================================================
# DATA DISC COPY - NUR DD
# ============================================================================

# Funktion zum Kopieren von Daten-Discs (CD/DVD/BD) mit dd
# Nutzt nur Standard-Tools ohne isoinfo/blockdev
copy_data_disc() {
    # Standard Block-Size für optische Medien
    local block_size=2048
    
    # Kopiere mit dd (status=progress für Fortschritt)
    if dd if="$CD_DEVICE" of="$iso_filename" bs="$block_size" conv=noerror,sync status=progress 2>>"$log_filename"; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Funktion zum Zurücksetzen aller Disc-Variablen
reset_disc_variables() {
    disc_label=""
    disc_type=""
    iso_filename=""
    md5_filename=""
    log_filename=""
    iso_basename=""
    temp_pathname=""
}

# Funktion zum vollständigen Aufräumen nach Disc-Operation
cleanup_disc_operation() {
    local status="${1:-unknown}"
    
    # 1. Temp-Verzeichnis aufräumen (falls vorhanden)
    if [[ -n "$temp_pathname" ]] && [[ -d "$temp_pathname" ]]; then
        rm -rf "$temp_pathname"
    fi
    
    # 2. Unvollständige ISO-Datei löschen (nur bei Fehler)
    if [[ "$status" == "failure" ]] && [[ -n "$iso_filename" ]] && [[ -f "$iso_filename" ]]; then
        rm -f "$iso_filename"
    fi
    
    # 3. Disc auswerfen (immer)
    if [[ -b "$CD_DEVICE" ]]; then
        eject "$CD_DEVICE" 2>/dev/null
    fi
    
    # 4. Variablen zurücksetzen (immer)
    reset_disc_variables
}
