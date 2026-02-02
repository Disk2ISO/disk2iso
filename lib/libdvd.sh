#!/bin/bash
# ===========================================================================
# DVD Library
# ===========================================================================
# Filepath: lib/libdvd.sh
#
# Beschreibung:
#   Funktionen für DVD-Ripping und -Konvertierung
#   - copy_video_dvd() - Video-DVD Orchestrator mit Fehler-Tracking
#   - Intelligentes Fallback-System bei Fehlern
#   - Nutzt gemeinsame Worker aus libcommon.sh (ddrescue/dd)
#   - Integration mit TMDB Metadata-Abfrage
#
# ---------------------------------------------------------------------------
# Dependencies: liblogging, libfolders, libcommon (optional: libtmdb)
# ---------------------------------------------------------------------------
# Author: D.Götze
# Version: 1.2.1
# Last Change: 2026-01-26 20:00
# ===========================================================================

# ===========================================================================
# DEPENDENCY CHECK
# ===========================================================================
readonly MODULE_NAME_DVD="dvd"               # Globale Variable für Modulname
SUPPORT_DVD=false                                     # Globales Support Flag
INITIALIZED_DVD=false                       # Initialisierung war erfolgreich
ACTIVATED_DVD=false                              # In Konfiguration aktiviert

# ===========================================================================
# dvd_check_dependencies
# ---------------------------------------------------------------------------
# Funktion.: Prüfe alle Modul-Abhängigkeiten (Modul-Dateien, Ausgabe-Ordner, 
# .........  kritische und optionale Software für die Ausführung des Modul),
# .........  lädt nach erfolgreicher Prüfung die Sprachdatei für das Modul.
# Parameter: keine
# Rückgabe.: 0 = Verfügbar (Module nutzbar)
# .........  1 = Nicht verfügbar (Modul deaktiviert)
# Extras...: Setzt SUPPORT_DVD=true bei erfolgreicher Prüfung
# ===========================================================================
dvd_check_dependencies() {
    log_debug "$MSG_DEBUG_DVD_CHECK_START"

    #-- Alle Modul Abhängigkeiten prüfen -------------------------------------
    check_module_dependencies "$MODULE_NAME_DVD" || return 1

    #-- Lade Modul-Konfiguration --------------------------------------------
    load_config_dvd || return 1

    #-- Setze Verfügbarkeit -------------------------------------------------
    SUPPORT_DVD=true
    log_debug "$MSG_DEBUG_DVD_CHECK_COMPLETE"
    
    #-- Abhängigkeiten erfüllt ----------------------------------------------
    log_info "$MSG_VIDEO_SUPPORT_AVAILABLE"
    return 0
}

# ===========================================================================
# load_config_dvd
# ---------------------------------------------------------------------------
# Funktion.: Lade DVD-Modul Konfiguration und setze Initialisierung
# Parameter: keine
# Rückgabe.: 0 = Erfolgreich geladen
# Setzt....: INITIALIZED_DVD=true, ACTIVATED_DVD=true
# Hinweis..: DVD-Modul hat keine API-Config, daher nur Flags setzen
# .........  Modul ist immer aktiviert wenn Support vorhanden
# ===========================================================================
load_config_dvd() {
    # DVD-Video ist immer aktiviert wenn Support verfügbar (keine Runtime-Deaktivierung)
    ACTIVATED_DVD=true
    
    # Setze Initialisierungs-Flag
    INITIALIZED_DVD=true
    
    log_info "DVD-Video: Konfiguration geladen"
    return 0
}

# ===========================================================================
# is_dvd_ready
# ---------------------------------------------------------------------------
# Funktion.: Prüfe ob DVD-Modul supported wird, initialisiert wurde und
# .........  aktiviert ist. Wenn true ist alles bereit für die Nutzung.
# Parameter: keine
# Rückgabe.: 0 = Bereit, 1 = Nicht bereit
# ===========================================================================
is_dvd_ready() {
    [[ "$SUPPORT_DVD" == "true" ]] && \
    [[ "$INITIALIZED_DVD" == "true" ]] && \
    [[ "$ACTIVATED_DVD" == "true" ]]
}

