#!/bin/bash
# =============================================================================
# System Information Library
# =============================================================================
# Filepath: lib/libsysteminfo.sh
#
# Beschreibung:
#   System-Informationen und Container-Erkennung
#   - Container-Erkennung (LXC, Docker, Podman)
#   - Speicherplatz-Prüfung (check_disk_space)
#   - Medium-Wechsel-Erkennung für Container-Umgebungen
#   - System-Monitoring und Ressourcen-Überwachung
#
# -----------------------------------------------------------------------------
# Dependencies: liblogging (für log_* Funktionen)
# -----------------------------------------------------------------------------
# Author: D.Götze
# Version: 1.2.1
# Last Change: 2026-01-26 20:00
# =============================================================================

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

# ===========================================================================
# check_dependencies_systeminfo
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
check_dependencies_systeminfo() {
    # Lade Sprachdatei für dieses Modul
    load_module_language "systeminfo"
    
    local missing=()
    
    # Basis-Tools für Systeminformationen
    command -v df >/dev/null 2>&1 || missing+=("df")
    command -v blkid >/dev/null 2>&1 || missing+=("blkid")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "$MSG_ERROR_SYSTEM_TOOLS_MISSING ${missing[*]}"
        log_info "$MSG_INSTALLATION_SYSTEM_TOOLS"
        return 1
    fi
    
    # Erkenne Container-Umgebung (setzt IS_CONTAINER und CONTAINER_TYPE)
    detect_container_environment
    
    return 0
}

# TODO: Ab hier ist das Modul noch nicht fertig implementiert!

# ============================================================================
# CONTAINER DETECTION
# ============================================================================
# Globale Variablen für Container-Erkennung
IS_CONTAINER=false
CONTAINER_TYPE=""

# Funktion: Erkenne Container-Umgebung
# Setzt globale Variablen: IS_CONTAINER, CONTAINER_TYPE
detect_container_environment() {
    IS_CONTAINER=false
    CONTAINER_TYPE=""
    
    # Methode 1: Prüfe /proc/1/environ auf container=
    if [[ -f /proc/1/environ ]]; then
        local env_content=$(tr '\0' '\n' < /proc/1/environ 2>/dev/null)
        
        if echo "$env_content" | grep -q "^container=lxc$"; then
            IS_CONTAINER=true
            CONTAINER_TYPE="lxc"
            log_info "$MSG_CONTAINER_DETECTED LXC"
            return 0
        elif echo "$env_content" | grep -q "^container=docker$"; then
            IS_CONTAINER=true
            CONTAINER_TYPE="docker"
            log_info "$MSG_CONTAINER_DETECTED Docker"
            return 0
        elif echo "$env_content" | grep -q "^container=podman$"; then
            IS_CONTAINER=true
            CONTAINER_TYPE="podman"
            log_info "$MSG_CONTAINER_DETECTED Podman"
            return 0
        fi
    fi
    
    # Methode 2: Prüfe auf Docker-spezifische Dateien
    if [[ -f /.dockerenv ]]; then
        IS_CONTAINER=true
        CONTAINER_TYPE="docker"
        log_info "$MSG_CONTAINER_DETECTED Docker"
        return 0
    fi
    
    # Methode 3: Prüfe /proc/1/cgroup
    if [[ -f /proc/1/cgroup ]]; then
        if grep -q ":/lxc/" /proc/1/cgroup 2>/dev/null; then
            IS_CONTAINER=true
            CONTAINER_TYPE="lxc"
            log_info "$MSG_CONTAINER_DETECTED LXC"
            return 0
        elif grep -q ":/docker/" /proc/1/cgroup 2>/dev/null; then
            IS_CONTAINER=true
            CONTAINER_TYPE="docker"
            log_info "$MSG_CONTAINER_DETECTED Docker"
            return 0
        fi
    fi
    
    # Keine Container-Umgebung erkannt
    log_info "$MSG_NATIVE_ENVIRONMENT_DETECTED"
    return 0
}

# ============================================================================
# DISK SPACE CHECK
# ============================================================================

