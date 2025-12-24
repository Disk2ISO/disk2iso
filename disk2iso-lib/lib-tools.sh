#!/bin/bash
################################################################################
# Tool Detection Library - Minimal (nur Debian Standard-Tools)
# Filepath: disk2iso-lib/lib-tools.sh
#
# Beschreibung:
#   Nur Prüfung der Debian-Standard-Tools (dd, md5sum, lsblk)
#
# Vereinfacht: 24.12.2025
################################################################################

# Prüfe ob dd verfügbar ist
check_dd() {
    command -v dd >/dev/null 2>&1
}

# Prüfe ob md5sum verfügbar ist
check_md5sum() {
    command -v md5sum >/dev/null 2>&1
}

# Prüfe ob lsblk verfügbar ist
check_lsblk() {
    command -v lsblk >/dev/null 2>&1
}

# Prüfe alle kritischen System-Tools
check_all_critical_tools() {
    local missing=()
    
    check_dd || missing+=("dd")
    check_md5sum || missing+=("md5sum")
    check_lsblk || missing+=("lsblk")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "${missing[@]}"
        return 1
    fi
    
    return 0
}

# Keine optionalen Tools mehr
check_all_optional_tools() {
    return 0
}
