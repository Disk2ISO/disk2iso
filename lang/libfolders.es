#!/bin/bash
################################################################################
# disk2iso - Archivo de idioma español para lib-folders.sh
# Filepath: lang/lib-folders.es
#
# Descripción:
#   Mensajes para la gestión de directorios
#
################################################################################

# ============================================================================
# OPERACIONES DE DIRECTORIO
# ============================================================================

# Subfolder Operations
readonly MSG_ERROR_ENSURE_SUBFOLDER_NO_NAME="ERROR: folders_ensure_subfolder requiere nombre de carpeta"
readonly MSG_SUBFOLDER_CREATED="Subcarpeta creada:"
readonly MSG_ERROR_CREATE_SUBFOLDER="ERROR: No se puede crear la subcarpeta:"
readonly MSG_ERROR_PARENT_DIR_MISSING="Directorio padre faltante:"

# Output Directory
readonly MSG_ERROR_OUTPUT_DIR_READ_FAILED="No se pudo leer el directorio de salida de la configuración"
readonly MSG_WARNING_OUTPUT_DIR_MISSING="Directorio de salida faltante:"
readonly MSG_ERROR_OUTPUT_DIR_PARENT_MISSING="Falta el directorio padre del directorio de salida:"
readonly MSG_ERROR_OUTPUT_DIR_CREATE_FAILED="No se pudo crear el directorio de salida:"
readonly MSG_INFO_OUTPUT_DIR_CREATED="Directorio de salida creado automáticamente:"

# Temp Directory
readonly MSG_WARNING_TEMP_DIR_MISSING="Directorio temporal faltante:"
readonly MSG_ERROR_TEMP_DIR_PARENT_MISSING="¡No se puede crear el directorio temporal! Falta el directorio padre:"
readonly MSG_ERROR_TEMP_DIR_CREATE_FAILED="No se pudo crear el directorio temporal:"
readonly MSG_INFO_TEMP_DIR_CREATED="Directorio temporal creado automáticamente:"

# Log Directory
readonly MSG_WARNING_LOG_DIR_MISSING="Directorio de registro faltante:"
readonly MSG_ERROR_LOG_DIR_PARENT_MISSING="¡No se puede crear el directorio de registro! Falta el directorio padre:"
readonly MSG_ERROR_LOG_DIR_CREATE_FAILED="No se pudo crear el directorio de registro:"
readonly MSG_INFO_LOG_DIR_CREATED="Directorio de registro creado automáticamente:"

# Module Directory
readonly MSG_WARNING_MODULE_DIR_MISSING="Directorio de módulo faltante:"
readonly MSG_ERROR_MODULE_DIR_PARENT_MISSING="¡No se puede crear el directorio de módulo! Falta el directorio padre:"
readonly MSG_ERROR_MODULE_DIR_CREATE_FAILED="No se pudo crear el directorio de módulo:"
readonly MSG_INFO_MODULE_DIR_CREATED="Directorio de módulo creado automáticamente:"

# Mount Directory
readonly MSG_WARNING_MOUNT_DIR_MISSING="Directorio de montaje faltante:"
readonly MSG_ERROR_MOUNT_DIR_PARENT_MISSING="¡No se puede crear el directorio de montaje! Falta el directorio padre:"
readonly MSG_ERROR_MOUNT_DIR_CREATE_FAILED="No se pudo crear el directorio de montaje:"
readonly MSG_INFO_MOUNT_DIR_CREATED="Directorio de montaje creado automáticamente:"
readonly MSG_ERROR_MOUNT_POINT_CREATE_FAILED="No se pudo crear el punto de montaje:"

# Debug Messages
readonly MSG_DEBUG_SUBFOLDER_EXISTS="folders_ensure_subfolder: La ruta ya existe:"
readonly MSG_DEBUG_SUBFOLDER_PERMISSIONS_NORMAL="folders_ensure_subfolder: Carpeta creada con permisos"
readonly MSG_DEBUG_SUBFOLDER_PERMISSIONS_PUBLIC="folders_ensure_subfolder: Carpeta creada con permisos"

# Common Suffixes
readonly MSG_SUFFIX_TRY_CREATE=" - intentando crear"
readonly MSG_SUFFIX_MISSING_PERMISSIONS=" (¿permisos faltantes?)"
