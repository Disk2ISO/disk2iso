# MQTT Audio-CD Fortschrittsanzeige korrigiert

**Datum**: 13.01.2026  
**Version**: 1.2.0  
**Geänderte Dateien**: 
- lib/lib-mqtt.sh
- doc/homeassistant-configuration.yaml

## Problem

Bei Audio-CDs wurde in Home Assistant "2 von 19 MB" statt "2 von 19 Tracks" angezeigt.

## Lösung

### 1. MQTT-Attribut `progress_unit` hinzugefügt

**lib/lib-mqtt.sh** - Funktion `mqtt_publish_progress()`:

```bash
# Bestimme Einheit basierend auf Disc-Typ
local unit="MB"
if [[ "${disc_type:-}" == "audio-cd" ]]; then
    unit="Tracks"
fi

# JSON mit neuer progress_unit
{
  ...
  "progress_unit": "${unit}",
  ...
}
```

**Verhalten**:
- Audio-CD (`disc_type == "audio-cd"`) → `progress_unit: "Tracks"`
- Alle anderen Medien → `progress_unit: "MB"`

### 2. Home Assistant Konfiguration aktualisiert

**doc/homeassistant-configuration.yaml**:

```yaml
{% if is_state('sensor.disk2iso_status', 'copying') %}
{% set unit = state_attr('sensor.disk2iso_status', 'progress_unit') or 'MB' %}
**Fortschritt:** {{ ... }} / {{ ... }} {{ unit }}
{% endif %}
```

Die Konfiguration liest jetzt dynamisch die Einheit aus dem `progress_unit` Attribut.

## Testen

### MQTT Broker

Prüfe die MQTT-Nachricht:
```bash
mosquitto_sub -h 192.168.20.10 -t "homeassistant/sensor/disk2iso/attributes" -v
```

**Ausgabe für Audio-CD**:
```json
{
  "disc_type": "audio-cd",
  "progress_percent": 10,
  "progress_mb": 2,
  "total_mb": 19,
  "progress_unit": "Tracks",
  "eta": "01:08:00"
}
```

**Ausgabe für DVD**:
```json
{
  "disc_type": "dvd-video",
  "progress_percent": 15,
  "progress_mb": 750,
  "total_mb": 4500,
  "progress_unit": "MB",
  "eta": "00:45:00"
}
```

## Home Assistant Integration

Der Benutzer muss die Lovelace Dashboard-Konfiguration aktualisieren. Die neue Zeile:

```yaml
{% set unit = state_attr('sensor.disk2iso_status', 'progress_unit') or 'MB' %}
**Fortschritt:** {{ state_attr('sensor.disk2iso_status', 'progress_mb') }} / {{ state_attr('sensor.disk2iso_status', 'total_mb') }} {{ unit }}
```

### Beispiel-Anzeige

**Audio-CD**:
```
Fortschritt: 3 / 19 Tracks
Verbleibend: 01:04:00
```

**DVD**:
```
Fortschritt: 1250 / 4500 MB
Verbleibend: 00:42:00
```

## Hinweis für den Benutzer

Der Benutzer muss in seiner **Home Assistant Konfiguration** die Lovelace-Card aktualisieren:

1. Home Assistant → Einstellungen → Dashboards
2. Bearbeite die disk2iso Card
3. Aktualisiere die Markdown-Vorlage mit der neuen Zeile (siehe oben)
4. Speichern

Alternativ: Kopiere die neue Konfiguration aus `/opt/disk2iso/doc/homeassistant-configuration.yaml`

---

**Status**: ✅ Implementiert und deployed  
**Nächster Schritt**: Home Assistant Dashboard aktualisieren
