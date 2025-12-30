#!/bin/bash
################################################################################
# Logging Library
# Filepath: disk2iso-lib/lib-logging.sh
#
# Beschreibung:
#   Zentrale Logging-Funktionen für alle Module:
#   - Timestamped Logging mit optionaler Datei-Ausgabe
#   - Wird von allen Modulen verwendet
#
# Quellen:
#   - functions.sh (log_message)
#
# Konsolidiert: 13.12.2025
################################################################################

# ============================================================================
# PATH CONSTANTS
# ============================================================================

readonly LOG_DIR="log"

# ============================================================================
# PATH GETTER
# ============================================================================

# Funktion: Ermittle Pfad für Log-Dateien
# Rückgabe: Vollständiger Pfad zu log/
get_path_log() {
    echo "${OUTPUT_DIR}/${LOG_DIR}"
}

# ============================================================================
# LOGGING FUNCTIONS
# Quelle: functions.sh
# ============================================================================

# Funktion für Logging (verwendet aktuelles log_filename)
# Parameter: $1 = Nachricht zum Loggen
# Ausgabe: Konsole + Optional log_filename (falls gesetzt)
log_message() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message"
    if [[ -n "$log_filename" ]]; then
        echo "$message" >> "$log_filename"
    fi
}

# ============================================================================
# ENDE DER LOGGING LIBRARY
# ============================================================================
