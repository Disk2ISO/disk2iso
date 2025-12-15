#!/bin/bash
################################################################################
# CD Library - Combined CD Functions
# Filepath: disk2iso-lib/lib-cd.sh
#
# Beschreibung:
#   Zusammenfassung aller CD-bezogenen Funktionen:
#   - CD-Audio Erkennung (detect_cd_audio)
#   - CD-ROM Erkennung (detect_cd_rom)
#   - CD-Audio Kopieren mit Metadaten-Lookup (copy_audio_cd)
#
# Komponenten:
#   - Detection: Erkennt Audio-CDs und Daten-CDs
#   - Copy: Rippt Audio-CDs zu MP3 mit MusicBrainz/CD-TEXT Metadaten
#   - Metadata: MusicBrainz und CD-TEXT Lookup für Album-Informationen
#
################################################################################

# ============================================================================
# CD-AUDIO DETECTION
# Quelle: detection/cd-audio.sh
# ============================================================================

# Funktion zum Erkennen von Audio-CDs
# Nutzt cdparanoia zur Track-Erkennung ohne Dateisystem
#
# Rückgabe:
#   0 = Audio-CD erkannt
#   1 = Kein Medium/Disc-Fehler
#   2 = Typ nicht erkannt (hat Dateisystem, keine Audio-CD)
#   3 = Benötigtes Tool (cdparanoia) nicht verfügbar
detect_cd_audio() {
    log_message "[CD-Audio] Starte Erkennung..."
    
    # Prüfe ob cdparanoia verfügbar ist
    if ! command -v cdparanoia >/dev/null 2>&1; then
        log_message "[CD-Audio] cdparanoia nicht verfügbar, überspringe Test"
        return 3
    fi
    
    # Test 1: Prüfe mit cdparanoia auf Audio-Tracks (direktester Test für Audio-CD)
    local cdparanoia_output=$(cdparanoia -d "$CD_DEVICE" -Q 2>&1)
    
    # Prüfe auf Fehler-Meldungen
    if echo "$cdparanoia_output" | grep -qi "Unable to open disc"; then
        log_message "[CD-Audio] cdparanoia kann Disc nicht öffnen"
        return 1
    fi
    
    if echo "$cdparanoia_output" | grep -qi "Unable to read table of contents"; then
        log_message "[CD-Audio] cdparanoia kann TOC nicht lesen"
        return 1
    fi
    
    # Echte Tracks haben Format: "  1.  12345 [02:44.20]" (mit Punkt nach Tracknummer)
    if echo "$cdparanoia_output" | grep -q "^[[:space:]]*[0-9]\+\."; then
        local track_count=$(echo "$cdparanoia_output" | grep -c "^[[:space:]]*[0-9]\+\.")
        log_message "[CD-Audio] ✓ Audio-CD erkannt mit $track_count Tracks"
        
        # Setze globale Variablen
        disc_type="audio-cd"
        get_disc_label "$disc_type"
        
        return 0
    fi
    
    log_message "[CD-Audio] Keine Audio-Tracks gefunden"
    
    # Test 2: Zusätzliche Validierung - Audio-CDs haben typisch KEIN Dateisystem
    if blkid "$CD_DEVICE" 2>/dev/null | grep -q "TYPE"; then
        log_message "[CD-Audio] Dateisystem erkannt, bestätigt keine Audio-CD"
        return 2
    fi
    
    return 1
}

# ============================================================================
# CD-ROM DETECTION
# Quelle: detection/cd-rom.sh
# ============================================================================

