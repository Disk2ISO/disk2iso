#!/bin/bash
################################################################################
# DVD Library - Combined DVD Functions
# Filepath: disk2iso-lib/lib-dvd.sh
#
# Beschreibung:
#   Zusammenfassung aller DVD-bezogenen Funktionen:
#   - DVD-Video Erkennung (detect_dvd_video)
#   - DVD-ROM Erkennung (detect_dvd_rom)
#   - DVD-Video Kopieren (copy_dvd_video)
#
# Komponenten:
#   - Detection: Erkennt Video-DVDs und Daten-DVDs
#   - Copy: Kopiert Video-DVDs mit dvdbackup + mkisofs
#
################################################################################

# ============================================================================
# DVD-VIDEO DETECTION
# Quelle: detection/dvd-video.sh
# ============================================================================

# Funktion zum Erkennen von Video-DVDs
# Nutzt isoinfo und Mount-Tests zur Verifikation der VIDEO_TS Struktur
#
# Rückgabe:
#   0 = DVD-Video erkannt
#   1 = Kein ISO9660/UDF Dateisystem
#   2 = Typ nicht erkannt (kein VIDEO_TS gefunden)
detect_dvd_video() {
    log_message "[DVD-Video] Starte Erkennung..."
    
    # Test 1: Prüfe mit isoinfo auf VIDEO_TS Verzeichnis (schnellste Methode ohne Mount)
    if command -v isoinfo >/dev/null 2>&1; then
        local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
        
        if echo "$iso_content" | grep -qi "VIDEO_TS"; then
            log_message "[DVD-Video] ✓ VIDEO_TS Verzeichnis via isoinfo gefunden"
            
            # Setze globale Variablen
            disc_type="video-dvd"
            get_disc_label "$disc_type"
            
            return 0
        fi
        
        log_message "[DVD-Video] Kein VIDEO_TS Verzeichnis via isoinfo"
    fi
    
    # Test 2: Versuche Mount und prüfe Verzeichnisstruktur (wenn isoinfo fehlschlägt)
    local temp_mount=$(get_tmp_mount)
    
    if mount -o ro "$CD_DEVICE" "$temp_mount" 2>/dev/null; then
        # Prüfe auf VIDEO_TS (case-insensitive)
        if [[ -d "$temp_mount/VIDEO_TS" ]] || [[ -d "$temp_mount/video_ts" ]]; then
            log_message "[DVD-Video] ✓ VIDEO_TS Verzeichnis via Mount gefunden"
            
            # Setze globale Variablen
            disc_type="video-dvd"
            get_disc_label "$disc_type"
            
            umount "$temp_mount" 2>/dev/null
            rmdir "$temp_mount" 2>/dev/null
            return 0
        fi
        
        umount "$temp_mount" 2>/dev/null
        log_message "[DVD-Video] Kein VIDEO_TS Verzeichnis nach Mount"
    else
        log_message "[DVD-Video] Mount fehlgeschlagen"
    fi
    
    rmdir "$temp_mount" 2>/dev/null
    
    # Test 3: Prüfe auf ISO9660 oder UDF Dateisystem (schwächster Test, nur als finale Prüfung)
    local fs_type=$(blkid -s TYPE -o value "$CD_DEVICE" 2>/dev/null)
    if [[ "$fs_type" != "iso9660" ]] && [[ "$fs_type" != "udf" ]]; then
        log_message "[DVD-Video] Kein ISO9660/UDF Dateisystem"
        return 1
    fi
    
    log_message "[DVD-Video] Keine Video-DVD erkannt (kein VIDEO_TS)"
    return 2
}

# ============================================================================
# DVD-ROM DETECTION
# Quelle: detection/dvd-rom.sh
# ============================================================================

