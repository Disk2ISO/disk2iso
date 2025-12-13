#!/bin/bash
################################################################################
# disk2iso - Installation Script
# Filepath: install.sh
#
# Beschreibung:
#   Installiert alle erforderlichen Abhängigkeiten und richtet optional
#   den systemd-Service ein.
#
# Verwendung:
#   sudo ./install.sh
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
   echo -e "${RED}$MSG_INSTALL_ROOT_ERROR${NC}"
   echo "$MSG_INSTALL_ROOT_HINT $0"
   exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     $MSG_INSTALL_TITLE                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Distro-Erkennung
# ============================================================================

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_package_manager)

if [[ "$PKG_MANAGER" == "unknown" ]]; then
    echo -e "${RED}$MSG_INSTALL_PKG_UNKNOWN${NC}"
    echo "$MSG_INSTALL_PKG_SUPPORTED"
    exit 1
fi

echo -e "${GREEN}✓${NC} $MSG_INSTALL_PKG_DETECTED ${BLUE}$PKG_MANAGER${NC}"
echo ""

# ============================================================================
# Dependency-Definitionen
# ============================================================================

# Kritische Dependencies (müssen installiert sein)
declare -A CRITICAL_DEPS=(
    ["dd"]="coreutils"
    ["md5sum"]="coreutils"
    ["lsblk"]="util-linux"
    ["isoinfo"]="genisoimage"
)

# Optionale Dependencies mit Paket-Namen pro Distro
declare -A OPTIONAL_DEPS_APT=(
    ["ddrescue"]="gddrescue"
    ["dvdbackup"]="dvdbackup"
    ["mkisofs"]="genisoimage"
    ["pv"]="pv"
    ["cdparanoia"]="cdparanoia"
    ["lame"]="lame"
    ["cd-discid"]="cd-discid"
    ["curl"]="curl"
    ["jq"]="jq"
    ["cdrdao"]="cdrdao"
    ["eyeD3"]="eyed3"
    ["mid3v2"]="python3-mutagen"
)

declare -A OPTIONAL_DEPS_DNF=(
    ["ddrescue"]="ddrescue"
    ["dvdbackup"]="dvdbackup"
    ["mkisofs"]="genisoimage"
    ["pv"]="pv"
    ["cdparanoia"]="cdparanoia-paranoia"
    ["lame"]="lame"
    ["cd-discid"]="cd-discid"
    ["curl"]="curl"
    ["jq"]="jq"
    ["cdrdao"]="cdrdao"
    ["eyeD3"]="python3-eyed3"
    ["mid3v2"]="python3-mutagen"
)

declare -A OPTIONAL_DEPS_PACMAN=(
    ["ddrescue"]="ddrescue"
    ["dvdbackup"]="dvdbackup"
    ["mkisofs"]="cdrtools"
    ["pv"]="pv"
    ["cdparanoia"]="cdparanoia"
    ["lame"]="lame"
    ["cd-discid"]="cd-discid"
    ["curl"]="curl"
    ["jq"]="jq"
    ["cdrdao"]="cdrdao"
    ["eyeD3"]="python-eyed3"
    ["mid3v2"]="python-mutagen"
)

# ============================================================================
# Dependency-Check
# ============================================================================

