#!/bin/bash
################################################################################
# disk2iso v1.2.0 - Configuration Management Library
# Filepath: lib/lib-config.sh
#
# Beschreibung:
#   Standalone Config-Management ohne Dependencies für Web-API
#   - update_config_value() - Schreibe einzelnen Wert in config.sh
#   - get_all_config_values() - Lese alle Werte als JSON
#
# Version: 1.2.0
# Datum: 14.01.2026
################################################################################

# ============================================================================
# GLOBALE LAUFZEIT-VARIABLEN
# ============================================================================
# Diese Variablen werden zur Laufzeit gesetzt und sollten NICHT manuell
# in disk2iso.conf geändert werden.

OUTPUT_DIR=""      # Ausgabeordner für ISO-Dateien (wird per Parameter oder DEFAULT gesetzt)
disc_label=""      # Normalisierter Label-Name der Disc
iso_filename=""    # Vollständiger Pfad zur ISO-Datei
md5_filename=""    # Vollständiger Pfad zur MD5-Datei
log_filename=""    # Vollständiger Pfad zur Log-Datei
iso_basename=""    # Basis-Dateiname ohne Pfad (z.B. "dvd_video.iso")
temp_pathname=""   # Temp-Verzeichnis für aktuellen Kopiervorgang
disc_type=""       # "data" (vereinfacht)
disc_block_size="" # Block Size des Mediums (wird gecacht)
disc_volume_size="" # Volume Size des Mediums in Blöcken (wird gecacht)

# ============================================================================
# CONFIG MANAGEMENT FUNKTIONEN
# ============================================================================

# Funktion: Aktualisiere einzelnen Config-Wert in config.sh
# Parameter: $1 = Key (z.B. "DEFAULT_OUTPUT_DIR")
#            $2 = Value (z.B. "/media/iso")
#            $3 = Quote-Mode ("quoted" oder "unquoted", default: auto-detect)
# Rückgabe: JSON mit {"success": true} oder {"success": false, "message": "..."}
update_config_value() {
    local key="$1"
    local value="$2"
    local quote_mode="${3:-auto}"
    local config_file="${INSTALL_DIR:-/opt/disk2iso}/conf/disk2iso.conf"
    
    if [[ -z "$key" ]]; then
        echo '{"success": false, "message": "Key erforderlich"}'
        return 1
    fi
    
    if [[ ! -f "$config_file" ]]; then
        echo '{"success": false, "message": "config.sh nicht gefunden"}'
        return 1
    fi
    
    # Auto-detect quote mode basierend auf aktuellem Wert
    if [[ "$quote_mode" == "auto" ]]; then
        local current_line=$(grep "^${key}=" "$config_file" | head -1)
        if [[ "$current_line" =~ =\".*\" ]]; then
            quote_mode="quoted"
        else
            quote_mode="unquoted"
        fi
    fi
    
    # Erstelle neue Zeile
    local new_line
    if [[ "$quote_mode" == "quoted" ]]; then
        new_line="${key}=\"${value}\""
    else
        new_line="${key}=${value}"
    fi
    
    # Aktualisiere mit sed (in-place)
    if /usr/bin/sed -i "s|^${key}=.*|${new_line}|" "$config_file" 2>/dev/null; then
        echo '{"success": true}'
        return 0
    else
        echo '{"success": false, "message": "Schreibfehler"}'
        return 1
    fi
}

# Funktion: Lese alle Config-Werte als JSON
# Rückgabe: JSON mit allen Konfigurations-Werten
get_all_config_values() {
    local config_file="${INSTALL_DIR:-/opt/disk2iso}/conf/disk2iso.conf"
    
    if [[ ! -f "$config_file" ]]; then
        echo '{"success": false, "message": "config.sh nicht gefunden"}'
        return 1
    fi
    
    # Extrahiere relevante Werte mit awk (entferne Kommentare)
    local values=$(/usr/bin/awk -F'=' '
        /^DEFAULT_OUTPUT_DIR=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t"]+|[ \t"]+$/, "", $2)
            print "\"output_dir\": \"" $2 "\"," 
        }
        /^MP3_QUALITY=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print "\"mp3_quality\": " $2 "," 
        }
        /^DDRESCUE_RETRIES=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print "\"ddrescue_retries\": " $2 "," 
        }
        /^USB_DRIVE_DETECTION_ATTEMPTS=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print "\"usb_detection_attempts\": " $2 "," 
        }
        /^USB_DRIVE_DETECTION_DELAY=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print "\"usb_detection_delay\": " $2 "," 
        }
        /^MQTT_ENABLED=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print "\"mqtt_enabled\": " ($2 == "true" ? "true" : "false") "," 
        }
        /^MQTT_BROKER=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t"]+|[ \t"]+$/, "", $2)
            print "\"mqtt_broker\": \"" $2 "\"," 
        }
        /^MQTT_PORT=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print "\"mqtt_port\": " $2 "," 
        }
        /^MQTT_USER=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t"]+|[ \t"]+$/, "", $2)
            print "\"mqtt_user\": \"" $2 "\"," 
        }
        /^MQTT_PASSWORD=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t"]+|[ \t"]+$/, "", $2)
            print "\"mqtt_password\": \"" $2 "\"," 
        }
        /^TMDB_API_KEY=/ { 
            gsub(/#.*/, "", $2)
            gsub(/^[ \t"]+|[ \t"]+$/, "", $2)
            print "\"tmdb_api_key\": \"" $2 "\"," 
        }
    ' "$config_file")
    
    # Entferne letztes Komma
    local output=$(echo "$values" | /usr/bin/sed '$ s/,$//')
    
    # Ausgabe nur zu stdout (kein logging)
    echo "{\"success\": true, ${output}}"
    return 0
}
