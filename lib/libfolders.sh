#!/bin/bash
# =============================================================================
# Folder Management Library
# =============================================================================
# Filepath: lib/libfolders.sh
#
# Beschreibung:
#   Verwaltung von Verzeichnissen und temporären Ordnern
#   - Temp-Verzeichnis-Erstellung und Bereinigung
#   - Lazy Initialization für Output-Ordner
#   - folders_ensure_subfolder() für alle Module
#   - cleanup_temp() für automatische Bereinigung
#
# -----------------------------------------------------------------------------
# Dependencies: liblogging (für log_* Funktionen)
# -----------------------------------------------------------------------------
# Author: D.Götze
# Version: 1.2.1
# Last Change: 2026-01-26 20:00
# =============================================================================

# =============================================================================
# DEPENDENCY CHECK
# =============================================================================

# ===========================================================================
# folders_check_dependencies
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
folders_check_dependencies() {
    # Lade Sprachdatei für dieses Modul
    load_module_language "folders"
    
    # Prüfe/Erstelle OUTPUT_DIR (kritisch für alle Folder-Operationen)
    folders_get_output_dir || return 1
    
    # Folders-Modul benötigt nur mkdir
    # mkdir ist POSIX-Standard und auf jedem System verfügbar
    return 0
}

# ============================================================================
# PATH CONSTANTS
# ============================================================================
# Konstanten für Unterordner-Namen (relativ zu OUTPUT_DIR)
# ----------------------------------------------------------------------------
# 1. CoreModules nutzen diese Konstanten für konsistente Ordner-Struktur
# 2. folders_ensure_subfolder() nutzt diese Konstanten für konsistente Ordner-Erstellung
# 3. Optionale Module können eigene Unterordner definieren (z.B. audio-cd, dvd-video)
# ----------------------------------------------------------------------------
# Globale Festsetzung für Zugriffsrechte in Ordnern -------------------------
readonly DIR_PERMISSIONS_NORMAL="755"        # Normale Ordner
readonly DIR_PERMISSIONS_PUBLIC="777"        # Öffentl. Ordner (.log, .temp)

# Globale Flags für Lazy Initialization -------------------------------------
_OUTPUT_DIR_CREATED=false                    # Ausgabe-Verzeichnis erstellt
_TEMP_DIR_CREATED=false                      # Temp-Verzeichnis erstellt
_LOG_DIR_CREATED=false                       # Log-Verzeichnis erstellt
_MOUNT_DIR_CREATED=false                     # Mount-Verzeichnis erstellt

# ============================================================================
# GENERIC HELPER FUNCTIONS
# ============================================================================

# ===========================================================================
# folders_ensure_subfolder
# ---------------------------------------------------------------------------
# Funktion.: Stelle sicher dass ein Unterordner existiert, der Ordner muss
# .........  expliziet übergeben werden, Verschachtelung ('.temp/mount') wird 
# .........  nicht unterstützt.
# Parameter: $1 = Unterordner-Name 
# Rückgabe.: 0 = Erfolg
# .........  1 = Fehler
# Hinweis..: - Setzt 755 für normale Ordner
# .........  - Setzt 777 für .log/.temp Ordner (Multi-User-Zugriff)
# .........  - Fast-Path wenn Ordner bereits existiert
# ===========================================================================
folders_ensure_subfolder() {
    local subfolder="$1"
    
    #-- Parameter-Validierung -----------------------------------------------
    if [[ -z "$subfolder" ]]; then
        log_error "$MSG_ERROR_ENSURE_SUBFOLDER_NO_NAME"
        return 1
    fi
    
    #-- hier schon vollständigen Pfad erstellen für die 1. Prüfung ----------
    local full_path="${OUTPUT_DIR}/${subfolder}"

    #-- Prüfung in zwei Schritten -------------------------------------------
    #-- 1. Ordner existiert bereits -----------------------------------------    
    if [[ -d "$full_path" ]]; then
        log_debug "folders_ensure_subfolder: Path existiert bereits: '${subfolder}'"
        return 0
    fi
    
    #-- 2. Prüfe ob Parent-Dir existiert (für Self-Repair) ------------------
    local parent_dir="$(dirname "$full_path")"
    if [[ ! -d "$parent_dir" ]]; then
        log_error "Parent-Verzeichnis fehlt: $parent_dir (für $subfolder)" >&2
        return 1
    fi
    
    #-- Erstelle Ordner -----------------------------------------------------
    if mkdir -p "$full_path" 2>/dev/null; then
        log_info "$MSG_SUBFOLDER_CREATED $full_path" >&2
        #-- Setzen der Berechtigungen ---------------------------------------
        local perms="755"
        if [[ "$subfolder" =~ ^\.(log|temp) ]] || [[ "$subfolder" =~ /\.(log|temp)($|/) ]]; then
            chmod $DIR_PERMISSIONS_NORMAL "$full_path" 2>/dev/null
            log_debug "folders_ensure_subfolder: Ordner erstellt mit Permissions ${DIR_PERMISSIONS_NORMAL}"
        else
            chmod $DIR_PERMISSIONS_PUBLIC "$full_path" 2>/dev/null
            log_debug "folders_ensure_subfolder: Ordner erstellt mit Permissions ${DIR_PERMISSIONS_PUBLIC}"
        fi
    else
        #-- Fehler loggen und Return-Code setzen ----------------------------
        log_error "$MSG_ERROR_CREATE_SUBFOLDER $full_path" >&2
        return 1
    fi

    #-- Melde Erfolg zurück -------------------------------------------------
    return 0
}

