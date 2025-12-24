#!/bin/bash
#############################################################################
# Disk Information Library - Minimal (nur Debian Standard-Tools)
# Filepath: disk2iso-lib/lib-diskinfos.sh
#
# Beschreibung:
#   Nur Label-Ermittlung ohne blkid/isoinfo
#   Generiert einfache Labels basierend auf Datum
#
# Vereinfacht: 24.12.2025
################################################################################

# ============================================================================
# DISK LABEL DETECTION - VEREINFACHT
# ============================================================================

# Funktion zum Ermitteln des Disk-Labels
# Generiert einfache Labels mit Datum (keine Metadaten-Tools benötigt)
get_disc_label() {
    local detected_type="${1:-data}"
    local label="Disc_$(date '+%Y%m%d_%H%M%S')"
    
    # Normalisiere Dateinamen (entferne ungültige Zeichen)
    disc_label=$(sanitize_filename "$label")
}