# Funktion zum Erkennen von Daten-CDs (CD-ROM)
# Unterscheidet von DVDs durch Größe (<800MB)
#
# Rückgabe:
#   0 = CD-ROM erkannt
#   1 = Kein ISO9660 Dateisystem
#   2 = Typ nicht erkannt (zu groß für CD oder VIDEO_TS gefunden)
detect_cd_rom() {
    log_message "[CD-ROM] Starte Erkennung..."
    
    # Test 1: Prüfe auf ISO9660 Dateisystem
    if ! blkid "$CD_DEVICE" 2>/dev/null | grep -q "TYPE=\"iso9660\""; then
        log_message "[CD-ROM] Kein ISO9660 Dateisystem"
        return 1
    fi
    
    log_message "[CD-ROM] ✓ ISO9660 Dateisystem erkannt"
    
    # Test 2: Unterscheide CD vs DVD anhand Größe (CD max ~737MB, schnellster Ausschlusstest)
    if command -v blockdev >/dev/null 2>&1; then
        local size=$(blockdev --getsize64 "$CD_DEVICE" 2>/dev/null)
        # 800 MB Grenze (CD max ~700MB + Reserve)
        local cd_max_size=$((800 * 1024 * 1024))
        
        if [[ -n "$size" ]]; then
            if [[ $size -gt $cd_max_size ]]; then
                log_message "[CD-ROM] Größe $size Bytes > 800MB, wahrscheinlich DVD"
                return 2
            fi
            
            log_message "[CD-ROM] ✓ Größe im CD-Bereich: $(( size / 1024 / 1024 ))MB"
            
            # Test 2a: Schließe Video-DVD aus (VIDEO_TS würde auf fehlerhafte Größenerkennung hindeuten)
            if command -v isoinfo >/dev/null 2>&1; then
                local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
                if echo "$iso_content" | grep -qi "VIDEO_TS"; then
                    log_message "[CD-ROM] VIDEO_TS gefunden, ist Video-DVD"
                    return 2
                fi
            fi
            
            log_message "[CD-ROM] ✓ Daten-CD erkannt (Größe: $(( size / 1024 / 1024 ))MB)"
            
            # Setze globale Variablen
            disc_type="cd-rom"
            get_disc_label "$disc_type"
            
            return 0
        fi
    fi
    
    # Test 3: Größe unbekannt - prüfe Blockgröße (CD = 2048 Bytes)
    if command -v isoinfo >/dev/null 2>&1; then
        local iso_info=$(isoinfo -d -i "$CD_DEVICE" 2>/dev/null)
        local block_size=$(echo "$iso_info" | grep -i "Logical block size" | grep -oE '[0-9]+')
        
        if [[ -n "$block_size" ]] && [[ $block_size -ne 2048 ]]; then
            log_message "[CD-ROM] Blockgröße $block_size ≠ 2048, keine Standard-CD"
            return 2
        fi
        
        # Test 3a: Schließe Video-DVD aus
        local iso_content=$(isoinfo -l -i "$CD_DEVICE" 2>/dev/null)
        if echo "$iso_content" | grep -qi "VIDEO_TS"; then
            log_message "[CD-ROM] VIDEO_TS gefunden, ist Video-DVD"
            return 2
        fi
    fi
    
    # Fallback: ISO9660 vorhanden, Größe/Blockgröße unbekannt oder passend
    log_message "[CD-ROM] ✓ Daten-CD erkannt (Größe unbekannt)"
    
    # Setze globale Variablen
    disc_type="cd-rom"
    get_disc_label "$disc_type"
    
    return 0
}

# ============================================================================
# AUDIO-CD METADATA LOOKUP
# Quelle: copy/audio.sh (Hilfsfunktionen)
# ============================================================================

