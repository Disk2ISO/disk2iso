#!/bin/bash
# =============================================================================
# Logging Library
# =============================================================================
# Filepath: lib/liblogging.sh
#
# Beschreibung:
#   Zentrale Logging-Funktionen für alle Module
#   - Timestamped Logging mit optionaler Datei-Ausgabe
#   - Modulares Sprachsystem (load_module_language)
#   - log_error(), log_info(), log_warning(), log_debug()
#   - Wird von allen anderen Modulen verwendet
#
# -----------------------------------------------------------------------------
# Dependencies: Keine (reine Console-Logging-Funktionen)
# -----------------------------------------------------------------------------
# Author: D.Götze
# Version: 1.2.1
# Last Change: 2026-01-26 20:00
# =============================================================================

# =============================================================================
# DEPENDENCY CHECK
# =============================================================================

# ===========================================================================
# logging_check_dependencies
# ---------------------------------------------------------------------------
# Funktion.: Prüfe alle Framework Abhängigkeiten (Modul-Dateien, die Modul
# .........  Ausgabe Ordner, kritische und optionale Software für die
# .........  Ausführung des Tool), lädt bei erfolgreicher Prüfung die
# .........  Sprachdatei für das Modul.
# Parameter: keine
# Rückgabe.: 0 = Verfügbar (Framework nutzbar)
# .........  1 = Nicht verfügbar (Framework deaktiviert)
# Extras...: Sollte so früh wie möglich nach dem Start geprüft werden, da
# .........  andere Module ggf. auf dieses Framework angewiesen sind. Am
# .........  besten direkt im Hauptskript (disk2iso) nach dem
# .........  Laden der libcommon.sh.
# ===========================================================================
logging_check_dependencies() {
    # Lade Sprachdatei für dieses Modul
    load_module_language "logging"
    
    # Logging-Modul benötigt keine externen Tools
    # Verwendet nur Bash-Funktionen (echo, printf, date)
    # Log-Verzeichnisse werden von anderen Modulen erstellt (libfiles, etc.)
    
    return 0
}

# ============================================================================
# LANGUAGE SYSTEM
# ============================================================================

# ============================================================================
# LANGUAGE FALLBACK MESSAGES (Hardcoded - loaded before language files)
# ============================================================================

# Diese Meldungen müssen hardcoded sein, da sie vor dem Laden der Sprachdateien
# verwendet werden können und das Sprachsystem selbst betreffen
readonly MSG_LANG_FILE_LOADED="Sprachdatei geladen:"
readonly MSG_LANG_FALLBACK_LOADED="Fallback: Sprachdatei geladen:"
readonly MSG_WARNING_NO_LANG_FILE="WARNUNG: Keine Sprachdatei gefunden für:"

# ============================================================================
# LANGUAGE FILE LOADING
# ============================================================================

# Funktion: Lade modul-spezifische Sprachdatei
# Parameter: $1 = Modul-Name (z.B. "common", "cd", "dvd", "bluray")
# Lädt: lang/lib[modul].[LANGUAGE]
# Beispiel: load_module_language "cd" lädt lang/libcd.de
load_module_language() {
    local module_name="$1"
    
    # Für Hauptskript (disk2iso) ohne lib Präfix suchen
    # Für Module mit lib Präfix suchen
    local lang_file
    if [[ -f "${SCRIPT_DIR}/lang/${module_name}.${LANGUAGE}" ]]; then
        lang_file="${SCRIPT_DIR}/lang/${module_name}.${LANGUAGE}"
    else
        lang_file="${SCRIPT_DIR}/lang/lib${module_name}.${LANGUAGE}"
    fi
    
    if [[ -f "$lang_file" ]]; then
        source "$lang_file"
        # Optional: Log-Nachricht nur wenn log_message bereits definiert
        if declare -f log_message >/dev/null 2>&1; then
            log_info "$MSG_LANG_FILE_LOADED $(basename "$lang_file")" >&2
        fi
    else
        # Fallback auf Englisch
        local fallback_file
        if [[ -f "${SCRIPT_DIR}/lang/${module_name}.en" ]]; then
            fallback_file="${SCRIPT_DIR}/lang/${module_name}.en"
        else
            fallback_file="${SCRIPT_DIR}/lang/lib${module_name}.en"
        fi
        
        if [[ -f "$fallback_file" ]]; then
            source "$fallback_file"
            if declare -f log_message >/dev/null 2>&1; then
                log_info "$MSG_LANG_FALLBACK_LOADED $(basename "$fallback_file")" >&2
            fi
        else
            # Keine Sprachdatei gefunden - Module funktionieren trotzdem
            if declare -f log_message >/dev/null 2>&1; then
                log_warning "$MSG_WARNING_NO_LANG_FILE ${module_name}.${LANGUAGE}" >&2
            fi
        fi
    fi
}

# Lade Debug-Messages (immer Englisch - Entwicklersprache)
# Diese werden nur benötigt wenn DEBUG=1 gesetzt ist
if [[ "${DEBUG:-0}" == "1" ]] || [[ "${VERBOSE:-0}" == "1" ]]; then
    DEBUG_LANG_FILE="${SCRIPT_DIR}/../lang/debugmsg.en"
    if [[ -f "$DEBUG_LANG_FILE" ]]; then
        source "$DEBUG_LANG_FILE"
    fi
fi

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Funktion für allgemeines Logging (Service/System)
# Parameter: $1 = Nachricht zum Loggen
# Ausgabe: Konsole (kein File-Logging für Service-Messages)
log_message() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message"
}

# Funktion für Info-Logging (alias für log_message)
# Parameter: $1 = Info-Nachricht
log_info() {
    log_message "ℹ️  $1"
}

# Funktion für Warning-Logging
# Parameter: $1 = Warning-Nachricht
# Ausgabe: Konsole + stderr
log_warning() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - ⚠️  WARNING: $1"
    echo "$message" >&2
}

# Funktion für Error-Logging
# Parameter: $1 = Error-Nachricht
# Ausgabe: Konsole + stderr
log_error() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - ❌ ERROR: $1"
    echo "$message" >&2
}

# Funktion für Debug-Logging
# Parameter: $1 = Debug-Nachricht
# Ausgabe: Nur wenn DEBUG=1 gesetzt ist
log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        local message="$(date '+%Y-%m-%d %H:%M:%S') - 🐛 DEBUG: $1"
        echo "$message" >&2
    fi
}

# ============================================================================
# ENDE DER LOGGING LIBRARY
# ============================================================================