# ============================================================================
# CORE FOLDER MANAGEMENT FUNCTIONS
# ============================================================================

# ===========================================================================
# folders_get_output_dir
# ---------------------------------------------------------------------------
# Funktion.: Stellt sicher, dass das Ausgabe-Verzeichnis existiert, es wird
# .........  normalerweise bei der Installation angelegt, kann aber bei
# .........  Bedarf automatisch erstellt werden (Self-Repair)
# Parameter: keine
# Rückgabe.: Pfad zum OUTPUT_DIR (ohne trailing slash)
# .........  Return-Code: 0 = Erfolg, 1 = Fehler (nicht erstellbar)
# Hinweis..: Nutzt Lazy Initialization - wird nur einmal pro Session geprüft
# .........  Erstellt Ordner automatisch wenn Parent-Dir existiert
# .........  Verwendet config_get_output_dir() aus libconfig.sh für Pfad
# ===========================================================================
folders_get_output_dir() {
    #-- Lazy Initialization: Ausgabe-Verzeichnis nur einmal prüfen ----------
    if [[ "$_OUTPUT_DIR_CREATED" == false ]]; then
        #-- Lese Ausgabe-Verzeichnis aus Konfiguration ----------------------
        local output_dir=$(config_get_output_dir) || {
            log_error "Ausgabe-Verzeichnis konnte nicht aus Konfiguration gelesen werden" >&2
            echo ""
            return 1
        }
        
        #-- Kontrolle ob das Ausgabe-Verzeichnis bereits existiert ----------
        if [[ ! -d "$output_dir" ]]; then
            log_warning "Ausgabe-Verzeichnis fehlt: $output_dir - versuche zu erstellen" >&2
            
            #-- Prüfe ob Parent-Directory existiert -------------------------
            local parent_dir="$(dirname "$output_dir")"
            if [[ ! -d "$parent_dir" ]]; then
                log_error "Ausgabe-Verzeichnis das Parent-Dir fehlt: $parent_dir" >&2
                echo ""
                return 1
            fi
            
            #-- Versuche das Ausgabe-Verzeichnis zu erstellen ---------------
            if ! mkdir -p "$output_dir" 2>/dev/null; then
                log_error "Ausgabe-Verzeichnis konnte nicht erstellt werden: $output_dir (fehlende Rechte?)" >&2
                echo ""
                return 1
            fi
            
            #-- Setze Berechtigungen ----------------------------------------
            chmod $DIR_PERMISSIONS_PUBLIC "$output_dir" 2>/dev/null
            log_info "Ausgabe-Verzeichnis automatisch erstellt: $output_dir" >&2

            #-- Flag setzen -----------------------------------------------------
            _OUTPUT_DIR_CREATED=true
        fi
    fi

    #-- Gebe Ausgabe-Verzeichnis zurück -------------------------------------
    echo "${output_dir%/}"
    return 0
}

