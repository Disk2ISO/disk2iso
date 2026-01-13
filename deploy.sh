#!/bin/bash
################################################################################
# disk2iso v1.2.0 - Deployment Script
# Aktualisiert Testsystem ohne config.sh zu überschreiben
################################################################################

set -e

SOURCE_DIR="/home/dirk/Projects/disk2iso"
TARGET_DIR="/opt/disk2iso"

echo "=== disk2iso Deployment ==="
echo ""

# 1. Backup erstellen
echo "1. Erstelle Backup..."
BACKUP_DIR="/tmp/disk2iso_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$TARGET_DIR" "$BACKUP_DIR/"
echo "   ✓ Backup: $BACKUP_DIR"
echo ""

# 2. Kernel-Dateien kopieren
echo "2. Kopiere Haupt-Scripts..."
sudo cp "$SOURCE_DIR/disk2iso.sh" "$TARGET_DIR/"
sudo cp "$SOURCE_DIR/install.sh" "$TARGET_DIR/"
sudo cp "$SOURCE_DIR/uninstall.sh" "$TARGET_DIR/"
sudo cp "$SOURCE_DIR/VERSION" "$TARGET_DIR/"
echo "   ✓ Haupt-Scripts aktualisiert"
echo ""

# 3. Bibliotheken kopieren
echo "3. Kopiere lib/*.sh..."
sudo cp "$SOURCE_DIR"/lib/*.sh "$TARGET_DIR/lib/"
echo "   ✓ $(ls $SOURCE_DIR/lib/*.sh | wc -l) Bibliotheken kopiert"
echo ""

# 4. Sprachdateien kopieren
echo "4. Kopiere Sprachdateien..."
sudo cp "$SOURCE_DIR"/lang/* "$TARGET_DIR/lang/"
echo "   ✓ Sprachdateien aktualisiert"
echo ""

# 5. Service-Dateien kopieren
echo "5. Kopiere Service-Dateien..."
sudo cp "$SOURCE_DIR"/service/* "$TARGET_DIR/service/"
echo "   ✓ Service-Definitionen aktualisiert"
echo ""

# 6. Web-Interface kopieren
echo "6. Kopiere Web-Interface..."
sudo cp "$SOURCE_DIR/www/app.py" "$TARGET_DIR/www/"
sudo cp "$SOURCE_DIR/www/i18n.py" "$TARGET_DIR/www/"
sudo cp -r "$SOURCE_DIR/www/templates" "$TARGET_DIR/www/"
sudo cp -r "$SOURCE_DIR/www/static" "$TARGET_DIR/www/"
echo "   ✓ Web-Interface aktualisiert"
echo ""

# 7. API-Dateien kopieren
echo "7. Kopiere API-Struktur..."
sudo mkdir -p "$TARGET_DIR/api"
sudo cp "$SOURCE_DIR"/api/*.json "$TARGET_DIR/api/" 2>/dev/null || echo "   ℹ Keine JSON-Dateien in api/"
echo "   ✓ API-Struktur aktualisiert"
echo ""

# 8. Config-Merge prüfen
echo "8. Prüfe config.sh auf neue Einstellungen..."
NEW_SETTINGS=()

# Prüfe auf neue TMDB_API_KEY Einstellung
if ! grep -q "TMDB_API_KEY" "$TARGET_DIR/lib/config.sh" 2>/dev/null; then
    NEW_SETTINGS+=("TMDB_API_KEY")
fi

if [ ${#NEW_SETTINGS[@]} -gt 0 ]; then
    echo "   ⚠ Neue Einstellungen gefunden:"
    for setting in "${NEW_SETTINGS[@]}"; do
        echo "      - $setting"
    done
    echo ""
    read -p "   Neue Einstellungen zu config.sh hinzufügen? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup der config.sh
        sudo cp "$TARGET_DIR/lib/config.sh" "$TARGET_DIR/lib/config.sh.bak"
        
        # Füge TMDB_API_KEY hinzu (falls nicht vorhanden)
        if [[ " ${NEW_SETTINGS[@]} " =~ " TMDB_API_KEY " ]]; then
            echo "" | sudo tee -a "$TARGET_DIR/lib/config.sh" >/dev/null
            echo "# TMDB API Key für DVD/Blu-ray Metadaten" | sudo tee -a "$TARGET_DIR/lib/config.sh" >/dev/null
            echo "TMDB_API_KEY=\"\"" | sudo tee -a "$TARGET_DIR/lib/config.sh" >/dev/null
            echo "   ✓ TMDB_API_KEY hinzugefügt"
        fi
    else
        echo "   ℹ Übersprungen - config.sh unverändert"
    fi
else
    echo "   ✓ Keine neuen Einstellungen - config.sh bleibt unverändert"
fi
echo ""

# 9. Berechtigungen setzen
echo "9. Setze Berechtigungen..."
sudo chmod +x "$TARGET_DIR/disk2iso.sh"
sudo chmod +x "$TARGET_DIR/install.sh"
sudo chmod +x "$TARGET_DIR/uninstall.sh"
sudo chmod +x "$TARGET_DIR"/lib/*.sh
echo "   ✓ Berechtigungen gesetzt"
echo ""

# 10. Services neu starten
echo "10. Starte Services neu..."
if systemctl is-active --quiet disk2iso; then
    sudo systemctl restart disk2iso
    echo "   ✓ disk2iso Service neu gestartet"
else
    echo "   ℹ disk2iso Service nicht aktiv"
fi

if systemctl is-active --quiet disk2iso-web; then
    sudo systemctl restart disk2iso-web
    echo "   ✓ disk2iso-web Service neu gestartet"
else
    echo "   ℹ disk2iso-web Service nicht aktiv"
fi
echo ""

# 11. Status prüfen
echo "11. Service-Status:"
systemctl status disk2iso --no-pager -l | grep -E "Active:|Main PID:" || true
systemctl status disk2iso-web --no-pager -l | grep -E "Active:|Main PID:" || true
echo ""

echo "=== Deployment abgeschlossen ==="
echo ""
echo "Backup gespeichert in: $BACKUP_DIR"
echo "Web-Interface: http://$(hostname -I | awk '{print $1}'):8080"
echo ""

# Zeige Änderungen
echo "Wichtige Änderungen in dieser Version:"
echo "  • Nachträgliche TMDB-Metadaten für DVDs/Blu-rays"
echo "  • Audio-CD ISO-Remaster mit neuen Tags"
echo "  • TV-Series Support mit Season/Disc-Erkennung"
echo "  • Neue API-Endpunkte: /api/metadata/*"
echo "  • Metadaten-Such-Modal im Web-Interface"
echo ""
