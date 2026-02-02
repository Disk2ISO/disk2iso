# ============================================================================
# Archivo de idioma: libintegrity (Español)
# ============================================================================
# Descripción: Mensajes en español para verificación de integridad de módulos
# Versión: 1.0.0
# Fecha: 2026-02-02
# ============================================================================

# Dependency Check (integrity_check_dependencies)
readonly MSG_ERROR_GET_INI_VALUE_MISSING="ERROR: get_ini_value() no disponible (¿libconfig.sh no cargado?)"
readonly MSG_ERROR_LOG_INFO_MISSING="ERROR: log_info() no disponible (¿liblogging.sh no cargado?)"

# Module Dependency Check
readonly MSG_INFO_NO_MANIFEST="No se encontró manifiesto, omitiendo verificación de dependencias"
readonly MSG_ERROR_DB_LOAD_FAILED="No se pudo cargar el archivo DB"
readonly MSG_ERROR_DB_NOT_FOUND="Archivo DB no encontrado"
readonly MSG_WARNING_UNKNOWN_FILE_TYPE="Tipo de archivo desconocido en el manifiesto"
readonly MSG_WARNING_MODULE_FILES_MISSING="Archivos de módulo faltantes (¿módulo instalado incompletamente o corrupto?):"
readonly MSG_INFO_CHECK_INSTALLATION="Nota: Verifique la instalación del módulo o actualice el manifiesto"
readonly MSG_WARNING_FOLDERS_ENSURE_SUBFOLDER_MISSING="folders_ensure_subfolder() no disponible - omitiendo verificación de carpetas"
readonly MSG_INFO_FOLDER_OK="Carpeta OK"
readonly MSG_ERROR_FOLDER_CREATION_FAILED="Falló la creación de la carpeta"
readonly MSG_ERROR_CRITICAL_FOLDERS_MISSING="Carpetas críticas faltantes y no se pudieron crear:"
readonly MSG_INFO_CHECK_WRITE_PERMISSIONS="Verifique los permisos de escritura en OUTPUT_DIR"
readonly MSG_ERROR_CRITICAL_TOOLS_MISSING="Faltan herramientas críticas"
readonly MSG_INFO_INSTALL_TOOLS="Instalación: sudo apt install"
readonly MSG_WARNING_OPTIONAL_TOOLS_MISSING="Faltan herramientas opcionales (funcionalidad reducida)"
readonly MSG_INFO_RECOMMENDED_INSTALL="Recomendado: sudo apt install"
readonly MSG_INFO_FOLDERS_AVAILABLE="Carpetas de módulo disponibles"
readonly MSG_INFO_FOLDERS_CHECKED="carpetas verificadas/creadas"
readonly MSG_INFO_ALL_DEPENDENCIES_OK="Todas las dependencias del módulo satisfechas"

# Debug Messages
readonly MSG_DEBUG_CHECK_START="check_module_dependencies: Iniciando para módulo"
readonly MSG_DEBUG_DB_LOADED="Archivo DB cargado"
readonly MSG_DEBUG_CHECK_COMPLETE="check_module_dependencies: Completado para módulo"
readonly MSG_DEBUG_ALL_DEPS_MET="todas las dependencias satisfechas"