# ============================================================================
# PATH CONSTANTS
# ============================================================================

# ===========================================================================
# get_path_dvd
# ---------------------------------------------------------------------------
# Funktion.: Liefert den Ausgabepfad des Modul für die Verwendung in anderen
# .........  abhängigen Modulen
# Parameter: keine
# Rückgabe.: Vollständiger Pfad zum Modul Verzeichnis
# Hinweis: Ordner wird bereits in check_module_dependencies() erstellt
# ===========================================================================
get_path_dvd() {
    echo "${OUTPUT_DIR}/${MODULE_NAME_DVD}"
}

# TODO: Ab hier ist das Modul noch nicht fertig implementiert!

# ============================================================================
# VIDEO DVD COPY - DVDBACKUP + GENISOIMAGE (Methode 1 - Schnellste)
# ============================================================================

# Funktion zum Kopieren von Video-DVDs mit Entschlüsselung
# Nutzt dvdbackup (mit libdvdcss) + genisoimage
# Mit intelligentem Fallback: dvdbackup → ddrescue → Ablehnung
copy_video_dvd() {
    # Initialisiere Kopiervorgang-Log
    init_copy_log "$(discinfo_get_label)" "dvd"
    
    # Nutze zentrale Fehler-Tracking Funktionen aus libcommon.sh
    local failure_count=$(common_get_disc_failure_count)
    
    # ========================================================================
    # TMDB METADATA BEFORE COPY (wenn verfügbar)
    # ========================================================================
    
    local skip_tmdb=false
    local disc_id=$(get_disc_identifier)  # Zentrale Funktion aus libcommon.sh
    
    # Prüfe ob TMDB BEFORE Copy verfügbar ist
    if declare -f query_tmdb_before_copy >/dev/null 2>&1; then
        # Extrahiere Filmtitel aus disc_label
        local movie_title
        if declare -f extract_movie_title_from_label >/dev/null 2>&1; then
            movie_title=$(extract_movie_title_from_label "$(discinfo_get_label)")
        else
            # Fallback: Einfache Konvertierung
            movie_title=$(echo "$(discinfo_get_label)" | tr '_' ' ' | sed 's/\b\(.)/ \u\1/g')
        fi
        
        log_info "TMDB: Suche nach '$movie_title'..."
        
        # Query TMDB
        if query_tmdb_before_copy "$movie_title" "$(discinfo_get_type)" "$disc_id"; then
            # TMDB Query erfolgreich - warte auf User-Auswahl
            log_info "TMDB: Warte auf User-Auswahl..."
            
            # Hole TMDB Response (aus .tmdbquery Datei)
            local output_base
            output_base=$(get_path_dvd)
            local tmdbquery_file="${output_base}/${dvd_id}_tmdb.tmdbquery"
            
            if [[ -f "$tmdbquery_file" ]]; then
                local tmdb_json
                tmdb_json=$(cat "$tmdbquery_file")
                
                # Warte auf Auswahl
                if declare -f wait_for_tmdb_selection >/dev/null 2>&1; then
                    if wait_for_tmdb_selection "$disc_id" "$tmdb_json"; then
                        # User hat ausgewählt - disc_label wurde aktualisiert
                        log_info "TMDB: Metadata-Auswahl erfolgreich - neues Label: $(discinfo_get_label)"
                        
                        # Re-initialisiere Log mit neuem Label
                        init_copy_log "$(discinfo_get_label)" "dvd"
                    else
                        log_info "TMDB: Metadata übersprungen - verwende generisches Label"
                        skip_tmdb=true
                    fi
                else
                    log_warning "TMDB: wait_for_tmdb_selection() nicht verfügbar"
                    skip_tmdb=true
                fi
            else
                log_warning "TMDB: Query-Datei nicht gefunden"
                skip_tmdb=true
            fi
        else
            log_info "TMDB: Keine Treffer oder Abfrage fehlgeschlagen"
            skip_tmdb=true
        fi
    else
        log_info "TMDB: BEFORE Copy nicht verfügbar - verwende generisches Label"
        skip_tmdb=true
    fi
    
    # ========================================================================
    # DVD COPY WORKFLOW
    # ========================================================================
    
    # Prüfe Fehler-Historie
    if [[ $failure_count -ge 2 ]]; then
        # DVD ist bereits 2x fehlgeschlagen → Ablehnung
        log_error "$MSG_ERROR_DVD_REJECTED"
        log_error "$MSG_ERROR_DVD_REJECTED_HINT"
        finish_copy_log
        return 1
    elif [[ $failure_count -eq 1 ]]; then
        # DVD ist bereits 1x fehlgeschlagen → Automatischer Fallback auf ddrescue
        log_warning "$MSG_WARNING_DVD_FAILED_BEFORE"
        log_copying "$MSG_FALLBACK_TO_DDRESCUE"
        
        # Setze Kopiermethode für ddrescue-Versuch
        discinfo_set_copy_method "ddrescue"
        
        # Nutze gemeinsamen Worker aus libcommon.sh
        if common_copy_data_disc_ddrescue; then
            # Erfolg → Erstelle DVD-Metadaten und lösche Fehler-Historie
            if declare -f create_dvd_archive_metadata >/dev/null 2>&1; then
                local movie_title=$(extract_movie_title "$(discinfo_get_label)")
                create_dvd_archive_metadata "$movie_title" "dvd-video" || true
            fi
            common_clear_disc_failures
            return 0
        else
            # Fehler → Registriere zweiten Fehlschlag
            common_register_disc_failure
            return 1
        fi
    fi
    
    # Erste Versuch: Normale dvdbackup-Methode
    log_copying "$MSG_METHOD_DVDBACKUP"
    
    # Setze Kopiermethode
    discinfo_set_copy_method "dvdbackup"
    
    # Erstelle temporäres Verzeichnis für DVD-Struktur (unter temp_pathname)
    # dvdbackup erstellt automatisch Unterordner, daher nutzen wir temp_pathname direkt
    local temp_dvd="$temp_pathname"
    
    # Ermittle DVD-Größe für Fortschrittsanzeige
    local dvd_size_mb=0
    get_disc_size
    if [[ $total_bytes -gt 0 ]]; then
        dvd_size_mb=$((total_bytes / 1024 / 1024))
        log_copying "$MSG_DVD_SIZE: ${dvd_size_mb} $MSG_PROGRESS_MB"
    fi
    
    # Prüfe Speicherplatz (Overhead wird automatisch berechnet)
    if [[ $dvd_size_mb -gt 0 ]]; then
        if ! check_disk_space "$dvd_size_mb"; then
            return 1
        fi
    fi
    
    # Starte dvdbackup im Hintergrund mit Fortschrittsanzeige
    # -M = Mirror (komplette DVD), -n = Name override (direkt VIDEO_TS)
    log_copying "$MSG_EXTRACT_DVD_STRUCTURE"
    dvdbackup -M -n "dvd" -i "$CD_DEVICE" -o "$temp_dvd" >>"$copy_log_filename" 2>&1 &
    local dvdbackup_pid=$!
    
    # Überwache Fortschritt (alle 60 Sekunden)
    local start_time=$(date +%s)
    local last_log_time=$start_time
    
    while kill -0 "$dvdbackup_pid" 2>/dev/null; do
        sleep 5
        
        local current_time=$(date +%s)
        local elapsed=$((current_time - last_log_time))
        
        # Log alle 60 Sekunden
        if [[ $elapsed -ge 60 ]]; then
            local copied_mb=0
            if [[ -d "$temp_dvd" ]]; then
                copied_mb=$(du -sm "$temp_dvd" 2>/dev/null | awk '{print $1}')
                # Fallback wenn du fehlschlägt oder leer
                copied_mb=${copied_mb:-0}
            fi
            
            # Konvertiere MB zu Bytes für zentrale Funktion (mit Validierung)
            local current_bytes=0
            local total_bytes=0
            if [[ "$copied_mb" =~ ^[0-9]+$ ]]; then
                current_bytes=$((copied_mb * 1024 * 1024))
            fi
            if [[ "$dvd_size_mb" =~ ^[0-9]+$ ]] && [[ $dvd_size_mb -gt 0 ]]; then
                total_bytes=$((dvd_size_mb * 1024 * 1024))
            fi
            
            # Nutze zentrale Fortschrittsberechnung
            common_calculate_and_log_progress "$current_bytes" "$total_bytes" "$start_time" "DVD"
            
            last_log_time=$current_time
        fi
    done
    
    # Warte auf dvdbackup Prozess-Ende
    wait "$dvdbackup_pid"
    local dvdbackup_exit=$?
    
    # Prüfe Ergebnis
    if [[ $dvdbackup_exit -ne 0 ]]; then
        log_error "$MSG_ERROR_DVDBACKUP_FAILED (Exit-Code: $dvdbackup_exit)"
        
        # Registriere Fehlschlag für automatischen Fallback (zentrale Funktion)
        common_register_disc_failure
        log_warning "$MSG_DVD_MARKED_FOR_RETRY"
        
        rm -rf "$temp_dvd"
        finish_copy_log
        return 1
    fi
    
    log_copying "$MSG_DVD_STRUCTURE_EXTRACTED"
    
    # VIDEO_TS ist jetzt direkt unter temp_dvd/dvd/VIDEO_TS
    local video_ts_dir="${temp_dvd}/dvd/VIDEO_TS"
    
    if [[ ! -d "$video_ts_dir" ]]; then
        log_error "$MSG_ERROR_NO_VIDEO_TS"
        finish_copy_log
        return 1
    fi
    
    # Erstelle ISO aus VIDEO_TS Struktur
    log_copying "$MSG_CREATE_DECRYPTED_ISO"
    
    # Setze Kopiermethode für ISO-Erstellung
    discinfo_set_copy_method "genisoimage"
    
    if genisoimage -dvd-video -V "$(discinfo_get_label)" -o "$iso_filename" "$(dirname "$video_ts_dir")" 2>>"$copy_log_filename"; then
        log_copying "$MSG_DECRYPTED_DVD_SUCCESS"
        
        # Erfolg → Lösche eventuelle Fehler-Historie (zentrale Funktion)
        common_clear_disc_failures
        
        # Erstelle Metadaten für Archiv-Ansicht
        if declare -f create_dvd_archive_metadata >/dev/null 2>&1; then
            local movie_title=$(extract_movie_title "$(discinfo_get_label)")
            create_dvd_archive_metadata "$movie_title" "dvd-video" || true
        fi
        
        rm -rf "$temp_dvd"
        finish_copy_log
        return 0
    else
        log_error "$MSG_ERROR_GENISOIMAGE_FAILED"
        
        # Registriere Fehlschlag (genisoimage-Fehler, zentrale Funktion)
        common_register_disc_failure
        
        rm -rf "$temp_dvd"
        finish_copy_log
        return 1
    fi
}

# ============================================================================
# VIDEO DVD COPY - DDRESCUE (Methode 2 - Mittelschnell)
# ============================================================================
# Hinweis: Ab v1.2.1 nutzt copy_video_dvd() die gemeinsamen Worker-Funktionen
#          aus libcommon.sh statt eigene copy_video_dvd_ddrescue():
#          - common_copy_data_disc_ddrescue() für ddrescue-Methode
#          - common_copy_data_disc_dd() für dd-Methode (falls benötigt)
#
# Orchestrator copy_video_dvd() wählt Methode basierend auf Fehler-Historie
# und ruft entsprechenden Worker auf. Metadaten-Erstellung erfolgt im
# Orchestrator nach erfolgreichem Worker-Aufruf.
# ============================================================================
