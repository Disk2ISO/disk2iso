#!/bin/bash
################################################################################
# disk2iso - Deinstallation Script
# Filepath: uninstall.sh
#
# Beschreibung:
#   Deinstalliert disk2iso und entfernt alle installierten Dateien.
#
# Verwendung:
#   sudo ./uninstall.sh
#
################################################################################

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ermittle Script-Verzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Lade Sprachdatei
source "${SCRIPT_DIR}/disk2iso-lib/lang/messages.de"

# Prüfe Root-Rechte
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$MSG_UNINSTALL_ROOT_ERROR${NC}"
   echo "$MSG_UNINSTALL_ROOT_HINT $0"
   exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     $MSG_UNINSTALL_TITLE                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Service-Deinstallation
# ============================================================================

remove_service() {
    local service_file="/etc/systemd/system/disk2iso.service"
    
    if [[ -f "$service_file" ]]; then
        echo -e "${BLUE}$MSG_UNINSTALL_SERVICE${NC}"
        
        # Stoppe Service falls aktiv
        if systemctl is-active --quiet disk2iso.service; then
            echo "$MSG_UNINSTALL_SERVICE_STOP"
            systemctl stop disk2iso.service
        fi
        
        # Deaktiviere Service falls enabled
        if systemctl is-enabled --quiet disk2iso.service; then
            echo "$MSG_UNINSTALL_SERVICE_DISABLE"
            systemctl disable disk2iso.service
        fi
        
        # Entferne Service-Datei
        rm -f "$service_file"
        systemctl daemon-reload
        
        echo -e "${GREEN}$MSG_UNINSTALL_SERVICE_OK${NC}"
    else
        echo -e "${YELLOW}$MSG_UNINSTALL_SERVICE_NOT_INSTALLED${NC}"
    fi
}

# ============================================================================
# Script-Deinstallation
# ============================================================================

remove_script() {
    echo ""
    echo -e "${BLUE}$MSG_UNINSTALL_FILES${NC}"
    
    local target_dir="/usr/local/bin"
    local script_name="disk2iso.sh"
    local script_path="${target_dir}/${script_name}"
    local lib_path="${target_dir}/disk2iso-lib"
    
    # Entferne Hauptskript
    if [[ -f "$script_path" ]]; then
        rm -f "$script_path"
        echo -e "${GREEN}$MSG_UNINSTALL_SCRIPT_OK $script_path${NC}"
    fi
    
    # Entferne lib-Verzeichnis
    if [[ -d "$lib_path" ]]; then
        rm -rf "$lib_path"
        echo -e "${GREEN}$MSG_UNINSTALL_LIBS_OK $lib_path${NC}"
    fi
}

# ============================================================================
# Daten-Bereinigung (optional)
# ============================================================================

remove_data() {
    echo ""
    read -p "$MSG_UNINSTALL_DATA_PROMPT " -r
    echo
    
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        echo -e "${YELLOW}$MSG_UNINSTALL_DATA_KEEP${NC}"
        return 0
    fi
    
    # Standardpfad aus config
    local output_dir="/mnt/pve/Public/images"
    
    if [[ -d "$output_dir" ]]; then
        echo -e "${YELLOW}$MSG_UNINSTALL_DATA_WARNING $output_dir${NC}"
        read -p "$MSG_UNINSTALL_DATA_CONFIRM " -r
        echo
        
        if [[ "$REPLY" == "ja" ]]; then
            echo -e "${BLUE}$MSG_UNINSTALL_DATA_DELETE${NC}"
            rm -rf "${output_dir}"/*
            echo -e "${GREEN}$MSG_UNINSTALL_DATA_OK${NC}"
        else
            echo -e "${YELLOW}$MSG_UNINSTALL_DATA_ABORT${NC}"
        fi
    fi
}

# ============================================================================
# Hauptprogramm
# ============================================================================

main() {
    remove_service
    remove_script
    remove_data
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     $MSG_UNINSTALL_COMPLETE              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "$MSG_UNINSTALL_REMOVED"
    echo ""
}

main "$@"
