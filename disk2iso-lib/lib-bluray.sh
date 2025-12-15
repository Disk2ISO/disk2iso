#!/bin/bash
################################################################################
# Blu-ray Library - Combined Blu-ray Functions
# Filepath: disk2iso-lib/lib-bluray.sh
#
# Beschreibung:
#   Zusammenfassung aller Blu-ray-bezogenen Funktionen:
#   - BD-Video Erkennung (detect_bd_video)
#   - BD-ROM Erkennung (detect_bd_rom)
#   - BD-Video Kopieren (copy_bluray_video)
#
# Komponenten:
#   - Detection: Erkennt Video-Blu-rays und Daten-Blu-rays
#   - Copy: Kopiert Video-Blu-rays mit MakeMKV
#
################################################################################

# ============================================================================
# BD-VIDEO DETECTION
# Quelle: detection/bd-video.sh
# ============================================================================

# Funktion zum Erkennen von Video-Blu-rays
# Nutzt Mount-Tests und isoinfo zur Verifikation der BDMV/BDAV Struktur
#
# Rückgabe:
#   0 = BD-Video erkannt
#   1 = Kein UDF Dateisystem/Blu-ray-Kennzeichen
#   2 = Typ nicht erkannt (kein BDMV/BDAV gefunden)
detect_bd_video() {
    log_message "[BD-Video] Starte Erkennung..."
    
    # Test 1: Versuche Mount und prüfe auf BDMV/BDAV Verzeichnis (schnellster und zuverlässigster Test)
    local temp_mount=$(get_tmp_mount)
    
    if mount -o ro "$CD_DEVICE" "$temp_mount" 2>/dev/null; then
        # BDMV = Blu-ray Disc Movie (Standard)
        # BDAV = Blu-ray Disc Audio/Visual (aufgenommene Inhalte)
        if [[ -d "$temp_mount/BDMV" ]] || [[ -d "$temp_mount/BDAV" ]]; then
            log_message "[BD-Video] ✓ BDMV/BDAV Verzeichnis via Mount gefunden"
            
            # Setze globale Variablen
            disc_type="video-bluray"
            get_disc_label "$disc_type"
            
            umount "$temp_mount" 2>/dev/null
            rmdir "$temp_mount" 2>/dev/null
            return 0
        fi
        
        umount "$temp_mount" 2>/dev/null
        log_message "[BD-Video] Kein BDMV/BDAV Verzeichnis nach Mount"
    else
        log_message "[BD-Video] Mount fehlgeschlagen, versuche alternative Methoden..."
    fi
    
    rmdir "$temp_mount" 2>/dev/null
    
    # Test 2: Fallback mit isoinfo -l (wenn Mount nicht möglich, aber Tool verfügbar)
    if command -v isoinfo >/dev/null 2>&1; then
        local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
        
        if echo "$iso_content" | grep -q "BDMV\|BDAV"; then
            log_message "[BD-Video] ✓ BDMV/BDAV via isoinfo gefunden"
            
            # Setze globale Variablen
            disc_type="video-bluray"
            get_disc_label "$disc_type"
            
            return 0
        fi
        
        log_message "[BD-Video] Kein BDMV/BDAV via isoinfo"
    fi
    
    # Test 3: Prüfe auf UDF Dateisystem oder "NOT in ISO 9660 format" (schwächster Test, nur als letzter Hinweis)
    local fs_type=$(blkid -s TYPE -o value "$CD_DEVICE" 2>/dev/null)
    local isoinfo_output=""
    
    if command -v isoinfo >/dev/null 2>&1; then
        isoinfo_output=$(isoinfo -d -i "$CD_DEVICE" 2>&1)
    fi
    
    # Blu-ray Kandidat wenn UDF oder "NOT in ISO 9660"
    if [[ "$fs_type" == "udf" ]] || echo "$isoinfo_output" | grep -qi "NOT in ISO 9660 format"; then
        log_message "[BD-Video] Blu-ray Dateisystem erkannt, aber keine Video-Struktur gefunden"
        return 2
    else
        log_message "[BD-Video] Kein UDF oder Blu-ray-Kennzeichen"
        return 1
    fi
}

