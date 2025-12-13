#!/bin/bash
################################################################################
# Tool Detection Library
# Filepath: disk2iso-lib/lib-tools.sh
#
# Beschreibung:
#   Sammlung aller Funktionen zur Erkennung von verfügbaren Tools:
#   - ISO-Erstellungs-Tools (genisoimage, mkisofs)
#   - Kopierwerkzeuge (ddrescue, dd)
#   - Metadaten-Tools (cd-discid, cdrdao, curl, jq)
#   - Tag-Editor (eyeD3, mid3v2)
#   - Video-Tools (dvdbackup, makemkvcon)
#
# Quellen:
#   - functions.sh (get_mkisofs_command)
#
# Konsolidiert: 13.12.2025
################################################################################

# ============================================================================
# ISO CREATION TOOLS
# Quelle: functions.sh
# ============================================================================

# Funktion zur Ermittlung des verfügbaren ISO-Erstellungs-Tools
# Gibt genisoimage oder mkisofs zurück (Präferenz: genisoimage)
# Gibt leeren String zurück wenn keines verfügbar
#
# Rückgabe: "genisoimage", "mkisofs" oder ""
get_mkisofs_command() {
    if command -v genisoimage >/dev/null 2>&1; then
        echo "genisoimage"
    elif command -v mkisofs >/dev/null 2>&1; then
        echo "mkisofs"
    else
        echo ""
    fi
}

# ============================================================================
# COPY TOOLS
# ============================================================================

# Prüfe ob ddrescue verfügbar ist (bevorzugtes Kopierwerkzeug)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_ddrescue() {
    command -v ddrescue >/dev/null 2>&1
}

# Prüfe ob dd verfügbar ist (Fallback-Kopierwerkzeug)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_dd() {
    command -v dd >/dev/null 2>&1
}

# ============================================================================
# METADATA TOOLS
# ============================================================================

# Prüfe ob cd-discid verfügbar ist (für MusicBrainz Disc-ID)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_cd_discid() {
    command -v cd-discid >/dev/null 2>&1
}

# Prüfe ob cdrdao verfügbar ist (für CD-TEXT)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_cdrdao() {
    command -v cdrdao >/dev/null 2>&1
}

# Prüfe ob curl verfügbar ist (für API-Anfragen)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_curl() {
    command -v curl >/dev/null 2>&1
}

# Prüfe ob jq verfügbar ist (für JSON-Parsing)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_jq() {
    command -v jq >/dev/null 2>&1
}

# ============================================================================
# AUDIO TOOLS
# ============================================================================

# Prüfe ob cdparanoia verfügbar ist (für Audio-CD Ripping)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_cdparanoia() {
    command -v cdparanoia >/dev/null 2>&1
}

# Prüfe ob lame verfügbar ist (für MP3-Encoding)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_lame() {
    command -v lame >/dev/null 2>&1
}

# Prüfe ob eyeD3 verfügbar ist (für MP3-Tags, bevorzugt)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_eyed3() {
    command -v eyeD3 >/dev/null 2>&1
}

# Prüfe ob mid3v2 verfügbar ist (für MP3-Tags, Fallback)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_mid3v2() {
    command -v mid3v2 >/dev/null 2>&1
}

# ============================================================================
# VIDEO TOOLS
# ============================================================================

# Prüfe ob dvdbackup verfügbar ist (für DVD-Video)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_dvdbackup() {
    command -v dvdbackup >/dev/null 2>&1
}

# Prüfe ob makemkvcon verfügbar ist (für Blu-ray Video)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_makemkvcon() {
    command -v makemkvcon >/dev/null 2>&1
}

# ============================================================================
# DISC INFO TOOLS
# ============================================================================

# Prüfe ob isoinfo verfügbar ist (für ISO9660/UDF Informationen)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_isoinfo() {
    command -v isoinfo >/dev/null 2>&1
}

# Prüfe ob blockdev verfügbar ist (für Blockgerät-Informationen)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_blockdev() {
    command -v blockdev >/dev/null 2>&1
}

# Prüfe ob blkid verfügbar ist (für Dateisystem-Erkennung)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_blkid() {
    command -v blkid >/dev/null 2>&1
}

# ============================================================================
# PROGRESS TOOLS
# ============================================================================

# Prüfe ob pv verfügbar ist (für Fortschrittsanzeige)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_pv() {
    command -v pv >/dev/null 2>&1
}

# ============================================================================
# SYSTEM TOOLS
# ============================================================================

# Prüfe ob md5sum verfügbar ist (für Checksummen)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_md5sum() {
    command -v md5sum >/dev/null 2>&1
}

