#!/bin/bash
################################################################################
# Common Functions Library
# Filepath: disk2iso-lib/lib-common.sh
#
# Beschreibung:
#   Gemeinsame Funktionen für alle Medientypen:
#   - Kopierfunktionen: ddrescue (bevorzugt), dd (Fallback)
#   - Utility-Funktionen: reset_disc_variables, cleanup_disc_operation
#   - copy_data_disc() - Wrapper für Daten-Discs (CD/DVD/BD-ROM)
#
# Quellen:
#   - copy/shared.sh (copy_with_ddrescue, copy_with_dd)
#   - copy/data.sh (copy_data_disc)
#   - functions.sh (reset_disc_variables, cleanup_disc_operation)
#
# Konsolidiert: 13.12.2025
################################################################################

# ============================================================================
# SHARED COPY FUNCTIONS
# Quelle: copy/shared.sh
# ============================================================================

# Funktion zum Kopieren mit ddrescue
# Robuste dd-Alternative mit Fehlerbehandlung
copy_with_ddrescue() {
    log_message "Verwende ddrescue für robustes Kopieren..."
    
    # Logfile ins Temp-Verzeichnis
    local logfile="${temp_pathname}/ddrescue.log"
    
    # Ermittle Block Size
    read block_size volume_size < <(get_disc_block_info)
    
    # Interaktiver Modus mit pv, falls verfügbar
    if [[ -t 0 ]] && command -v pv >/dev/null 2>&1; then
        local disc_size=$(get_disc_size)
        if ddrescue -n -b "$block_size" "$CD_DEVICE" - "$logfile" 2>>"$log_filename" | pv -s "$disc_size" | dd of="$iso_filename" bs="$block_size" 2>>"$log_filename"; then
            log_message "ddrescue erfolgreich abgeschlossen"
            return 0
        else
            log_message "ddrescue fehlgeschlagen"
            return 1
        fi
    else
        # Service-Modus oder pv nicht verfügbar
        if ddrescue -n -b "$block_size" "$CD_DEVICE" "$iso_filename" "$logfile" 2>>"$log_filename"; then
            log_message "ddrescue erfolgreich abgeschlossen"
            return 0
        else
            log_message "ddrescue fehlgeschlagen"
            return 1
        fi
    fi
}

# Funktion zum Kopieren mit dd (Fallback)
# Nutzt isoinfo für präzise Block Size und Volume Size
copy_with_dd() {
    log_message "Verwende dd als Fallback..."
    
    # Ermittle präzise Block Size und Volume Size
    read block_size volume_size < <(get_disc_block_info)
    
    # Berechne Gesamtgröße für pv
    local total_size=$((block_size * volume_size))
    
    # Interaktiver Modus mit pv, falls verfügbar
    if [[ -t 0 ]] && command -v pv >/dev/null 2>&1; then
        if [[ $volume_size -gt 0 ]]; then
            # Mit count für präzises Kopieren
            if dd if="$CD_DEVICE" bs="$block_size" count="$volume_size" 2>>"$log_filename" | pv -s "$total_size" | dd of="$iso_filename" bs="$block_size" 2>>"$log_filename"; then
                log_message "dd erfolgreich abgeschlossen (präzise Methode)"
                return 0
            else
                log_message "dd fehlgeschlagen"
                return 1
            fi
        else
            # Fallback ohne count
            local disc_size=$(get_disc_size)
            if dd if="$CD_DEVICE" bs="$block_size" 2>>"$log_filename" | pv -s "$disc_size" | dd of="$iso_filename" bs="$block_size" 2>>"$log_filename"; then
                log_message "dd erfolgreich abgeschlossen (Fallback-Methode)"
                return 0
            else
                log_message "dd fehlgeschlagen"
                return 1
            fi
        fi
    else
        # Service-Modus oder pv nicht verfügbar
        if [[ $volume_size -gt 0 ]]; then
            # Mit count für präzises Kopieren (ohne conv=noerror,sync für saubere Daten)
            if dd if="$CD_DEVICE" of="$iso_filename" bs="$block_size" count="$volume_size" status=progress 2>>"$log_filename"; then
                log_message "dd erfolgreich abgeschlossen (präzise Methode)"
                return 0
            else
                log_message "dd fehlgeschlagen"
                return 1
            fi
        else
            # Fallback: Standard-Methode mit conv=noerror,sync
            if dd if="$CD_DEVICE" of="$iso_filename" bs="$block_size" conv=noerror,sync status=progress 2>>"$log_filename"; then
                log_message "dd erfolgreich abgeschlossen (Fallback-Methode mit conv=noerror)"
                return 0
            else
                log_message "dd fehlgeschlagen"
                return 1
            fi
        fi
    fi
}

# ============================================================================
# DATA DISC COPY
# Quelle: copy/data.sh
# ============================================================================

# Funktion zum Kopieren von Daten-Discs (CD/DVD/BD)
# Wählt automatisch beste Methode: ddrescue > dd
copy_data_disc() {
    log_message "Kopiere Daten-Disc..."
    
    local copy_success=false
    
    # Strategie 1: Versuche ddrescue (robuster als dd)
    if command -v ddrescue >/dev/null 2>&1; then
        if copy_with_ddrescue; then
            copy_success=true
        fi
    fi
    
    # Strategie 2: Fallback auf dd
    if [[ "$copy_success" == false ]]; then
        if copy_with_dd; then
            copy_success=true
        fi
    fi
    
    if [[ "$copy_success" == true ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# Quelle: functions.sh
# ============================================================================

# Funktion zum Zurücksetzen aller Disc-Variablen
# Wird nach jedem Kopiervorgang aufgerufen
reset_disc_variables() {
    disc_label=""
    disc_type=""
    disc_block_size=""
    disc_volume_size=""
    iso_filename=""
    md5_filename=""
    log_filename=""
    iso_basename=""
    temp_pathname=""
}

# Funktion zum vollständigen Aufräumen nach Disc-Operation
# Parameter: $1 = success|failure|interrupted (optional, für Logging)
cleanup_disc_operation() {
    local status="${1:-unknown}"
    
    # 1. Temp-Verzeichnis aufräumen (falls vorhanden)
    if [[ -n "$temp_pathname" ]] && [[ -d "$temp_pathname" ]]; then
        rm -rf "$temp_pathname"
        log_message "Temp-Verzeichnis bereinigt: $temp_pathname"
    fi
    
    # 2. Unvollständige ISO-Datei löschen (nur bei Fehler)
    if [[ "$status" == "failure" ]] && [[ -n "$iso_filename" ]] && [[ -f "$iso_filename" ]]; then
        rm -f "$iso_filename"
        log_message "Unvollständige ISO-Datei gelöscht: $iso_filename"
    fi
    
    # 3. Disc auswerfen (immer)
    if [[ -b "$CD_DEVICE" ]]; then
        eject "$CD_DEVICE" 2>/dev/null
        log_message "Disc ausgeworfen"
    fi
    
    # 4. Variablen zurücksetzen (immer)
    reset_disc_variables
}

# ============================================================================
# ENDE DER COMMON COPY FUNCTIONS LIBRARY
# ============================================================================