# ===========================================================================
# folders_get_temp_dir
# ---------------------------------------------------------------------------
# Funktion.: Prüft das Vorhandensein des Temp-Ordner unterhalb des Ausgabe-
# .........  Verzeichnis, erstellt diesen falls notwendig, und gibt den
# .........  vollständigen Pfad zurück.
# Parameter: keine
# Rückgabe.: Pfad zum Temp-Verzeichnis (ohne trailing slash)
# .........  Return-Code: 0 = Erfolg, 1 = Fehler (nicht erstellbar)
# Hinweis..: Nutzt Lazy Initialization - wird nur einmal pro Session geprüft
# ===========================================================================
folders_get_temp_dir() {
    #-- Ermitteln des kompletten Verzeichnis-Pfad ---------------------------
    local temp_dir="$(folders_get_output_dir)/.temp"

    #-- Lazy Initialization: Verzeichnis nur einmal prüfen ------------------
    if [[ "$_TEMP_DIR_CREATED" == false ]]; then
        #-- Prüfe ob Temp-Verzeichnis existiert -----------------------------
        if [[ ! -d "$temp_dir" ]]; then
            log_warning "Temp-Verzeichnis fehlt: $temp_dir - versuche zu erstellen" >&2

            #-- Prüfe ob Parent-Directory existiert ---------------------------
            local parent_dir="$(dirname "$temp_dir")"
            if [[ ! -d "$parent_dir" ]]; then
                log_error "Temp-Verzeichnis kann nicht erstellt werden! Das Parent-Dir fehlt: $parent_dir" >&2
                return 1
            fi

            #-- Versuche das Temp-Verzeichnis zu erstellen --------------------
            if ! folders_ensure_subfolder "$temp_dir"; then
                log_error "Temp-Verzeichnis konnte nicht erstellt werden: $temp_dir (fehlende Rechte?)" >&2
                return 1
            fi
            log_info "Temp-Verzeichnis automatisch erstellt: $temp_dir" >&2

            #-- Flag setzen -----------------------------------------------------
            _TEMP_DIR_CREATED=true
        fi
    fi

    #-- Gebe Verzeichnis zurück geben ---------------------------------------
    echo "${temp_dir%/}"
    return 0
}

# ===========================================================================
# folders_get_log_dir
# ---------------------------------------------------------------------------
# Funktion.: Prüft das Vorhandensein des Log-Ordner unterhalb des Ausgabe-
# .........  Verzeichnis, erstellt diesen falls notwendig, und gibt den
# .........  vollständigen Pfad zurück.
# Parameter: keine
# Rückgabe.: Pfad zum Log-Verzeichnis (ohne trailing slash)
# .........  Return-Code: 0 = Erfolg, 1 = Fehler (nicht erstellbar)
# Hinweis..: Nutzt Lazy Initialization - wird nur einmal pro Session geprüft
# .........  Log-Verzeichnis hat 777 Permissions für Multi-User-Zugriff
# ===========================================================================
folders_get_log_dir() {
    #-- Ermitteln des kompletten Verzeichnis-Pfad ---------------------------
    local log_dir="$(folders_get_output_dir)/.log"

    #-- Lazy Initialization: Verzeichnis nur einmal prüfen ------------------
    if [[ "$_LOG_DIR_CREATED" == false ]]; then
        #-- Prüfe ob Log-Verzeichnis existiert ------------------------------
        if [[ ! -d "$log_dir" ]]; then
            log_warning "Log-Verzeichnis fehlt: $log_dir - versuche zu erstellen" >&2

            #-- Prüfe ob Parent-Directory existiert -------------------------
            local parent_dir="$(dirname "$log_dir")"
            if [[ ! -d "$parent_dir" ]]; then
                log_error "Log-Verzeichnis kann nicht erstellt werden! Das Parent-Dir fehlt: $parent_dir" >&2
                return 1
            fi

            #-- Versuche das Log-Verzeichnis zu erstellen -------------------
            if ! folders_ensure_subfolder ".log"; then
                log_error "Log-Verzeichnis konnte nicht erstellt werden: $log_dir (fehlende Rechte?)" >&2
                return 1
            fi
            log_info "Log-Verzeichnis automatisch erstellt: $log_dir" >&2
        fi

        #-- Flag setzen -----------------------------------------------------
        _LOG_DIR_CREATED=true
    fi

    #-- Gebe Verzeichnis zurück ---------------------------------------------
    echo "${log_dir%/}"
    return 0
}