# Funktion zum Erkennen von Daten-DVDs (DVD-ROM)
# Unterscheidet von CDs durch Größe und schließt Video-DVDs aus
#
# Rückgabe:
#   0 = DVD-ROM erkannt
#   1 = Kein ISO9660/UDF Dateisystem
#   2 = Typ nicht erkannt (zu klein/groß oder VIDEO_TS gefunden)
detect_dvd_rom() {
    log_message "[DVD-ROM] Starte Erkennung..."
    
    # Test 1: Prüfe auf ISO9660 oder UDF Dateisystem
    local fs_type=$(blkid -s TYPE -o value "$CD_DEVICE" 2>/dev/null)
    if [[ "$fs_type" != "iso9660" ]] && [[ "$fs_type" != "udf" ]]; then
        log_message "[DVD-ROM] Kein ISO9660/UDF Dateisystem (ist: $fs_type)"
        return 1
    fi
    
    log_message "[DVD-ROM] ✓ ISO9660/UDF Dateisystem erkannt"
    
    # Test 2: Prüfe Größe (DVD min ~800MB, max ~9GB für Dual Layer)
    if command -v blockdev >/dev/null 2>&1; then
        local size=$(blockdev --getsize64 "$CD_DEVICE" 2>/dev/null)
        local cd_max_size=$((800 * 1024 * 1024))
        local dvd_max_size=$((9 * 1024 * 1024 * 1024))  # Dual Layer ~8.5GB + Reserve
        
        if [[ -n "$size" ]]; then
            if [[ $size -lt $cd_max_size ]]; then
                log_message "[DVD-ROM] Größe $size Bytes < 800MB, wahrscheinlich CD"
                return 2
            fi
            
            if [[ $size -gt $dvd_max_size ]]; then
                log_message "[DVD-ROM] Größe $size Bytes > 9GB, wahrscheinlich Blu-ray"
                return 2
            fi
            
            log_message "[DVD-ROM] ✓ Größe im DVD-Bereich: $(( size / 1024 / 1024 ))MB"
            
            # Test 2a: Schließe Video-DVD aus (VIDEO_TS Verzeichnis)
            if command -v isoinfo >/dev/null 2>&1; then
                local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
                if echo "$iso_content" | grep -qi "VIDEO_TS"; then
                    log_message "[DVD-ROM] VIDEO_TS gefunden, ist Video-DVD"
                    return 2
                fi
            fi
            
            log_message "[DVD-ROM] ✓ Daten-DVD erkannt (Größe: $(( size / 1024 / 1024 ))MB)"
            
            # Setze globale Variablen
            disc_type="dvd-rom"
            get_disc_label "$disc_type"
            
            return 0
        fi
    fi
    
    # Test 3: Größe unbekannt - prüfe trotzdem auf VIDEO_TS und akzeptiere als DVD-ROM wenn nicht vorhanden
    if command -v isoinfo >/dev/null 2>&1; then
        local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
        if echo "$iso_content" | grep -qi "VIDEO_TS"; then
            log_message "[DVD-ROM] VIDEO_TS gefunden, ist Video-DVD"
            return 2
        fi
    fi
    
    # Fallback: ISO9660/UDF vorhanden, kein VIDEO_TS, Größe unbekannt → akzeptiere als DVD-ROM
    log_message "[DVD-ROM] ✓ Daten-DVD erkannt (Größe unbekannt)"
    
    # Setze globale Variablen
    disc_type="dvd-rom"
    get_disc_label "$disc_type"
    
    return 0
}

# ============================================================================
# DVD-VIDEO COPY
# Quelle: copy/dvd-video.sh
# ============================================================================

# Funktion zum Kopieren von Video-DVDs mit dvdbackup + mkisofs
# Erhält DVD-Struktur inkl. VIDEO_TS und AUDIO_TS Ordner
#
# Rückgabe:
#   0 = Kopieren erfolgreich
#   1 = Kopieren fehlgeschlagen
copy_dvd_video() {
    log_message "Verwende dvdbackup + mkisofs für Video-DVD..."
    
    # Nutze globales temp_pathname statt lokales temp_dir
    # Extrahiere DVD-Struktur (dvdbackup hat eigene Fortschrittsanzeige)
    if dvdbackup -i "$CD_DEVICE" -o "$temp_pathname" -M 2>&1 | tee -a "$log_filename"; then
        log_message "DVD-Struktur extrahiert"
        
        # Finde DVD-Verzeichnis
        local dvd_dir=$(find "$temp_pathname" -maxdepth 1 -type d ! -path "$temp_pathname" | head -n 1)
        
        if [[ -n "$dvd_dir" ]]; then
            # Erstelle ISO mit mkisofs oder genisoimage
            local mkiso_cmd=$(get_mkisofs_command)
            
            if [[ -n "$mkiso_cmd" ]]; then
                # Ermittle Block Size
                read block_size volume_size < <(get_disc_block_info)
                
                # mkisofs mit pv für Fortschrittsanzeige (falls verfügbar)
                if [[ -t 0 ]] && command -v pv >/dev/null 2>&1; then
                    local dir_size=$(du -sb "$dvd_dir" | cut -f1)
                    if $mkiso_cmd -dvd-video -udf -V "$disk_label" -o - "$dvd_dir" 2>>"$log_filename" | pv -s "$dir_size" | dd of="$iso_filename" bs="$block_size" 2>>"$log_filename"; then
                        log_message "ISO erfolgreich erstellt mit $mkiso_cmd"
                        return 0
                    fi
                else
                    # Ohne pv
                    if $mkiso_cmd -dvd-video -udf -V "$disk_label" -o "$iso_filename" "$dvd_dir" 2>>"$log_filename"; then
                        log_message "ISO erfolgreich erstellt mit $mkiso_cmd"
                        return 0
                    fi
                fi
            fi
        fi
    fi
    
    log_message "dvdbackup + mkisofs fehlgeschlagen"
    return 1
}

# ============================================================================
# ENDE DER DVD LIBRARY
# ============================================================================
