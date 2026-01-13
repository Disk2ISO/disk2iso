#!/bin/bash
################################################################################
# Deployment-Validierung für disk2iso v1.2.0
################################################################################

echo "=== disk2iso v1.2.0 Deployment-Validierung ==="
echo ""

# 1. Versions-Check
echo "1. Versions-Check:"
version=$(cat /opt/disk2iso/VERSION 2>/dev/null || echo "FEHLER")
echo "   Version: $version"
if [ "$version" == "1.2.0" ]; then
    echo "   ✓ Version korrekt"
else
    echo "   ✗ Falsche Version!"
fi
echo ""

# 2. Neue Module prüfen
echo "2. Neue Module:"
if [ -f "/opt/disk2iso/lib/lib-cd-metadata.sh" ]; then
    echo "   ✓ lib-cd-metadata.sh vorhanden"
else
    echo "   ✗ lib-cd-metadata.sh fehlt!"
fi

if grep -q "add_metadata_to_existing_iso" /opt/disk2iso/lib/lib-dvd-metadata.sh 2>/dev/null; then
    echo "   ✓ lib-dvd-metadata.sh erweitert"
else
    echo "   ✗ lib-dvd-metadata.sh nicht aktualisiert!"
fi

if grep -q "load_module_language" /opt/disk2iso/lib/lib-tools.sh 2>/dev/null; then
    echo "   ✓ lib-tools.sh korrigiert"
else
    echo "   ✗ lib-tools.sh nicht korrigiert!"
fi
echo ""

# 3. API-Endpunkte prüfen
echo "3. API-Endpunkte:"
if grep -q "/api/metadata/tmdb/search" /opt/disk2iso/www/app.py 2>/dev/null; then
    echo "   ✓ TMDB-Search-Endpunkt vorhanden"
else
    echo "   ✗ TMDB-Search-Endpunkt fehlt!"
fi

if grep -q "/api/metadata/musicbrainz/search" /opt/disk2iso/www/app.py 2>/dev/null; then
    echo "   ✓ MusicBrainz-Search-Endpunkt vorhanden"
else
    echo "   ✗ MusicBrainz-Search-Endpunkt fehlt!"
fi
echo ""

# 4. Web-Interface prüfen
echo "4. Web-Interface:"
if grep -q "metadata-modal" /opt/disk2iso/www/templates/archive.html 2>/dev/null; then
    echo "   ✓ Metadaten-Modal im Template"
else
    echo "   ✗ Metadaten-Modal fehlt!"
fi

if grep -q "openMetadataModal" /opt/disk2iso/www/static/js/archive.js 2>/dev/null; then
    echo "   ✓ Modal-Funktionen in archive.js"
else
    echo "   ✗ Modal-Funktionen fehlen!"
fi

if grep -q "Version: 1.2.0" /opt/disk2iso/www/static/js/index.js 2>/dev/null; then
    echo "   ✓ JavaScript-Header aktualisiert"
else
    echo "   ✗ JavaScript-Header nicht aktualisiert!"
fi
echo ""

# 5. Service-Status
echo "5. Service-Status:"
if systemctl is-active --quiet disk2iso; then
    echo "   ✓ disk2iso Service läuft"
else
    echo "   ✗ disk2iso Service NICHT aktiv!"
fi

if systemctl is-active --quiet disk2iso-web; then
    echo "   ✓ disk2iso-web Service läuft"
else
    echo "   ✗ disk2iso-web Service NICHT aktiv!"
fi
echo ""

# 6. API Live-Test
echo "6. API Live-Test:"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/status)
if [ "$response" == "200" ]; then
    echo "   ✓ /api/status erreichbar (HTTP $response)"
else
    echo "   ✗ /api/status nicht erreichbar (HTTP $response)"
fi

response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"Test"}' http://localhost:8080/api/metadata/tmdb/search -o /dev/null -w "%{http_code}")
if [ "$response" == "200" ] || [ "$response" == "400" ]; then
    echo "   ✓ /api/metadata/tmdb/search erreichbar (HTTP $response)"
else
    echo "   ✗ /api/metadata/tmdb/search nicht erreichbar (HTTP $response)"
fi
echo ""

# 7. Sprachsystem
echo "7. Sprachsystem:"
lang_count=$(ls /opt/disk2iso/lang/lib-cd.* 2>/dev/null | wc -l)
if [ "$lang_count" == "4" ]; then
    echo "   ✓ Alle 4 Sprachen vorhanden (de, en, es, fr)"
else
    echo "   ⚠ Nur $lang_count Sprachen gefunden"
fi
echo ""

# 8. Config-Integrität
echo "8. Config-Integrität:"
if [ -f "/opt/disk2iso/lib/config.sh" ]; then
    echo "   ✓ config.sh vorhanden"
    if grep -q "OUTPUT_DIR" /opt/disk2iso/lib/config.sh; then
        echo "   ✓ Einstellungen intakt"
    else
        echo "   ✗ config.sh beschädigt!"
    fi
else
    echo "   ✗ config.sh fehlt!"
fi
echo ""

echo "=== Validierung abgeschlossen ==="
