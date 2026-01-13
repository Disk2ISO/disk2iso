#!/bin/bash
################################################################################
# disk2iso v1.2.0 - DVD/Blu-ray Metadata Library
# Filepath: lib/lib-dvd-metadata.sh
#
# Beschreibung:
#   TMDB-Integration für automatische Film-Metadaten und Cover
#   - search_tmdb_movie() - Film in TMDB suchen
#   - search_tmdb_tv() - TV-Serie in TMDB suchen
#   - get_tmdb_movie_details() - Details zu Film abrufen
#   - get_tmdb_tv_season_details() - Details zu TV-Staffel abrufen
#   - download_tmdb_poster() - Poster herunterladen
#   - create_dvd_metadata() - .nfo und -thumb.jpg erstellen
#
# Version: 1.2.0
# Datum: 13.01.2026
################################################################################

# ============================================================================
# TMDB API CONFIGURATION
# ============================================================================

readonly TMDB_API_BASE_URL="https://api.themoviedb.org/3"
readonly TMDB_IMAGE_BASE_URL="https://image.tmdb.org/t/p/w500"

# ============================================================================
# TMDB API FUNCTIONS - MOVIES
# ============================================================================

# Funktion: Suche Film in TMDB API
# Parameter: $1 = Suchbegriff (Film-Titel)
# Rückgabe: JSON mit Suchergebnissen oder leerer String bei Fehler
search_tmdb_movie() {
    local query="$1"
    
    # Prüfe ob API-Key konfiguriert ist
    if [[ -z "$TMDB_API_KEY" ]]; then
        log_message "TMDB: API-Key nicht konfiguriert"
        return 1
    fi
    
    # URL-Encode des Suchbegriffs (Leerzeichen → %20)
    local encoded_query=$(echo "$query" | sed 's/ /%20/g')
    
    # API-Anfrage (language=de-DE für deutsche Titel)
    local url="${TMDB_API_BASE_URL}/search/movie?api_key=${TMDB_API_KEY}&language=de-DE&query=${encoded_query}&page=1"
    
    local response=$(curl -s -f "$url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        echo "$response"
        return 0
    else
        log_message "TMDB: Fehler bei der Film-Suche nach '$query'"
        return 1
    fi
}

# Funktion: Hole Details zu einem Film
# Parameter: $1 = TMDB Movie-ID
# Rückgabe: JSON mit Film-Details oder leerer String bei Fehler
get_tmdb_movie_details() {
    local movie_id="$1"
    
    if [[ -z "$TMDB_API_KEY" ]]; then
        return 1
    fi
    
    # API-Anfrage mit Credits (für Director)
    local url="${TMDB_API_BASE_URL}/movie/${movie_id}?api_key=${TMDB_API_KEY}&language=de-DE&append_to_response=credits"
    
    local response=$(curl -s -f "$url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        echo "$response"
        return 0
    else
        log_message "TMDB: Fehler beim Abrufen der Details für Movie-ID $movie_id"
        return 1
    fi
}

# ============================================================================
# TMDB API FUNCTIONS - TV SHOWS
# ============================================================================

# Funktion: Suche TV-Serie in TMDB API
# Parameter: $1 = Suchbegriff (Serien-Titel)
# Rückgabe: JSON mit Suchergebnissen oder leerer String bei Fehler
search_tmdb_tv() {
    local query="$1"
    
    if [[ -z "$TMDB_API_KEY" ]]; then
        log_message "TMDB: API-Key nicht konfiguriert"
        return 1
    fi
    
    local encoded_query=$(echo "$query" | sed 's/ /%20/g')
    local url="${TMDB_API_BASE_URL}/search/tv?api_key=${TMDB_API_KEY}&language=de-DE&query=${encoded_query}&page=1"
    
    local response=$(curl -s -f "$url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        echo "$response"
        return 0
    else
        log_message "TMDB: Fehler bei der TV-Suche nach '$query'"
        return 1
    fi
}

# Funktion: Hole Details zu einer TV-Staffel
# Parameter: $1 = TMDB TV-ID
#            $2 = Season-Nummer
# Rückgabe: JSON mit Season-Details oder leerer String bei Fehler
get_tmdb_tv_season_details() {
    local tv_id="$1"
    local season_number="$2"
    
    if [[ -z "$TMDB_API_KEY" ]]; then
        return 1
    fi
    
    local url="${TMDB_API_BASE_URL}/tv/${tv_id}/season/${season_number}?api_key=${TMDB_API_KEY}&language=de-DE"
    
    local response=$(curl -s -f "$url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        echo "$response"
        return 0
    else
        log_message "TMDB: Fehler beim Abrufen von TV-ID $tv_id Season $season_number"
        return 1
    fi
}

# ============================================================================
# COMMON FUNCTIONS
# ============================================================================

# Funktion: Lade Poster von TMDB herunter
# Parameter: $1 = Poster-Pfad (z.B. "/abc123.jpg")
#            $2 = Ziel-Dateiname (vollständiger Pfad)
# Rückgabe: 0 = Erfolg, 1 = Fehler
download_tmdb_poster() {
    local poster_path="$1"
    local output_file="$2"
    
    # Prüfe ob Poster-Pfad vorhanden
    if [[ -z "$poster_path" ]] || [[ "$poster_path" == "null" ]]; then
        log_message "TMDB: Kein Poster verfügbar"
        return 1
    fi
    
    local poster_url="${TMDB_IMAGE_BASE_URL}${poster_path}"
    
    # Lade Poster herunter
    if curl -s -f "$poster_url" -o "$output_file" 2>/dev/null; then
        log_message "TMDB: Poster heruntergeladen: $(basename "$output_file")"
        return 0
    else
        log_message "TMDB: Fehler beim Herunterladen des Posters"
        return 1
    fi
}

# ============================================================================
# WEB API WRAPPER FUNCTIONS (für Python Flask Integration)
# ============================================================================

# Funktion: TMDB Suche mit JSON-Return für Web-API
# Parameter: $1 = Suchbegriff (Film/Serien-Titel)
#            $2 = Media-Type ("movie" oder "tv")
# Rückgabe: JSON-String mit {"success": true/false, "results": [...]}
# Diese Funktion wird vom Python Web-Interface aufgerufen
search_tmdb_json() {
    local title="$1"
    local media_type="$2"
    
    # Validierung
    if [[ -z "$title" ]]; then
        echo '{"success": false, "message": "Titel erforderlich"}'
        return 1
    fi
    
    if [[ -z "$TMDB_API_KEY" ]]; then
        echo '{"success": false, "message": "TMDB API Key nicht konfiguriert"}'
        return 1
    fi
    
    # URL-Encode des Titels
    local encoded_title=$(echo "$title" | sed 's/ /%20/g' | sed 's/&/%26/g')
    
    # Wähle Endpoint basierend auf media_type
    local url
    if [[ "$media_type" == "tv" ]]; then
        url="${TMDB_API_BASE_URL}/search/tv?api_key=${TMDB_API_KEY}&language=de-DE&query=${encoded_title}&page=1"
    else
        url="${TMDB_API_BASE_URL}/search/movie?api_key=${TMDB_API_KEY}&language=de-DE&query=${encoded_title}&page=1"
    fi
    
    # API-Anfrage
    local response=$(curl -s -f "$url" 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
        echo '{"success": false, "message": "TMDB-Suche fehlgeschlagen"}'
        return 1
    fi
    
    # Formatiere Ergebnisse mit jq (max 10 Treffer)
    local results=$(echo "$response" | jq -c '[.results[:10] | .[] | {
        id: .id,
        title: (if .title then .title else .name end),
        year: ((if .release_date then .release_date else .first_air_date end) // "" | split("-")[0]),
        overview: (.overview // ""),
        poster_path: (.poster_path // ""),
        poster_url: (if .poster_path then ("https://image.tmdb.org/t/p/w200" + .poster_path) else null end)
    }]' 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ -z "$results" ]]; then
        echo '{"success": false, "message": "JSON-Formatierung fehlgeschlagen"}'
        return 1
    fi
    
    # Baue finale JSON-Response
    echo "{\"success\": true, \"results\": $results}"
    return 0
}

# ============================================================================
# METADATA CREATION
# ============================================================================

# Funktion: Erstelle .nfo Datei für DVD/Blu-ray
# Parameter: $1 = Ziel .nfo Datei
#            $2 = TMDB Movie Details (JSON)
#            $3 = Disc-Typ (dvd-video oder bd-video)
create_movie_nfo() {
    local nfo_file="$1"
    local movie_json="$2"
    local disc_type="$3"
    
    # Extrahiere Felder aus JSON
    local title=$(echo "$movie_json" | jq -r '.title // empty')
    local year=$(echo "$movie_json" | jq -r '.release_date // empty' | cut -d'-' -f1)
    local runtime=$(echo "$movie_json" | jq -r '.runtime // empty')
    local genres=$(echo "$movie_json" | jq -r '[.genres[].name] | join(", ") // empty')
    local overview=$(echo "$movie_json" | jq -r '.overview // empty')
    local rating=$(echo "$movie_json" | jq -r '.vote_average // empty')
    
    # Extrahiere Regisseur (erster Director aus Credits)
    local director=$(echo "$movie_json" | jq -r '.credits.crew[] | select(.job == "Director") | .name' | head -n1)
    
    # Fallback-Werte
    [[ -z "$title" ]] && title="Unknown Movie"
    [[ -z "$year" ]] && year="0000"
    [[ -z "$runtime" ]] && runtime="0"
    [[ -z "$genres" ]] && genres="Unknown"
    [[ -z "$director" ]] && director="Unknown"
    [[ -z "$rating" ]] && rating="0.0"
    
    # Erstelle .nfo Datei (KEY=VALUE Format wie bei Audio-CDs)
    {
        echo "TITLE=$title"
        echo "YEAR=$year"
        echo "DIRECTOR=$director"
        echo "GENRE=$genres"
        echo "RUNTIME=$runtime"
        echo "RATING=$rating"
        echo "TYPE=$disc_type"
        [[ -n "$overview" ]] && echo "OVERVIEW=$overview"
    } > "$nfo_file"
    
    log_message "Metadaten erstellt: $(basename "$nfo_file")"
}

# Funktion: Interaktive Film-Auswahl aus TMDB-Suchergebnissen
# Parameter: $1 = TMDB Suchergebnisse (JSON)
# Rückgabe: Movie-ID des ausgewählten Films oder leer bei Abbruch
select_tmdb_movie() {
    local search_results="$1"
    
    # Prüfe ob Ergebnisse vorhanden
    local result_count=$(echo "$search_results" | jq -r '.results | length')
    
    if [[ "$result_count" -eq 0 ]]; then
        log_message "TMDB: Keine Ergebnisse gefunden"
        return 1
    fi
    
    # Speichere Ergebnisse in API-Datei für Web-Interface
    local api_dir="${OUTPUT_DIR}/../api"
    mkdir -p "$api_dir"
    
    echo "$search_results" | jq '.' > "${api_dir}/tmdb_results.json"
    
    # Zeige Auswahl-Optionen
    log_message "TMDB: $result_count Ergebnis(se) gefunden"
    log_message "Bitte wählen Sie einen Film im Web-Interface aus..."
    
    # Warte auf Benutzer-Auswahl (max 5 Minuten)
    local selection_file="${api_dir}/tmdb_selection.json"
    rm -f "$selection_file"
    
    local timeout=300
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        if [[ -f "$selection_file" ]]; then
            local selected_index=$(jq -r '.selected_index // empty' "$selection_file")
            
            if [[ -n "$selected_index" ]]; then
                # Hole Movie-ID des ausgewählten Films
                local movie_id=$(echo "$search_results" | jq -r ".results[$selected_index].id // empty")
                
                if [[ -n "$movie_id" ]]; then
                    log_message "TMDB: Film ausgewählt (Index: $selected_index, ID: $movie_id)"
                    echo "$movie_id"
                    return 0
                fi
            fi
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    log_message "TMDB: Timeout - keine Auswahl getroffen"
    return 1
}

# Funktion: Erstelle Archive-Metadaten für DVD/Blu-ray
# Parameter: $1 = Suchbegriff (Film-/Serien-Titel, aus disc_label abgeleitet)
#            $2 = Disc-Typ (dvd-video oder bd-video)
# Verwendet globale Variablen: iso_filename, disc_label
create_dvd_archive_metadata() {
    local search_query="$1"
    local disc_type="$2"
    
    # Prüfe ob es sich um eine TV-Serie handelt (Season im Dateinamen)
    local season_number=""
    if [[ "$disc_label" =~ season[_[:space:]]*([0-9]+) ]]; then
        season_number="${BASH_REMATCH[1]}"
        log_message "TV-Serie erkannt: Season $season_number"
        
        # Entferne Season/Disc aus Suchbegriff für bessere Treffer
        search_query=$(echo "$search_query" | sed -E 's/[Ss]eason[[:space:]]*[0-9]+//g' | sed -E 's/[Dd]is[ck][[:space:]]*[0-9]+//g' | sed 's/  / /g' | xargs)
        
        # TV-Serie Workflow
        log_message "Suche TV-Serie: $search_query"
        local tv_results=$(search_tmdb_tv "$search_query")
        
        if [[ -z "$tv_results" ]]; then
            log_message "TMDB: TV-Suche fehlgeschlagen - keine Metadaten erstellt"
            return 1
        fi
        
        local result_count=$(echo "$tv_results" | jq -r '.results | length')
        
        if [[ "$result_count" -eq 0 ]]; then
            log_message "TMDB: Keine TV-Serie gefunden"
            return 1
        fi
        
        # Nehme erstes Ergebnis (meist beste Übereinstimmung)
        local tv_id=$(echo "$tv_results" | jq -r '.results[0].id')
        local tv_name=$(echo "$tv_results" | jq -r '.results[0].name')
        log_message "TMDB: TV-Serie gefunden: $tv_name (ID: $tv_id)"
        
        # Hole Season-Details
        local season_details=$(get_tmdb_tv_season_details "$tv_id" "$season_number")
        
        if [[ -z "$season_details" ]]; then
            log_message "TMDB: Fehler beim Abrufen der Season-Details"
            return 1
        fi
        
        # Erstelle .nfo für TV-Serie
        local nfo_file="${iso_filename%.iso}.nfo"
        local first_air_date=$(echo "$tv_results" | jq -r '.results[0].first_air_date' | cut -d'-' -f1)
        local genres=$(echo "$tv_results" | jq -r '.results[0].genre_ids[]' 2>/dev/null | head -3 | tr '\n' ',' | sed 's/,$//')
        local overview=$(echo "$tv_results" | jq -r '.results[0].overview // empty')
        local rating=$(echo "$tv_results" | jq -r '.results[0].vote_average // "0"')
        
        # Hole Creator (entspricht Director bei Filmen)
        local creator="Unknown Creator"
        local tv_full=$(curl -s -f "${TMDB_API_BASE_URL}/tv/${tv_id}?api_key=${TMDB_API_KEY}&language=de-DE" 2>/dev/null)
        if [[ -n "$tv_full" ]]; then
            creator=$(echo "$tv_full" | jq -r '.created_by[0].name // "Unknown Creator"')
            # Genre-Namen statt IDs
            genres=$(echo "$tv_full" | jq -r '[.genres[].name] | join(", ") // "Unknown"')
        fi
        
        {
            echo "TITLE=$tv_name"
            echo "YEAR=$first_air_date"
            echo "DIRECTOR=$creator"
            echo "GENRE=$genres"
            echo "RUNTIME=42"
            echo "RATING=$rating"
            echo "TYPE=$disc_type"
            [[ -n "$overview" ]] && echo "OVERVIEW=$overview"
        } > "$nfo_file"
        
        log_message "TV-Metadaten erstellt: $(basename "$nfo_file")"
        
        # Lade Season-Poster
        local poster_path=$(echo "$season_details" | jq -r '.poster_path // empty')
        local thumb_file="${iso_filename%.iso}-thumb.jpg"
        
        if download_tmdb_poster "$poster_path" "$thumb_file"; then
            log_message "Season-Poster heruntergeladen"
            return 0
        else
            log_message "TV-Metadaten erstellt (ohne Poster)"
            return 0
        fi
        
    else
        # Film Workflow (wie bisher)
        log_message "Suche Film-Metadaten: $search_query"
        
        local search_results=$(search_tmdb_movie "$search_query")
        
        if [[ -z "$search_results" ]]; then
            log_message "TMDB: Suche fehlgeschlagen - keine Metadaten erstellt"
            return 1
        fi
        
        # Prüfe ob automatische Auswahl möglich (nur 1 Ergebnis)
        local result_count=$(echo "$search_results" | jq -r '.results | length')
        local movie_id=""
        
        if [[ "$result_count" -eq 1 ]]; then
            # Automatische Auswahl bei eindeutigem Ergebnis
            movie_id=$(echo "$search_results" | jq -r '.results[0].id')
            local movie_title=$(echo "$search_results" | jq -r '.results[0].title')
            log_message "TMDB: Eindeutiges Ergebnis gefunden: $movie_title"
        else
            # Mehrere Ergebnisse → Benutzer-Auswahl erforderlich
            movie_id=$(select_tmdb_movie "$search_results")
            
            if [[ -z "$movie_id" ]]; then
                log_message "TMDB: Keine Auswahl getroffen - keine Metadaten erstellt"
                return 1
            fi
        fi
        
        # Hole Details zum ausgewählten Film
        local movie_details=$(get_tmdb_movie_details "$movie_id")
        
        if [[ -z "$movie_details" ]]; then
            log_message "TMDB: Fehler beim Abrufen der Film-Details"
            return 1
        fi
        
        # Erstelle .nfo Datei
        local nfo_file="${iso_filename%.iso}.nfo"
        create_movie_nfo "$nfo_file" "$movie_details" "$disc_type"
        
        # Lade Poster herunter
        local poster_path=$(echo "$movie_details" | jq -r '.poster_path // empty')
        local thumb_file="${iso_filename%.iso}-thumb.jpg"
        
        if download_tmdb_poster "$poster_path" "$thumb_file"; then
            log_message "Film-Metadaten erfolgreich erstellt"
            return 0
        else
            log_message "Film-Metadaten erstellt (ohne Poster)"
            return 0
        fi
    fi
}

# ============================================================================
# TITLE EXTRACTION
# ============================================================================

# Funktion: Extrahiere Filmtitel aus disc_label
# Parameter: $1 = disc_label (z.B. "the_matrix_1999" oder "MOVIE_TITLE")
# Rückgabe: Bereinigter Titel für TMDB-Suche
extract_movie_title() {
    local label="$1"
    
    # Entferne gängige Suffixe
    label=$(echo "$label" | sed -E 's/_disc_?[0-9]+$//i')
    label=$(echo "$label" | sed -E 's/_dvd$//i')
    label=$(echo "$label" | sed -E 's/_bluray$//i')
    label=$(echo "$label" | sed -E 's/_bd$//i')
    
    # Entferne Jahr am Ende (4-stellig)
    label=$(echo "$label" | sed -E 's/_[0-9]{4}$//')
    
    # Ersetze Unterstriche durch Leerzeichen
    label=$(echo "$label" | tr '_' ' ')
    
    # Großschreibung (erster Buchstabe jedes Wortes)
    label=$(echo "$label" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    
    echo "$label"
}

# ============================================================================
# RETROACTIVE METADATA FUNCTIONS
# ============================================================================

# Funktion: Füge TMDB-Metadaten zu existierender ISO hinzu
# Parameter: 
#   $1 = iso_path (vollständiger Pfad zur ISO-Datei)
#   $2 = title (Film- oder Serien-Titel für TMDB-Suche)
#   $3 = media_type ("movie" oder "tv")
#   $4 = tmdb_id (optional, wenn bereits bekannt)
# Rückgabe: 0 bei Erfolg, 1 bei Fehler
add_metadata_to_existing_iso() {
    local iso_path="$1"
    local title="$2"
    local media_type="$3"
    local tmdb_id="$4"
    
    # Validierung
    if [[ ! -f "$iso_path" ]]; then
        log_message "TMDB: ISO-Datei nicht gefunden: $iso_path"
        return 1
    fi
    
    if [[ -z "$TMDB_API_KEY" ]]; then
        log_message "TMDB: API-Key nicht konfiguriert"
        return 1
    fi
    
    # Extrahiere Basisnamen ohne .iso
    local base_path="${iso_path%.iso}"
    local nfo_file="${base_path}.nfo"
    local thumb_file="${base_path}-thumb.jpg"
    
    log_message "TMDB: Füge Metadaten hinzu für: $(basename "$iso_path")"
    
    # Wenn TMDB-ID bereits bekannt, hole Details direkt
    if [[ -n "$tmdb_id" ]]; then
        if [[ "$media_type" == "tv" ]]; then
            # Extrahiere Season-Nummer aus Dateinamen
            local season_num=""
            if [[ "$(basename "$iso_path")" =~ season[_[:space:]]*([0-9]+) ]]; then
                season_num="${BASH_REMATCH[1]}"
            fi
            
            if [[ -z "$season_num" ]]; then
                log_message "TMDB: Keine Season-Nummer im Dateinamen gefunden"
                return 1
            fi
            
            local tv_details=$(get_tmdb_tv_season_details "$tmdb_id" "$season_num")
            
            if [[ -z "$tv_details" ]]; then
                log_message "TMDB: Konnte TV-Details nicht abrufen"
                return 1
            fi
            
            # Extrahiere Metadaten
            local tv_name=$(echo "$tv_details" | jq -r '.name // empty')
            local first_air_date=$(echo "$tv_details" | jq -r '.first_air_date // empty')
            local year=$(echo "$first_air_date" | cut -d'-' -f1)
            local creator=$(echo "$tv_details" | jq -r '.created_by[0].name // "Unknown"')
            local genres=$(echo "$tv_details" | jq -r '[.genres[].name] | join(", ") // "Unknown"')
            local runtime=$(echo "$tv_details" | jq -r '.episode_run_time[0] // 0')
            local rating=$(echo "$tv_details" | jq -r '.vote_average // 0')
            local overview=$(echo "$tv_details" | jq -r '.overview // ""')
            local poster_path=$(echo "$tv_details" | jq -r '.seasons[] | select(.season_number == '"$season_num"') | .poster_path // empty')
            
            # Erstelle .nfo
            cat > "$nfo_file" <<EOF
TITLE=$tv_name
YEAR=$year
DIRECTOR=$creator
GENRE=$genres
RUNTIME=$runtime
RATING=$rating
TYPE=dvd-video
OVERVIEW=$overview
EOF
            
            # Lade Season-Poster
            if [[ -n "$poster_path" ]] && download_tmdb_poster "$poster_path" "$thumb_file"; then
                log_message "TMDB: TV-Metadaten erfolgreich hinzugefügt"
                return 0
            fi
            
        else
            # Movie
            local movie_details=$(get_tmdb_movie_details "$tmdb_id")
            
            if [[ -z "$movie_details" ]]; then
                log_message "TMDB: Konnte Film-Details nicht abrufen"
                return 1
            fi
            
            # Extrahiere Metadaten
            local movie_title=$(echo "$movie_details" | jq -r '.title // empty')
            local release_date=$(echo "$movie_details" | jq -r '.release_date // empty')
            local year=$(echo "$release_date" | cut -d'-' -f1)
            local director=$(echo "$movie_details" | jq -r '.credits.crew[] | select(.job == "Director") | .name' | head -n1)
            local genres=$(echo "$movie_details" | jq -r '[.genres[].name] | join(", ") // "Unknown"')
            local runtime=$(echo "$movie_details" | jq -r '.runtime // 0')
            local rating=$(echo "$movie_details" | jq -r '.vote_average // 0')
            local overview=$(echo "$movie_details" | jq -r '.overview // ""')
            local poster_path=$(echo "$movie_details" | jq -r '.poster_path // empty')
            
            # Ermittle Disc-Typ aus Pfad
            local disc_type="dvd-video"
            if [[ "$iso_path" =~ /bd/ ]]; then
                disc_type="bd-video"
            fi
            
            # Erstelle .nfo
            cat > "$nfo_file" <<EOF
TITLE=$movie_title
YEAR=$year
DIRECTOR=$director
GENRE=$genres
RUNTIME=$runtime
RATING=$rating
TYPE=$disc_type
OVERVIEW=$overview
EOF
            
            # Lade Poster
            if [[ -n "$poster_path" ]] && download_tmdb_poster "$poster_path" "$thumb_file"; then
                log_message "TMDB: Film-Metadaten erfolgreich hinzugefügt"
                return 0
            fi
        fi
        
        log_message "TMDB: Metadaten erstellt (ohne Poster)"
        return 0
    fi
    
    # Wenn keine TMDB-ID: Suche zuerst
    log_message "TMDB: Suche nach: $title ($media_type)"
    
    if [[ "$media_type" == "tv" ]]; then
        local search_results=$(search_tmdb_tv "$title")
    else
        local search_results=$(search_tmdb_movie "$title")
    fi
    
    if [[ -z "$search_results" ]]; then
        log_message "TMDB: Keine Suchergebnisse gefunden"
        return 1
    fi
    
    # Verwende ersten Treffer
    local first_id=$(echo "$search_results" | jq -r '.results[0].id // empty')
    
    if [[ -z "$first_id" ]]; then
        log_message "TMDB: Keine gültige ID in Suchergebnissen"
        return 1
    fi
    
    # Rekursiver Aufruf mit ID
    add_metadata_to_existing_iso "$iso_path" "$title" "$media_type" "$first_id"
}

# Funktion: Benenne ISO-Datei basierend auf TMDB-Titel um
# Parameter:
#   $1 = old_iso_path (aktueller Pfad)
#   $2 = new_title (neuer Titel, wird normalisiert)
# Rückgabe: Neuer Pfad oder alter Pfad bei Fehler
rename_iso_with_metadata() {
    local old_path="$1"
    local new_title="$2"
    
    if [[ ! -f "$old_path" ]]; then
        echo "$old_path"
        return 1
    fi
    
    # Normalisiere Titel (Kleinbuchstaben, Unterstriche)
    local normalized=$(echo "$new_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g')
    
    # Behalte Verzeichnis bei
    local dir=$(dirname "$old_path")
    local new_path="${dir}/${normalized}.iso"
    
    # Prüfe ob Datei bereits existiert
    if [[ -f "$new_path" ]] && [[ "$new_path" != "$old_path" ]]; then
        log_message "TMDB: Datei existiert bereits: $(basename "$new_path")"
        echo "$old_path"
        return 1
    fi
    
    # Benenne ISO + zugehörige Dateien um
    if mv "$old_path" "$new_path" 2>/dev/null; then
        # Benenne .md5 um (falls vorhanden)
        [[ -f "${old_path%.iso}.md5" ]] && mv "${old_path%.iso}.md5" "${new_path%.iso}.md5" 2>/dev/null
        
        # .nfo und -thumb.jpg werden mit neuem Namen erstellt
        log_message "TMDB: ISO umbenannt: $(basename "$old_path") → $(basename "$new_path")"
        echo "$new_path"
        return 0
    else
        log_message "TMDB: Umbenennung fehlgeschlagen"
        echo "$old_path"
        return 1
    fi
}

################################################################################
# ENDE lib-dvd-metadata.sh
################################################################################