# ===========================================================================
# folders_get_modul_output_dir
# ---------------------------------------------------------------------------
# Funktion.: Prüft das Vorhandensein des übergebenen Modulspezifischen 
# .........  Ausgabe-Ordner unterhalb des Standard Ausgabe-Verzeichnis, 
# .........  erstellt diesen falls notwendig und gibt den vollständigen 
# .........  Pfad zurück.
# Parameter: $1 = Modulspezifischer Unterordner (optional, default: "data")
# Rückgabe.: Pfad zum Modulspezifischen-Verzeichnis (ohne trailing slash)
# .........  Return-Code: 0 = Erfolg, 1 = Fehler (nicht erstellbar)
# ===========================================================================
folders_get_modul_output_dir() {
    #-- Paramter Handling und Ermitteln des kompletten Verzeichnis-Pfad -----
    local module_subdir="$(folders_get_output_dir)/${1:-$DATA_DIR}"

    #-- Prüfe ob Data-Verzeichnis existiert ---------------------------------
    if [[ ! -d "$module_subdir" ]]; then
        log_warning "Modul-Verzeichnis fehlt: $module_subdir - versuche zu erstellen" >&2

        #-- Prüfe ob Parent-Directory existiert -----------------------------
        local parent_dir="$(dirname "$module_subdir")"
        if [[ ! -d "$parent_dir" ]]; then
            log_error "Modul-Verzeichnis kann nicht erstellt werden! Das Parent-Dir fehlt: $parent_dir" >&2
            return 1
        fi

        #-- Versuche das Data-Verzeichnis zu erstellen ----------------------
        if ! folders_ensure_subfolder "$module_subdir"; then
            log_error "Modul-Verzeichnis konnte nicht erstellt werden: $module_subdir (fehlende Rechte?)" >&2
            return 1
        fi
        log_info "Modul-Verzeichnis automatisch erstellt: $module_subdir" >&2
    fi

    #-- Gebe Verzeichnis zurück ---------------------------------------------
    echo "${module_subdir%/}"
    return 0
}

# ============================================================================
# TEMP FOLDER MANAGEMENT
# ============================================================================

# ===========================================================================
# folders_get_mount_dir
# ---------------------------------------------------------------------------
# Funktion.: Prüft das Vorhandensein des Mount-Ordner unterhalb des Temp-
# .........  Verzeichnis, erstellt diesen falls notwendig, und gibt den
# .........  vollständigen Pfad zurück.
# Parameter: keine
# Rückgabe.: Pfad zum Mount-Verzeichnis (ohne trailing slash)
# .........  Return-Code: 0 = Erfolg, 1 = Fehler (nicht erstellbar)
# Hinweis..: Nutzt Lazy Initialization - wird nur einmal pro Session geprüft
# .........  Mount-Verzeichnis hat 777 Permissions für Multi-User-Zugriff
# .........  Pfad: ${OUTPUT_DIR}/.temp/mountpoints
# ===========================================================================
folders_get_mount_dir() {
    #-- Ermitteln des kompletten Verzeichnis-Pfad ---------------------------
    local mount_dir="$(folders_get_temp_dir)/mountpoints"

    #-- Lazy Initialization: Verzeichnis nur einmal prüfen ------------------
    if [[ "$_MOUNT_DIR_CREATED" == false ]]; then
        #-- Prüfe ob Mount-Verzeichnis existiert ----------------------------
        if [[ ! -d "$mount_dir" ]]; then
            log_warning "Mount-Verzeichnis fehlt: $mount_dir - versuche zu erstellen" >&2

            #-- Prüfe ob Parent-Directory existiert -------------------------
            local parent_dir="$(dirname "$mount_dir")"
            if [[ ! -d "$parent_dir" ]]; then
                log_error "Mount-Verzeichnis kann nicht erstellt werden! Das Parent-Dir fehlt: $parent_dir" >&2
                return 1
            fi

            #-- Versuche das Mount-Verzeichnis zu erstellen -----------------
            if ! folders_ensure_subfolder "$MOUNTPOINTS_DIR"; then
                log_error "Mount-Verzeichnis konnte nicht erstellt werden: $mount_dir (fehlende Rechte?)" >&2
                return 1
            fi
            log_info "Mount-Verzeichnis automatisch erstellt: $mount_dir" >&2
        fi

        #-- Flag setzen -----------------------------------------------------
        _MOUNT_DIR_CREATED=true
    fi

    #-- Gebe Verzeichnis zurück ---------------------------------------------
    echo "${mount_dir%/}"
    return 0
}