# ============================================================================
# BD-ROM DETECTION
# Quelle: detection/bd-rom.sh
# ============================================================================

# Funktion zum Erkennen von Daten-Blu-rays (BD-ROM)
# Schließt Video-Blu-rays (BDMV/BDAV Struktur) aus
#
# Rückgabe:
#   0 = BD-ROM erkannt
#   1 = Kein UDF Dateisystem/Blu-ray-Kennzeichen
#   2 = Typ nicht erkannt (BDMV/BDAV gefunden oder zu klein)
detect_bd_rom() {
    log_message "[BD-ROM] Starte Erkennung..."
    
    # Test 1: Prüfe auf UDF Dateisystem (Blu-rays nutzen typisch UDF 2.5+)
    local fs_type=$(blkid -s TYPE -o value "$CD_DEVICE" 2>/dev/null)
    
    if [[ "$fs_type" == "udf" ]]; then
        log_message "[BD-ROM] ✓ UDF Dateisystem erkannt"
        
        # Test 1a: Schließe Video-Blu-ray sofort aus (BDMV/BDAV via Mount)
        local temp_mount=$(get_tmp_mount)
        
        if mount -o ro "$CD_DEVICE" "$temp_mount" 2>/dev/null; then
            if [[ -d "$temp_mount/BDMV" ]] || [[ -d "$temp_mount/BDAV" ]]; then
                log_message "[BD-ROM] BDMV/BDAV gefunden, ist Video-Blu-ray"
                umount "$temp_mount" 2>/dev/null
                rmdir "$temp_mount" 2>/dev/null
                return 2
            fi
            umount "$temp_mount" 2>/dev/null
            
            # Kein BDMV/BDAV → Daten-Blu-ray
            log_message "[BD-ROM] ✓ Daten-Blu-ray erkannt (UDF ohne Video-Struktur)"
            
            # Setze globale Variablen
            disc_type="data-bluray"
            get_disc_label "$disc_type"
            
            rmdir "$temp_mount" 2>/dev/null
            return 0
        fi
        
        rmdir "$temp_mount" 2>/dev/null
        
        # Mount fehlgeschlagen, prüfe mit isoinfo
        if command -v isoinfo >/dev/null 2>&1; then
            local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
            if echo "$iso_content" | grep -q "BDMV\|BDAV"; then
                log_message "[BD-ROM] BDMV/BDAV via isoinfo gefunden, ist Video-Blu-ray"
                return 2
            fi
        fi
        
        # UDF vorhanden, kein BDMV/BDAV → Daten-Blu-ray
        log_message "[BD-ROM] ✓ Daten-Blu-ray erkannt (UDF ohne Video-Struktur)"
        
        # Setze globale Variablen
        disc_type="data-bluray"
        get_disc_label "$disc_type"
        
        return 0
    fi
    
    # Test 2: Fallback für Blu-rays ohne UDF-Erkennung via isoinfo
    if command -v isoinfo >/dev/null 2>&1; then
        local isoinfo_output=$(isoinfo -d -i "$CD_DEVICE" 2>&1)
        
        if echo "$isoinfo_output" | grep -qi "NOT in ISO 9660 format"; then
            log_message "[BD-ROM] Kein ISO9660, wahrscheinlich UDF Blu-ray"
            
            # Schließe Video-Blu-ray aus
            local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
            if echo "$iso_content" | grep -q "BDMV\|BDAV"; then
                log_message "[BD-ROM] BDMV/BDAV via isoinfo gefunden, ist Video-Blu-ray"
                return 2
            fi
            
            # Test 2a: Prüfe Größe zur Bestätigung
            if command -v blockdev >/dev/null 2>&1; then
                local size=$(blockdev --getsize64 "$CD_DEVICE" 2>/dev/null)
                local bd_min_size=$((9 * 1024 * 1024 * 1024))   # 9GB Grenze
                
                if [[ -n "$size" ]] && [[ $size -ge $bd_min_size ]]; then
                    log_message "[BD-ROM] ✓ Daten-Blu-ray erkannt (Größe: $(( size / 1024 / 1024 / 1024 ))GB)"
                    
                    # Setze globale Variablen
                    disc_type="data-bluray"
                    get_disc_label "$disc_type"
                    
                    return 0
                elif [[ -n "$size" ]]; then
                    log_message "[BD-ROM] Größe $size Bytes < 9GB, wahrscheinlich DVD"
                    return 2
                fi
            fi
            
            # Größe unbekannt, aber Blu-ray-Kennzeichen vorhanden
            log_message "[BD-ROM] ✓ Daten-Blu-ray erkannt (Größe unbekannt)"
            
            # Setze globale Variablen
            disc_type="data-bluray"
            get_disc_label "$disc_type"
            
            return 0
        fi
    fi
    
    log_message "[BD-ROM] Kein UDF Dateisystem oder Blu-ray-Kennzeichen"
    log_message "[BD-ROM] Keine Daten-Blu-ray erkannt"
    return 1
}