# MusicBrainz Metadaten-Lookup
# Parameter: $1 = CD_DEVICE (z.B. /dev/sr0)
# Setzt globale Variablen: ALBUM_ARTIST, ALBUM_TITLE, ALBUM_YEAR, ALBUM_GENRE, TRACK_TITLES[@], RELEASE_ID
#
# Rückgabe:
#   0 = Metadaten erfolgreich abgerufen
#   1 = Fehler oder keine Daten verfügbar
lookup_musicbrainz() {
    local device="$1"
    
    # Initialisiere globale Variablen
    ALBUM_ARTIST=""
    ALBUM_TITLE=""
    ALBUM_YEAR=""
    ALBUM_GENRE=""
    RELEASE_ID=""
    TRACK_TITLES=()
    
    if [[ "$AUDIO_USE_MUSICBRAINZ" != "true" ]]; then
        log_message "MusicBrainz Lookup deaktiviert (AUDIO_USE_MUSICBRAINZ=$AUDIO_USE_MUSICBRAINZ)"
        return 1
    fi
    
    if ! command -v cd-discid >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        log_message "MusicBrainz Lookup: Fehlende Tools (cd-discid, curl, jq)"
        return 1
    fi
    
    log_message "MusicBrainz Lookup wird durchgeführt..."
    
    # Berechne Disc-ID
    local discid_output
    if ! discid_output=$(cd-discid "$device" 2>/dev/null); then
        log_message "FEHLER: cd-discid konnte Disc-ID nicht berechnen"
        return 1
    fi
    
    # Format: DISCID TRACKS OFFSET1 OFFSET2 ... LENGTH
    local discid=$(echo "$discid_output" | awk '{print $1}')
    
    if [[ -z "$discid" ]]; then
        log_message "FEHLER: Ungültige Disc-ID"
        return 1
    fi
    
    log_message "Disc-ID: $discid"
    
    # MusicBrainz API Anfrage (Rate-Limiting: 1 Request/Sekunde)
    local api_url="https://musicbrainz.org/ws/2/discid/${discid}?fmt=json&inc=recordings+artists+release-groups"
    local response
    
    if ! response=$(curl -s -A "auto-cd-ripper/1.0 (dirk@example.com)" "$api_url" 2>/dev/null); then
        log_message "FEHLER: MusicBrainz API Anfrage fehlgeschlagen"
        return 1
    fi
    
    # Rate-Limiting respektieren
    sleep 1
    
    # Parse JSON Response
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local error_msg=$(echo "$response" | jq -r '.error // "Unknown error"')
        log_message "MusicBrainz: Keine Metadaten gefunden ($error_msg)"
        return 1
    fi
    
    # Extrahiere Release-Informationen (erster Release)
    RELEASE_ID=$(echo "$response" | jq -r '.releases[0].id // ""')
    ALBUM_TITLE=$(echo "$response" | jq -r '.releases[0].title // ""')
    ALBUM_ARTIST=$(echo "$response" | jq -r '.releases[0]["artist-credit"][0].artist.name // ""')
    ALBUM_YEAR=$(echo "$response" | jq -r '.releases[0].date // ""' | cut -d'-' -f1)
    
    # Extrahiere Track-Titel
    local track_count=$(echo "$response" | jq -r '.releases[0].media[0].tracks | length')
    local i
    for ((i=0; i<track_count; i++)); do
        local track_title=$(echo "$response" | jq -r ".releases[0].media[0].tracks[$i].recording.title // \"\"")
        TRACK_TITLES+=("$track_title")
    done
    
    if [[ -z "$ALBUM_ARTIST" ]] || [[ -z "$ALBUM_TITLE" ]] || [[ ${#TRACK_TITLES[@]} -eq 0 ]]; then
        log_message "MusicBrainz: Unvollständige Metadaten"
        return 1
    fi
    
    log_message "✓ Album: $ALBUM_ARTIST - $ALBUM_TITLE ($ALBUM_YEAR)"
    log_message "✓ Tracks: ${#TRACK_TITLES[@]}"
    
    return 0
}

# CD-TEXT Metadaten auslesen
# Parameter: $1 = CD_DEVICE (z.B. /dev/sr0)
# Setzt globale Variablen: CDTEXT_ALBUM, CDTEXT_ARTIST, CDTEXT_TITLES[@]
#
# Rückgabe:
#   0 = CD-TEXT erfolgreich ausgelesen
#   1 = Fehler oder keine CD-TEXT Daten verfügbar
get_cdtext_info() {
    local device="$1"
    
    # Initialisiere globale Variablen
    CDTEXT_ALBUM=""
    CDTEXT_ARTIST=""
    CDTEXT_TITLES=()
    
    if [[ "$AUDIO_USE_CDTEXT" != "true" ]]; then
        log_message "CD-TEXT Lookup deaktiviert (AUDIO_USE_CDTEXT=$AUDIO_USE_CDTEXT)"
        return 1
    fi
    
    if ! command -v cdrdao >/dev/null 2>&1; then
        log_message "CD-TEXT Lookup: cdrdao nicht installiert"
        return 1
    fi
    
    log_message "CD-TEXT Lookup wird durchgeführt..."
    
    # Lese CD-TEXT mit cdrdao
    local cdtext_output
    if ! cdtext_output=$(cdrdao read-cdtext --device "$device" 2>&1); then
        log_message "CD-TEXT: Keine Daten verfügbar"
        return 1
    fi
    
    # Parse CD-TEXT Output
    # Format: "TITLE \"...\"\n" "PERFORMER \"...\"\n"
    local in_disc_section=false
    local track_num=0
    
    while IFS= read -r line; do
        # Disc-Level Metadaten
        if [[ $line =~ ^CD_TEXT[[:space:]]*\{ ]]; then
            in_disc_section=true
        elif [[ $line =~ ^\} ]]; then
            in_disc_section=false
        elif [[ $in_disc_section == true ]]; then
            if [[ $line =~ TITLE[[:space:]]+\"([^\"]+)\" ]]; then
                CDTEXT_ALBUM="${BASH_REMATCH[1]}"
            elif [[ $line =~ PERFORMER[[:space:]]+\"([^\"]+)\" ]]; then
                CDTEXT_ARTIST="${BASH_REMATCH[1]}"
            fi
        fi
        
        # Track-Level Metadaten
        if [[ $line =~ ^TRACK[[:space:]]+AUDIO ]]; then
            ((track_num++))
        elif [[ $track_num -gt 0 ]] && [[ $line =~ TITLE[[:space:]]+\"([^\"]+)\" ]]; then
            CDTEXT_TITLES+=("${BASH_REMATCH[1]}")
        fi
    done <<< "$cdtext_output"
    
    if [[ -z "$CDTEXT_ALBUM" ]] && [[ -z "$CDTEXT_ARTIST" ]] && [[ ${#CDTEXT_TITLES[@]} -eq 0 ]]; then
        log_message "CD-TEXT: Keine Metadaten gefunden"
        return 1
    fi
    
    log_message "✓ CD-TEXT: $CDTEXT_ARTIST - $CDTEXT_ALBUM"
    log_message "✓ CD-TEXT Tracks: ${#CDTEXT_TITLES[@]}"
    
    return 0
}

# Album-Cover herunterladen von CoverArtArchive
# Parameter: $1 = MusicBrainz Release-ID, $2 = Zielverzeichnis
#
# Rückgabe:
#   0 = Cover erfolgreich heruntergeladen
#   1 = Fehler oder Download fehlgeschlagen
download_album_cover() {
    local release_id="$1"
    local target_dir="$2"
    local cover_file="${target_dir}/folder.jpg"
    
    if [[ "$AUDIO_DOWNLOAD_COVER" != "true" ]]; then
        log_message "Album-Cover Download deaktiviert (AUDIO_DOWNLOAD_COVER=$AUDIO_DOWNLOAD_COVER)"
        return 1
    fi
    
    if [[ -z "$release_id" ]]; then
        log_message "Album-Cover: Keine Release-ID verfügbar"
        return 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        log_message "Album-Cover: curl nicht verfügbar"
        return 1
    fi
    
    log_message "Album-Cover wird heruntergeladen..."
    
    # CoverArtArchive API
    local cover_url="https://coverartarchive.org/release/${release_id}/front"
    
    if ! curl -s -L -f -o "$cover_file" "$cover_url" 2>/dev/null; then
        log_message "Album-Cover: Download fehlgeschlagen"
        return 1
    fi
    
    # Validiere Bild (mindestens 1KB)
    if [[ ! -f "$cover_file" ]] || [[ $(stat -c%s "$cover_file" 2>/dev/null || echo 0) -lt 1024 ]]; then
        log_message "Album-Cover: Ungültige Datei"
        rm -f "$cover_file"
        return 1
    fi
    
    log_message "✓ Album-Cover gespeichert: $cover_file"
    
    # Rate-Limiting respektieren
    sleep 1
    
    return 0
}

# ============================================================================
# AUDIO-CD COPY
# Quelle: copy/audio.sh
# ============================================================================

# Funktion zum Kopieren von Audio-CDs
# Rippt Audio-Tracks zu MP3 mit MusicBrainz/CD-TEXT Metadaten und Album-Cover
#
# Rückgabe:
#   0 = Audio-CD erfolgreich gerippt
#   1 = Fehler beim Rippen
copy_audio_cd() {
    log_message "Starte Audio-CD Ripping..."
    
    # Metadaten-Lookup durchführen
    local use_metadata=false
    local artist_name=""
    local album_name=""
    local album_year=""
    local release_id=""
    declare -a track_titles
    
    # 1. Priorität: MusicBrainz
    if lookup_musicbrainz "$CD_DEVICE"; then
        artist_name="$ALBUM_ARTIST"
        album_name="$ALBUM_TITLE"
        album_year="$ALBUM_YEAR"
        release_id="$RELEASE_ID"
        track_titles=("${TRACK_TITLES[@]}")
        use_metadata=true
        log_message "✓ MusicBrainz Metadaten verfügbar"
    # 2. Priorität: CD-TEXT
    elif get_cdtext_info "$CD_DEVICE"; then
        artist_name="$CDTEXT_ARTIST"
        album_name="$CDTEXT_ALBUM"
        track_titles=("${CDTEXT_TITLES[@]}")
        use_metadata=true
        log_message "✓ CD-TEXT Metadaten verfügbar"
    # 3. Fallback: Generische Benennung
    else
        log_message "⚠ Keine Metadaten verfügbar, verwende generische Benennung"
        artist_name="Unknown Artist"
        album_name="$disc_label"
    fi
    
    # Erstelle Album-Verzeichnis mit Künstler/Album-Namen
    local safe_artist=$(sanitize_filename "$artist_name")
    local safe_album=$(sanitize_filename "$album_name")
    local album_dirname="${safe_artist} - ${safe_album}"
    local album_dir="${OUTPUT_DIR}/${album_dirname}"
    
    if ! get_album_folder "$album_dir"; then
        log_message "FEHLER: Konnte Album-Verzeichnis nicht erstellen: $album_dir"
        return 1
    fi
    
    # Erstelle temporäres Verzeichnis für WAV-Dateien
    if ! get_album_folder "$temp_pathname"; then
        log_message "FEHLER: Konnte temporäres Verzeichnis nicht erstellen: $temp_pathname"
        return 1
    fi
    
    log_message "Album-Verzeichnis: $album_dir"
    log_message "Temporäres Verzeichnis: $temp_pathname"
    
    # Album-Cover herunterladen
    if [[ -n "$release_id" ]]; then
        download_album_cover "$release_id" "$album_dir"
    fi
    
    # Ermittle Anzahl der Tracks
    local track_info
    track_info=$(cdparanoia -d "$CD_DEVICE" -Q 2>&1)
    
    if [[ $? -ne 0 ]]; then
        log_message "FEHLER: cdparanoia konnte keine Track-Informationen lesen"
        return 1
    fi
    
    # Extrahiere Track-Nummern (Format: "  1." oder " 10.")
    local tracks=()
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]+([0-9]+)\. ]]; then
            tracks+=("${BASH_REMATCH[1]}")
        fi
    done <<< "$track_info"
    
    local total_tracks=${#tracks[@]}
    
    if [[ $total_tracks -eq 0 ]]; then
        log_message "FEHLER: Keine Audio-Tracks gefunden"
        return 1
    fi
    
    log_message "Gefundene Tracks: $total_tracks"
    
    # Verarbeite jeden Track
    local track_num
    local track_idx=0
    for track_num in "${tracks[@]}"; do
        local padded_track=$(printf "%02d" "$track_num")
        local wav_file="${temp_pathname}/track${padded_track}.wav"
        
        # Bestimme Track-Titel und Dateinamen
        local track_title=""
        if [[ $use_metadata == true ]] && [[ $track_idx -lt ${#track_titles[@]} ]]; then
            track_title="${track_titles[$track_idx]}"
        fi
        
        local mp3_filename
        if [[ -n "$track_title" ]]; then
            local safe_title=$(sanitize_filename "$track_title")
            mp3_filename="${padded_track} - ${safe_title}.mp3"
        else
            mp3_filename="track${padded_track}.mp3"
        fi
        
        local mp3_file="${album_dir}/${mp3_filename}"
        
        log_message "Rippe Track ${track_num}/${total_tracks}..."
        if [[ -n "$track_title" ]]; then
            log_message "  Titel: $track_title"
        fi
        
        # Rippe Track mit cdparanoia
        if ! cdparanoia -d "$CD_DEVICE" "$track_num" "$wav_file" 2>&1 | tee -a "$log_filename"; then
            log_message "WARNUNG: Fehler beim Rippen von Track $track_num"
            ((track_idx++))
            continue
        fi
        
        # Konvertiere zu MP3 mit lame
        log_message "Encodiere Track $track_num zu MP3..."
        local lame_quality="-${AUDIO_QUALITY}"
        
        if ! lame -h "$lame_quality" --quiet "$wav_file" "$mp3_file" 2>&1 | tee -a "$log_filename"; then
            log_message "WARNUNG: Fehler beim Encodieren von Track $track_num"
            rm -f "$wav_file"
            ((track_idx++))
            continue
        fi
        
        # Setze ID3-Tags mit vollständigen Metadaten
        if [[ $use_metadata == true ]]; then
            # Verwende eyeD3 wenn verfügbar (bessere Cover-Unterstützung)
            if command -v eyeD3 >/dev/null 2>&1; then
                local eyeD3_args=(
                    --artist "$artist_name"
                    --album "$album_name"
                    --title "${track_title:-Track $track_num}"
                    --track "$track_num"
                    --track-total "$total_tracks"
                )
                
                [[ -n "$album_year" ]] && eyeD3_args+=(--release-year "$album_year")
                
                # Cover einbetten wenn verfügbar
                local cover_file="${album_dir}/folder.jpg"
                if [[ -f "$cover_file" ]]; then
                    eyeD3_args+=(--add-image "${cover_file}:FRONT_COVER")
                fi
                
                eyeD3 "${eyeD3_args[@]}" "$mp3_file" >/dev/null 2>&1
                
            # Fallback auf mid3v2
            elif command -v mid3v2 >/dev/null 2>&1; then
                mid3v2 \
                    --artist "$artist_name" \
                    --album "$album_name" \
                    --song "${track_title:-Track $track_num}" \
                    --track "$track_num" \
                    ${album_year:+--year "$album_year"} \
                    "$mp3_file" 2>/dev/null
                
                # Cover einbetten mit mid3v2 (wenn verfügbar)
                local cover_file="${album_dir}/folder.jpg"
                if [[ -f "$cover_file" ]]; then
                    mid3v2 --picture "$cover_file" "$mp3_file" 2>/dev/null || true
                fi
            fi
        else
            # Minimale Tags für generische Benennung
            if command -v mid3v2 >/dev/null 2>&1; then
                mid3v2 --album "$album_name" --track "$track_num" "$mp3_file" 2>/dev/null
            fi
        fi
        
        # Lösche temporäre WAV-Datei
        rm -f "$wav_file"
        
        log_message "Track $track_num erfolgreich verarbeitet"
        ((track_idx++))
    done
    
    # Zusammenfassung
    log_message "Audio-CD erfolgreich gerippt: $album_dir"
    log_message "Gesamt: $total_tracks Tracks"
    
    if [[ $use_metadata == true ]]; then
        log_message "Metadaten: $artist_name - $album_name"
        [[ -n "$album_year" ]] && log_message "Jahr: $album_year"
        [[ -f "${album_dir}/folder.jpg" ]] && log_message "Cover: folder.jpg"
    fi
    
    return 0
}

# ============================================================================
# ENDE DER CD LIBRARY
# ============================================================================