# ===========================================================================
# folders_get_unique_mountpoint
# ---------------------------------------------------------------------------
# Funktion.: Erstellt einen eindeutigen temporären Mount-Point
# Parameter: keine
# Rückgabe.: Pfad zum Mount-Point (individueller Unterordner)
# .........  Return-Code: 0 = Erfolg, 1 = Fehler (nicht erstellbar)
# Hinweis..: Nutzt folders_get_mount_dir() für konsistentes Base-Verzeichnis
# .........  Generiert eindeutigen Namen mit PID und RANDOM
# .........  Jeder Aufruf erstellt einen NEUEN Mount-Point
# ===========================================================================
folders_get_unique_mountpoint() {
    #-- Hole Mount-Base-Verzeichnis (mit Lazy Initialization) ---------------
    local mount_base=$(folders_get_mount_dir) || return 1
    
    #-- Generiere eindeutigen Mount-Point Namen ----------------------------
    local mount_point="${mount_base}/mount_$$_${RANDOM}"
    
    #-- Erstelle Mount-Point ------------------------------------------------
    if ! mkdir -p "$mount_point" 2>/dev/null; then
        log_error "Mount-Point konnte nicht erstellt werden: $mount_point" >&2
        return 1
    fi
    
    #-- Setze Berechtigungen für Multi-User-Zugriff ------------------------
    chmod $DIR_PERMISSIONS_PUBLIC "$mount_point" 2>/dev/null
    
    #-- Gebe Mount-Point zurück ---------------------------------------------
    echo "$mount_point"
    return 0
}

# ============================================================================
# TODO: Ab hier ist das Modul noch nicht fertig implementiert!
# ============================================================================






# ============================================================================
# PATH GETTER
# ============================================================================

# ===========================================================================
# MODUL-ORDNER KONSTANTEN (für Manifest-Datei-Mapping)
# ===========================================================================

# Ordner für Modul-Komponenten (relativ zu INSTALL_DIR)
readonly MODULE_LIB_DIR="lib"                    # Bash-Module
readonly MODULE_LANG_DIR="lang"                  # Sprachdateien
readonly MODULE_CONF_DIR="conf"                  # Konfiguration
readonly MODULE_DOC_DIR="doc"                    # Dokumentation
readonly MODULE_API_DIR="api"                    # API JSON-Dateien

# Web-Frontend Ordner
readonly MODULE_HTML_DIR="www/templates"         # HTML-Partials
readonly MODULE_CSS_DIR="www/static/css"         # Stylesheets
readonly MODULE_JS_DIR="www/static/js"           # JavaScript

# Backend Ordner
readonly MODULE_ROUTER_DIR="www/routes"          # Python-Routes

# ===========================================================================
# get_conf_dir
# ---------------------------------------------------------------------------
# Funktion.: Liefert den Pfad zum Konfigurations-Verzeichnis
# Parameter: keine
# Rückgabe.: 0 = Ordner existiert (Pfad in stdout)
#            1 = Ordner fehlt (leerer String in stdout)
# Beispiel.: get_conf_dir
#            → "/opt/disk2iso/conf"
# Hinweis..: Erstellt KEINEN Ordner - nur von install.sh erstellt
# ===========================================================================
get_conf_dir() {
    local conf_dir="${INSTALL_DIR}/${MODULE_CONF_DIR}"
    
    # Prüfe ob Verzeichnis existiert
    if [[ ! -d "$conf_dir" ]]; then
        echo ""
        return 1
    fi
    
    echo "$conf_dir"
    return 0
}

# ===========================================================================
# get_api_dir
# ---------------------------------------------------------------------------
# Funktion.: Liefert den Pfad zum API-Verzeichnis für JSON-Dateien
# Parameter: keine
# Rückgabe.: 0 = Ordner existiert (Pfad in stdout)
#            1 = Ordner fehlt (leerer String in stdout)
# Beispiel.: get_api_dir
#            → "/opt/disk2iso/api"
# Hinweis..: Erstellt KEINEN Ordner - nur von install.sh erstellt
# ===========================================================================
get_api_dir() {
    local api_dir="${INSTALL_DIR}/${MODULE_API_DIR}"
    
    # Prüfe ob Verzeichnis existiert
    if [[ ! -d "$api_dir" ]]; then
        echo ""
        return 1
    fi
    
    echo "$api_dir"
    return 0
}