check_dependencies() {
    echo -e "${BLUE}$MSG_INSTALL_CHECK_CRITICAL${NC}"
    
    local missing_critical=()
    local install_critical=()
    
    for cmd in "${!CRITICAL_DEPS[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_critical+=("$cmd")
            install_critical+=("${CRITICAL_DEPS[$cmd]}")
        fi
    done
    
    if [[ ${#missing_critical[@]} -gt 0 ]]; then
        echo -e "${RED}$MSG_INSTALL_MISSING_CRITICAL ${missing_critical[*]}${NC}"
        echo -e "${YELLOW}$MSG_INSTALL_INSTALLING ${install_critical[*]}${NC}"
        install_packages "${install_critical[@]}"
    else
        echo -e "${GREEN}$MSG_INSTALL_CRITICAL_OK${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}$MSG_INSTALL_CHECK_OPTIONAL${NC}"
    
    local missing_optional=()
    local install_optional=()
    
    # Wähle richtige Dependency-Map
    local -n dep_map
    case "$PKG_MANAGER" in
        apt)     dep_map=OPTIONAL_DEPS_APT ;;
        dnf|yum) dep_map=OPTIONAL_DEPS_DNF ;;
        pacman)  dep_map=OPTIONAL_DEPS_PACMAN ;;
        *)       dep_map=OPTIONAL_DEPS_APT ;;
    esac
    
    for cmd in "${!dep_map[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_optional+=("$cmd")
            
            local pkg="${dep_map[$cmd]}"
            # Verhindere Duplikate
            if [[ ! " ${install_optional[*]} " =~ " ${pkg} " ]]; then
                install_optional+=("$pkg")
            fi
        fi
    done
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        echo -e "${YELLOW}$MSG_INSTALL_MISSING_OPTIONAL ${missing_optional[*]}${NC}"
        echo ""
        echo "$MSG_INSTALL_OPTIONAL_DESC"
        echo "$MSG_INSTALL_OPTIONAL_DDRESCUE"
        echo "$MSG_INSTALL_OPTIONAL_DVDBACKUP"
        echo "$MSG_INSTALL_OPTIONAL_AUDIO"
        echo "$MSG_INSTALL_OPTIONAL_METADATA"
        echo "$MSG_INSTALL_OPTIONAL_CDTEXT"
        echo "$MSG_INSTALL_OPTIONAL_ID3"
        echo "$MSG_INSTALL_OPTIONAL_PV"
        echo ""
        
        read -p "$MSG_INSTALL_OPTIONAL_PROMPT " -r
        echo
        if [[ $REPLY =~ ^[Jj]$ ]]; then
            install_packages "${install_optional[@]}"
        else
            echo -e "${YELLOW}$MSG_INSTALL_OPTIONAL_SKIPPED${NC}"
        fi
    else
        echo -e "${GREEN}$MSG_INSTALL_OPTIONAL_OK${NC}"
    fi
    
    # MakeMKV Hinweis
    if ! command -v makemkvcon >/dev/null 2>&1; then
        echo ""
        echo -e "${YELLOW}$MSG_INSTALL_MAKEMKV_MISSING${NC}"
        echo "$MSG_INSTALL_MAKEMKV_INFO"
        echo "$MSG_INSTALL_MAKEMKV_DOWNLOAD"
        echo "$MSG_INSTALL_MAKEMKV_UNAVAIL"
    fi
}

# ============================================================================
# Paket-Installation
# ============================================================================

install_packages() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo -e "${BLUE}$MSG_INSTALL_PACKAGES ${packages[*]}${NC}"
    
    case "$PKG_MANAGER" in
        apt)
            apt-get update -qq
            apt-get install -y "${packages[@]}"
            ;;
        dnf)
            dnf install -y "${packages[@]}"
            ;;
        yum)
            yum install -y "${packages[@]}"
            ;;
        pacman)
            pacman -S --noconfirm "${packages[@]}"
            ;;
        zypper)
            zypper install -y "${packages[@]}"
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}$MSG_INSTALL_SUCCESS${NC}"
    else
        echo -e "${RED}$MSG_INSTALL_FAILED${NC}"
        exit 1
    fi
}

# ============================================================================
# Script-Installation
# ============================================================================