# Prüfe ob lsblk verfügbar ist (für Geräteinformationen)
# Rückgabe: 0 = verfügbar, 1 = nicht verfügbar
check_lsblk() {
    command -v lsblk >/dev/null 2>&1
}

# ============================================================================
# COMPREHENSIVE TOOL CHECKS
# ============================================================================

# Prüfe alle erforderlichen Tools für CD-ROM/DVD-ROM/BD-ROM Kopieren
# Rückgabe: 0 = alle erforderlich Tools vorhanden, 1 = mindestens ein Tool fehlt
check_required_data_tools() {
    local missing_tools=()
    
    check_blkid || missing_tools+=("blkid")
    check_isoinfo || missing_tools+=("isoinfo")
    
    # Mindestens ein Kopierwerkzeug erforderlich
    if ! check_ddrescue && ! check_dd; then
        missing_tools+=("ddrescue oder dd")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_message "FEHLER: Fehlende erforderliche Tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Prüfe alle erforderlichen Tools für Audio-CD Ripping
# Rückgabe: 0 = alle erforderlich Tools vorhanden, 1 = mindestens ein Tool fehlt
check_required_audio_tools() {
    local missing_tools=()
    
    check_cdparanoia || missing_tools+=("cdparanoia")
    check_lame || missing_tools+=("lame")
    
    # Mindestens ein Tag-Editor empfohlen (nicht zwingend erforderlich)
    if ! check_eyed3 && ! check_mid3v2; then
        log_message "WARNUNG: Kein MP3-Tag-Editor gefunden (eyeD3 oder mid3v2 empfohlen)"
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_message "FEHLER: Fehlende erforderliche Tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Prüfe alle erforderlichen Tools für DVD-Video Kopieren
# Rückgabe: 0 = alle erforderlich Tools vorhanden, 1 = mindestens ein Tool fehlt
check_required_dvd_video_tools() {
    local missing_tools=()
    
    check_dvdbackup || missing_tools+=("dvdbackup")
    
    # ISO-Erstellungs-Tool erforderlich
    if [[ -z "$(get_mkisofs_command)" ]]; then
        missing_tools+=("genisoimage oder mkisofs")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_message "FEHLER: Fehlende erforderliche Tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Prüfe alle erforderlichen Tools für Blu-ray Video Kopieren
# Rückgabe: 0 = alle erforderlich Tools vorhanden, 1 = mindestens ein Tool fehlt
check_required_bluray_video_tools() {
    local missing_tools=()
    
    check_makemkvcon || missing_tools+=("makemkvcon")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_message "FEHLER: Fehlende erforderliche Tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# ============================================================================
# STARTUP DEPENDENCY CHECKS
# ============================================================================

# Prüfe alle kritischen System-Tools (müssen für Basisbetrieb vorhanden sein)
# Rückgabe: Liste der fehlenden Tools als Array (leer wenn alle vorhanden)
check_all_critical_tools() {
    local missing=()
    
    check_dd || missing+=("dd")
    check_md5sum || missing+=("md5sum")
    check_lsblk || missing+=("lsblk")
    check_isoinfo || missing+=("isoinfo")
    
    # Ausgabe als Array für weitere Verarbeitung
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "${missing[@]}"
        return 1
    fi
    
    return 0
}

# Prüfe alle optionalen Tools (für erweiterte Funktionen)
# Rückgabe: Liste der fehlenden Tools als Array (leer wenn alle vorhanden)
check_all_optional_tools() {
    local missing=()
    
    # Kopierwerkzeuge
    check_ddrescue || missing+=("ddrescue")
    
    # Video-Tools
    check_dvdbackup || missing+=("dvdbackup")
    check_makemkvcon || missing+=("makemkvcon")
    
    # ISO-Erstellungs-Tools
    [[ -z "$(get_mkisofs_command)" ]] && missing+=("mkisofs/genisoimage")
    
    # Audio-Tools
    check_cdparanoia || missing+=("cdparanoia")
    check_lame || missing+=("lame")
    
    # Metadaten-Tools
    check_cd_discid || missing+=("cd-discid")
    check_curl || missing+=("curl")
    check_jq || missing+=("jq")
    check_cdrdao || missing+=("cdrdao")
    
    # Tag-Editor (mindestens einer sollte vorhanden sein)
    if ! check_eyed3 && ! check_mid3v2; then
        missing+=("eyeD3/mid3v2")
    fi
    
    # Fortschritts-Tools
    check_pv || missing+=("pv")
    
    # Ausgabe als Array für weitere Verarbeitung
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "${missing[@]}"
        return 1
    fi
    
    return 0
}

# ============================================================================
# ENDE DER TOOL DETECTION LIBRARY
# ============================================================================