# ============================================================================
# BD-VIDEO COPY
# Quelle: copy/bluray-video.sh
# ============================================================================

# Funktion zum Kopieren von Video-Blu-rays mit MakeMKV
# Erstellt entschlüsseltes ISO-Backup mit BDMV/BDAV-Struktur
#
# Rückgabe:
#   0 = Kopieren erfolgreich
#   1 = Kopieren fehlgeschlagen
copy_bluray_video() {
    log_message "Starte Blu-ray Video ISO-Backup..."
    
    # Prüfe ob makemkvcon verfügbar ist
    if ! command -v makemkvcon >/dev/null 2>&1; then
        log_message "FEHLER: makemkvcon nicht verfügbar - kann Video-Blu-ray nicht verarbeiten"
        return 1
    fi
    
    # Erstelle temporäres Verzeichnis
    if ! get_album_folder "$temp_pathname"; then
        log_message "FEHLER: Konnte temporäres Verzeichnis nicht erstellen: $temp_pathname"
        return 1
    fi
    
    log_message "Erstelle entschlüsseltes Backup im BDMV-Format..."
    
    # Erstelle Backup-Ordner
    local backup_dir="${OUTPUT_DIR}/${disc_label}_BACKUP"
    if ! get_bd_backup_folder "$backup_dir"; then
        return 1
    fi
    
    # Erstelle Backup mit MakeMKV
    if makemkvcon backup --decrypt disc:0 "$backup_dir" 2>&1 | tee -a "$log_filename"; then
        log_message "MakeMKV Backup erfolgreich erstellt: $backup_dir"
        
        # Optional: Konvertiere zu ISO mit genisoimage/mkisofs
        local mkiso_cmd=$(get_mkisofs_command)
        if [[ -n "$mkiso_cmd" ]]; then
            log_message "Erstelle ISO aus Backup-Ordner..."
            
            if $mkiso_cmd -udf -iso-level 3 -o "$iso_filename" "$backup_dir" 2>&1 | tee -a "$log_filename"; then
                log_message "ISO erfolgreich erstellt: $iso_filename"
                
                # Lösche Backup-Ordner nach erfolgreicher ISO-Erstellung
                rm -rf "$backup_dir"
                
                return 0
            else
                log_message "WARNUNG: ISO-Erstellung fehlgeschlagen, Backup-Ordner bleibt erhalten"
                return 0  # Backup ist trotzdem erfolgreich
            fi
        else
            log_message "ISO-Tools nicht verfügbar, Backup als Ordner-Struktur gesichert"
            return 0
        fi
    else
        log_message "FEHLER: MakeMKV Backup fehlgeschlagen"
        rm -rf "$backup_dir"
        return 1
    fi
}

# ============================================================================
# ENDE DER BLU-RAY LIBRARY
# ============================================================================