install_script() {
    echo ""
    echo -e "${BLUE}$MSG_INSTALL_SCRIPT${NC}"
    
    local target_dir="/usr/local/bin"
    local script_name="disk2iso.sh"
    local target_path="${target_dir}/${script_name}"
    
    # Kopiere Hauptskript
    if cp -f "${SCRIPT_DIR}/${script_name}" "$target_path"; then
        chmod +x "$target_path"
        echo -e "${GREEN}$MSG_INSTALL_SCRIPT_OK $target_path${NC}"
    else
        echo -e "${RED}$MSG_INSTALL_SCRIPT_ERROR${NC}"
        exit 1
    fi
    
    # Kopiere Bibliotheken direkt (ohne lib/-Unterordner)
    local lib_target="${target_dir}/disk2iso-lib"
    if [[ -d "${SCRIPT_DIR}/disk2iso-lib" ]]; then
        rm -rf "$lib_target"
        
        if cp -r "${SCRIPT_DIR}/disk2iso-lib" "$lib_target"; then
            echo -e "${GREEN}$MSG_INSTALL_LIBS_OK $lib_target/${NC}"
        else
            echo -e "${RED}$MSG_INSTALL_LIBS_ERROR${NC}"
            exit 1
        fi
        
        # Passe Pfad im Hauptskript an (zeigt direkt auf Bibliotheken-Verzeichnis)
        sed -i "s|SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE\\[0\\]}\")\" \&\& pwd)\"|SCRIPT_DIR=\"${lib_target}\"|" "$target_path"
    fi
}

# ============================================================================
# Service-Installation
# ============================================================================

install_service() {
    echo ""
    read -p "$MSG_INSTALL_SERVICE_PROMPT " -r
    echo
    
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        echo -e "${YELLOW}$MSG_INSTALL_SERVICE_SKIPPED${NC}"
        return 0
    fi
    
    echo -e "${BLUE}$MSG_INSTALL_SERVICE${NC}"
    
    local service_file="${SCRIPT_DIR}/disk2iso.service"
    local service_target="/etc/systemd/system/disk2iso.service"
    
    if [[ ! -f "$service_file" ]]; then
        echo -e "${RED}$MSG_INSTALL_SERVICE_NOT_FOUND $service_file${NC}"
        return 1
    fi
    
    # Kopiere Service-Datei
    if cp -f "$service_file" "$service_target"; then
        echo -e "${GREEN}$MSG_INSTALL_SERVICE_OK $service_target${NC}"
    else
        echo -e "${RED}$MSG_INSTALL_SERVICE_ERROR${NC}"
        return 1
    fi
    
    # Reload systemd
    systemctl daemon-reload
    
    # Aktiviere Service
    read -p "$MSG_INSTALL_SERVICE_ENABLE_PROMPT " -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        if systemctl enable disk2iso.service; then
            echo -e "${GREEN}$MSG_INSTALL_SERVICE_ENABLED${NC}"
        else
            echo -e "${RED}$MSG_INSTALL_SERVICE_ENABLE_ERROR${NC}"
            return 1
        fi
    fi
    
    # Starte Service
    read -p "$MSG_INSTALL_SERVICE_START_PROMPT " -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        if systemctl start disk2iso.service; then
            echo -e "${GREEN}$MSG_INSTALL_SERVICE_STARTED${NC}"
            echo ""
            echo "$MSG_INSTALL_SERVICE_STATUS_CMD"
            echo "$MSG_INSTALL_SERVICE_LOGS_CMD"
        else
            echo -e "${RED}$MSG_INSTALL_SERVICE_START_ERROR${NC}"
            return 1
        fi
    fi
}

# ============================================================================
# Hauptprogramm
# ============================================================================

main() {
    check_dependencies
    install_script
    install_service
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     $MSG_INSTALL_COMPLETE                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "$MSG_INSTALL_USAGE"
    echo "$MSG_INSTALL_USAGE_MANUAL"
    echo "$MSG_INSTALL_USAGE_SERVICE"
    echo "$MSG_INSTALL_USAGE_STATUS"
    echo "$MSG_INSTALL_USAGE_LOGS"
    echo ""
}

main "$@"
