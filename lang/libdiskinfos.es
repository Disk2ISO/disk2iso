# ============================================================================
# Archivo de idioma: libdiskinfos (Español)
# ============================================================================
# Descripción: Mensajes en español para detección de disco y metadatos
# Versión: 1.0.0
# Fecha: 2026-02-02
# ============================================================================

# Dependency Check
readonly MSG_ERROR_CRITICAL_TOOLS_MISSING="Faltan herramientas críticas para la detección de disco"
readonly MSG_INFO_INSTALL_MOUNT="Instalación: apt install mount"
readonly MSG_WARNING_OPTIONAL_TOOLS_MISSING="Faltan herramientas opcionales para una mejor detección de disco"
readonly MSG_INFO_INSTALL_ISOINFO="Instalación: apt install genisoimage util-linux"
readonly MSG_INFO_FALLBACK_METHODS="La detección de disco utiliza métodos de respaldo"

# Disc Info Validation
readonly MSG_WARNING_EMPTY_LABEL="Etiqueta vacía - usando respaldo"
readonly MSG_ERROR_INVALID_DISC_TYPE="Tipo de disco no válido"
readonly MSG_WARNING_INVALID_SECTORS="Número de sectores no válido"

# Init Disc Info
readonly MSG_ERROR_DISC_TYPE_FAILED="No se pudo detectar el tipo de disco"
readonly MSG_ERROR_LABEL_FAILED="No se pudo extraer la etiqueta del disco"
readonly MSG_WARNING_IDENTIFIER_FAILED="No se pudo calcular el identificador del disco"
readonly MSG_ERROR_FILENAMES_FAILED="No se pudieron generar los nombres de archivo"

# Debug Messages - Disc Info Functions
readonly MSG_DEBUG_DISCINFO_INIT="DISC_INFO reiniciado"
readonly MSG_DEBUG_GET_ID="discinfo_get_id"
readonly MSG_DEBUG_GET_ID_EMPTY="No se ha establecido disc_id"
readonly MSG_DEBUG_SET_ID="UUID"
readonly MSG_DEBUG_DETECT_ID_TYPE="Tipo de disco detectado"
readonly MSG_DEBUG_DETECT_ID_AUDIO="CD de Audio - DiscID será establecido por copy_audio_cd()"
readonly MSG_DEBUG_GET_IDENTIFIER="discinfo_get_identifier"
readonly MSG_DEBUG_GET_IDENTIFIER_EMPTY="No se ha establecido disc_identifier"
readonly MSG_DEBUG_SET_IDENTIFIER="Identificador"
readonly MSG_DEBUG_SET_LABEL="discinfo_set_label"
readonly MSG_DEBUG_SET_TYPE="discinfo_set_type"
readonly MSG_DEBUG_SET_SIZE="discinfo_set_size"
readonly MSG_DEBUG_SET_FILESYSTEM="discinfo_set_filesystem"
readonly MSG_DEBUG_SET_COPY_METHOD="discinfo_set_copy_method"
readonly MSG_DEBUG_SET_CREATED_AT="discinfo_set_created_at"
readonly MSG_DEBUG_SET_TITLE="discinfo_set_title"
readonly MSG_DEBUG_SET_RELEASE_DATE="discinfo_set_release_date"
readonly MSG_DEBUG_SET_COUNTRY="discinfo_set_country"
readonly MSG_DEBUG_SET_PUBLISHER="discinfo_set_publisher"
readonly MSG_DEBUG_SET_PROVIDER="discinfo_set_provider"
readonly MSG_DEBUG_SET_PROVIDER_ID="discinfo_set_provider_id"
readonly MSG_DEBUG_SET_COVER_PATH="discinfo_set_cover_path"
readonly MSG_DEBUG_SET_COVER_URL="discinfo_set_cover_url"
readonly MSG_DEBUG_SET_ISO_FILENAME="discinfo_set_iso_filename"
readonly MSG_DEBUG_SET_MD5_FILENAME="discinfo_set_md5_filename"
readonly MSG_DEBUG_SET_LOG_FILENAME="discinfo_set_log_filename"
readonly MSG_DEBUG_SET_ISO_BASENAME="discinfo_set_iso_basename"
readonly MSG_DEBUG_SET_TEMP_PATHNAME="discinfo_set_temp_pathname"

# Debug Messages - Init Disc Info
readonly MSG_DEBUG_INIT_START="Iniciando análisis del disco..."
readonly MSG_DEBUG_INIT_TYPE="Tipo de disco"
readonly MSG_DEBUG_INIT_FILESYSTEM="Sistema de archivos"
readonly MSG_DEBUG_INIT_LABEL="Etiqueta del disco"
readonly MSG_DEBUG_INIT_AUDIO_LABEL="CD de Audio - La etiqueta será establecida en copy_audio_cd()"
readonly MSG_DEBUG_INIT_SIZE="Tamaño del disco"
readonly MSG_DEBUG_INIT_SECTORS="sectores"
readonly MSG_DEBUG_INIT_CREATED_AT="Fecha de creación ISO"
readonly MSG_DEBUG_INIT_ID_LATER="No se detectó ID de disco (se establecerá más tarde si es necesario)"
readonly MSG_DEBUG_INIT_ID="ID del disco"
readonly MSG_DEBUG_INIT_IDENTIFIER="Identificador del disco"
readonly MSG_DEBUG_INIT_TITLE="Título del disco"
readonly MSG_DEBUG_INIT_RELEASE_DATE="Fecha de lanzamiento"
readonly MSG_DEBUG_INIT_PROVIDER="Proveedor de metadatos"
readonly MSG_DEBUG_INIT_ISO_FILENAME="Nombre del archivo ISO"
readonly MSG_DEBUG_INIT_AUDIO_FILENAMES="CD de Audio - Los nombres de archivo se generarán en copy_audio_cd()"
readonly MSG_DEBUG_INIT_ESTIMATED_SIZE="Tamaño estimado (con sobrecarga)"
readonly MSG_DEBUG_INIT_SUCCESS="Análisis del disco completado exitosamente"

# Debug Messages - Disc Data Functions
readonly MSG_DEBUG_SET_ARTIST="discdata_set_artist"
readonly MSG_DEBUG_SET_ALBUM="discdata_set_album"
readonly MSG_DEBUG_SET_YEAR="discdata_set_year"
readonly MSG_DEBUG_SET_GENRE="discdata_set_genre"
readonly MSG_DEBUG_SET_TRACK_COUNT="discdata_set_track_count"
readonly MSG_DEBUG_SET_DURATION="discdata_set_duration"
readonly MSG_DEBUG_SET_TOC="discdata_set_toc"
readonly MSG_DEBUG_SET_ORIGINAL_RELEASE_DATE="discdata_set_original_release_date"
readonly MSG_DEBUG_SET_ORIGINAL_COUNTRY="discdata_set_original_country"
readonly MSG_DEBUG_SET_ORIGINAL_LABEL="discdata_set_original_label"
readonly MSG_DEBUG_SET_COMPOSER="discdata_set_composer"
readonly MSG_DEBUG_SET_SONGWRITER="discdata_set_songwriter"
readonly MSG_DEBUG_SET_ARRANGER="discdata_set_arranger"