# Funktion zur Prüfung des verfügbaren Speicherplatzes
# Parameter: $1 = benötigte Größe in MB
# Rückgabe: 0 = genug Platz, 1 = zu wenig Platz
# ===========================================================================
# check_disk_space
# ---------------------------------------------------------------------------
# Funktion.: Prüfe verfügbaren Speicherplatz
# Parameter: $1 = required_mb (benötigte MB - INKL. Overhead!)
#            HINWEIS: init_disc_info() berechnet bereits estimated_size_mb
#                     mit 10% Overhead. Diese Funktion prüft nur noch ob
#                     genug Platz vorhanden ist.
# Rückgabe.: 0 = Ausreichend Platz, 1 = Nicht genug Platz
# ===========================================================================
check_disk_space() {
    local required_mb=$1
    
    # Validierung
    if [[ -z "$required_mb" ]] || [[ ! "$required_mb" =~ ^[0-9]+$ ]]; then
        log_warning "check_disk_space: Ungültige required_mb '$required_mb' - überspringe Prüfung"
        return 0
    fi
    
    # Ermittle verfügbaren Speicherplatz am Ausgabepfad
    local available_mb=$(df -BM "$OUTPUT_DIR" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/M//')
    
    if [[ -z "$available_mb" ]] || [[ ! "$available_mb" =~ ^[0-9]+$ ]]; then
        log_error "$MSG_WARNING_DISK_SPACE_CHECK_FAILED"
        return 0  # Fahre fort, wenn Prüfung fehlschlägt
    fi
    
    # Detailliertes Logging
    log_info "Speicherplatz: ${available_mb} MB verfügbar, ${required_mb} MB benötigt"
    
    if [[ $available_mb -lt $required_mb ]]; then
        log_error "$MSG_ERROR_INSUFFICIENT_DISK_SPACE ${required_mb} MB benötigt, nur ${available_mb} MB verfügbar"
        
        # API: Fehler melden
        if declare -f api_update_status >/dev/null 2>&1; then
            api_update_status "error" "" "" "Nicht genug Speicherplatz: ${available_mb}/${required_mb} MB"
        fi
        
        return 1
    fi
    
    return 0
}

# ============================================================================
# SYSTEM INFORMATION COLLECTION
# ============================================================================

# Funktion: Sammle System-Informationen für API
# Schreibt: system.json im API-Verzeichnis
collect_system_information() {
    local api_dir="${INSTALL_DIR:-/opt/disk2iso}/api"
    local output_file="${api_dir}/system.json"
    
    # Erstelle API-Verzeichnis falls nicht vorhanden
    mkdir -p "$api_dir" 2>/dev/null || return 1
    
    # OS Informationen
    local os_name="Unknown"
    local os_version="Unknown"
    local kernel_version=$(uname -r 2>/dev/null || echo "Unknown")
    local architecture=$(uname -m 2>/dev/null || echo "Unknown")
    local hostname_value=$(hostname 2>/dev/null || echo "Unknown")
    local uptime_value=$(uptime -p 2>/dev/null | sed 's/^up //' || echo "Unknown")
    
    # Distribution erkennen
    if [[ -f /etc/os-release ]]; then
        os_name=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
        os_version=$(grep "^VERSION=" /etc/os-release | cut -d= -f2 | tr -d '"')
    elif [[ -f /etc/debian_version ]]; then
        os_name="Debian"
        os_version=$(cat /etc/debian_version)
    fi
    
    # Container-Typ
    local container_status="false"
    local container_type_value="none"
    if $IS_CONTAINER; then
        container_status="true"
        container_type_value="$CONTAINER_TYPE"
    fi
    
    # Laufwerk-Informationen
    local optical_drive="none"
    local optical_drive_model="Unknown"
    if [[ -b "$CD_DEVICE" ]]; then
        optical_drive="$CD_DEVICE"
        # Versuche Modell zu ermitteln
        if [[ -f "/sys/block/$(basename $CD_DEVICE)/device/model" ]]; then
            optical_drive_model=$(cat "/sys/block/$(basename $CD_DEVICE)/device/model" 2>/dev/null | xargs)
        fi
    fi
    
    # Speicherplatz
    local output_dir_space="0"
    local output_dir_total="0"
    local output_dir_used_percent="0"
    if [[ -d "$OUTPUT_DIR" ]]; then
        local df_output=$(df -BG "$OUTPUT_DIR" 2>/dev/null | tail -1)
        if [[ -n "$df_output" ]]; then
            output_dir_total=$(echo "$df_output" | awk '{print $2}' | sed 's/G//')
            output_dir_space=$(echo "$df_output" | awk '{print $4}' | sed 's/G//')
            output_dir_used_percent=$(echo "$df_output" | awk '{print $5}' | sed 's/%//')
        fi
    fi
    
    # Software-Versionen (Kernsoftware)
    local cdparanoia_version="Not installed"
    local lame_version="Not installed"
    local dvdbackup_version="Not installed"
    local ddrescue_version="Not installed"
    local genisoimage_version="Not installed"
    local python_version="Not installed"
    local flask_version="Not installed"
    local mosquitto_version="Not installed"
    
    if command -v cdparanoia >/dev/null 2>&1; then
        cdparanoia_version=$(cdparanoia --version 2>&1 | head -1 | grep -oP '\d+\.\d+(\.\d+)?' || echo "installed")
    fi
    
    if command -v lame >/dev/null 2>&1; then
        lame_version=$(lame --version 2>&1 | head -1 | grep -oP '\d+\.\d+(\.\d+)?' || echo "installed")
    fi
    
    if command -v dvdbackup >/dev/null 2>&1; then
        dvdbackup_version=$(dvdbackup --version 2>&1 | grep -oP '\d+\.\d+(\.\d+)?' || echo "installed")
    fi
    
    if command -v ddrescue >/dev/null 2>&1; then
        ddrescue_version=$(ddrescue --version 2>&1 | head -1 | grep -oP '\d+\.\d+(\.\d+)?' || echo "installed")
    fi
    
    if command -v genisoimage >/dev/null 2>&1; then
        genisoimage_version=$(genisoimage --version 2>&1 | head -1 | grep -oP '\d+\.\d+(\.\d+)?' || echo "installed")
    fi
    
    if command -v python3 >/dev/null 2>&1; then
        python_version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+(\.\d+)?' || echo "installed")
    fi

    if python3 -c "import flask" 2>/dev/null; then
        flask_version=$(python3 -c "import importlib.metadata; print(importlib.metadata.version('flask'))" 2>/dev/null || echo "installed")
    elif [[ -f "/opt/disk2iso/venv/bin/python3" ]]; then
        # Prüfe auch im venv
        if /opt/disk2iso/venv/bin/python3 -c "import flask" 2>/dev/null; then
            flask_version=$(/opt/disk2iso/venv/bin/python3 -c "import importlib.metadata; print(importlib.metadata.version('flask'))" 2>/dev/null || echo "installed")
        fi
    fi

    if command -v mosquitto >/dev/null 2>&1; then
        mosquitto_version=$(mosquitto -h 2>&1 | grep -oP 'version \K\d+\.\d+(\.\d+)?' || echo "installed")
    fi
    
    # Timestamp
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    
    # Erstelle JSON (manuell, um jq-Abhängigkeit zu vermeiden)
    cat > "$output_file" <<EOF
{
  "os": {
    "distribution": "$os_name",
    "version": "$os_version",
    "kernel": "$kernel_version",
    "architecture": "$architecture",
    "hostname": "$hostname_value",
    "uptime": "$uptime_value"
  },
  "container": {
    "is_container": $container_status,
    "type": "$container_type_value"
  },
  "hardware": {
    "optical_drive": "$optical_drive",
    "drive_model": "$optical_drive_model"
  },
  "storage": {
    "output_dir": "$OUTPUT_DIR",
    "total_gb": $output_dir_total,
    "free_gb": $output_dir_space,
    "used_percent": $output_dir_used_percent
  },
  "software": {
    "cdparanoia": "$cdparanoia_version",
    "lame": "$lame_version",
    "dvdbackup": "$dvdbackup_version",
    "ddrescue": "$ddrescue_version",
    "genisoimage": "$genisoimage_version",
    "python": "$python_version",
    "flask": "$flask_version",
    "mosquitto": "$mosquitto_version"
  },
  "timestamp": "$timestamp"
}
EOF
    
    chmod 644 "$output_file" 2>/dev/null || true
    return 0
}