# ===========================================================================
# get_module_folder_path
# ---------------------------------------------------------------------------
# Funktion.: Ermittle vollständigen Pfad zu Modul-Ordner mit Fallback-Logik
# Parameter: $1 = module_name (z.B. "tmdb", "audio", "metadata")
#            $2 = folder_type (z.B. "cache", "covers", "temp", "logs")
# Rückgabe.: Vollständiger Pfad zum Ordner
# Beispiel.: get_module_folder_path "tmdb" "cache"
#            → "/media/iso/metadata/tmdb/cache"
# Fallbacks: 1. [folders] <folder_type> aus INI (spezifisch)
#            2. [folders] output aus INI + /<folder_type> (konstruiert)
#            3. folders_get_output_dir() + /<folder_type> (global)
# Nutzt....: get_module_ini_path() aus libfiles.sh
#            get_ini_value() aus libconfig.sh
# ===========================================================================
get_module_folder_path() {
    local module_name="$1"
    local folder_type="$2"
    
    if [[ -z "$module_name" ]] || [[ -z "$folder_type" ]]; then
        return 1
    fi
    
    local ini_file=$(get_module_ini_path "$module_name")
    local folder_path
    local output_path
    
    # 1. Primär: Spezifischer Ordner aus INI
    folder_path=$(get_ini_value "$ini_file" "folders" "$folder_type")
    
    if [[ -n "$folder_path" ]]; then
        echo "${OUTPUT_DIR}/${folder_path}"
        return 0
    fi
    
    # 2. Fallback: output-Basis + Unterordner
    output_path=$(get_ini_value "$ini_file" "folders" "output")
    
    if [[ -n "$output_path" ]]; then
        echo "${OUTPUT_DIR}/${output_path}/${folder_type}"
        return 0
    fi
    
    # 3. Letzter Fallback: Globaler Output-Ordner
    echo "$(folders_get_output_dir)/${folder_type}"
}

# ===========================================================================
# get_module_file_path
# ---------------------------------------------------------------------------
# Funktion.: Ermittle vollständigen Pfad zu Modul-Datei
# Parameter: $1 = file_type ("libary", "language", "js", "css", etc.)
#            $2 = filename (z.B. "libmetadata.sh")
# Rückgabe.: Vollständiger Pfad
# Beispiel.: get_module_file_path "libary" "libmetadata.sh"
#            → "/opt/disk2iso/lib/libmetadata.sh"
# ===========================================================================
get_module_file_path() {
    local file_type="$1"
    local filename="$2"
    
    if [[ -z "$file_type" ]] || [[ -z "$filename" ]]; then
        return 1
    fi
    
    local base_dir="${INSTALL_DIR:-/opt/disk2iso}"
    
    # Mappe file_type zu Ordner
    case "$file_type" in
        lib)
            echo "${base_dir}/${MODULE_LIB_DIR}/${filename}"
            ;;
        lang)
            # Sprachdateien haben Suffix (z.B. .de, .en)
            # Wenn filename ohne Suffix → nur Basis-Name
            if [[ "$filename" =~ \.(de|en|es|fr|it)$ ]]; then
                echo "${base_dir}/${MODULE_LANG_DIR}/${filename}"
            else
                # Gib Pattern zurück (für Existenz-Check mit Wildcard)
                echo "${base_dir}/${MODULE_LANG_DIR}/${filename}.*"
            fi
            ;;
        js)
            echo "${base_dir}/${MODULE_JS_DIR}/${filename}"
            ;;
        css)
            echo "${base_dir}/${MODULE_CSS_DIR}/${filename}"
            ;;
        html)
            echo "${base_dir}/${MODULE_HTML_DIR}/${filename}"
            ;;
        router)
            # Python-Dateien haben prefix "routes_"
            if [[ "$filename" == routes_* ]]; then
                echo "${base_dir}/${MODULE_ROUTER_DIR}/${filename}"
            else
                echo "${base_dir}/${MODULE_ROUTER_DIR}/routes_${filename}"
            fi
            ;;
        docu)
            echo "${base_dir}/${MODULE_DOC_DIR}/${filename}"
            ;;
        *)
            # Unbekannter Typ → Fehler
            return 1
            ;;
    esac
}

# ============================================================================
# ENDE DER FOLDER MANAGEMENT LIBRARY
# ============================================================================
