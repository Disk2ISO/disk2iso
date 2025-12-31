# Web-Server Brainstorming

Sammlung von Ideen und Konzepten für eine optionale Web-Interface Integration in disk2iso.

---

## 🎯 Was soll die Web-Seite anzeigen?

### 1. Aktueller Status
- Laufwerksstatus (leer/beschäftigt/bereit)
- Aktuell eingelegte Disc (Typ, Label)
- Ripping-Fortschritt (Prozent, MB, ETA)
- Gewählte Methode (dd, ddrescue, cdparanoia, etc.)
- Letzte Aktivität (Timestamp)

### 2. Archiv
- Liste aller gerippten Discs
- Gruppierung nach Typ (audio/, data/, dvd/, bd/)
- Metadaten pro Disc:
  - Dateiname
  - Größe
  - Erstellungsdatum
  - MD5-Checksumme
  - (Audio-CD: Cover, Artist, Album)
- Suchfunktion
- Sortierung (Datum, Name, Größe, Typ)

---

## 🏠 Home Assistant Integration via MQTT

### Anforderungen

**Funktion 1: Status-Dashboard**
- Laufwerksstatus (leer/belegt)
- Disc-Typ + Label
- Live-Fortschritt (%, MB, ETA)
- Fortschrittsbalken
- Statistik (Anzahl ISOs nach Typ: Audio, Daten, DVD, BD)

**Funktion 2: Benachrichtigungen**
- Bei Abschluss → Notify an alle HA Clients
- Bei Abbruch/Fehler → Notify an alle HA Clients

### Warum MQTT statt Webhooks?

**✅ MQTT ist die richtige Lösung:**
- Kontinuierliche Status-Updates für Live-Dashboard
- Retained Messages (Status bleibt nach HA-Neustart erhalten)
- Event-basierte Benachrichtigungen möglich
- Robust bei Netzwerkunterbrechungen
- Eine Technologie für beide Anforderungen

**❌ Webhooks allein reichen nicht:**
- Nur für einmalige Events geeignet
- Kein persistenter Status
- Fortschritt-Updates würden jede Sekunde einen HTTP-Request erfordern
- Verlust von Updates wenn HA offline ist

### MQTT Topics Struktur

```bash
# Status-Updates (kontinuierlich, retained)
disk2iso/status          → "idle" | "detecting" | "ripping" | "finished" | "error"
disk2iso/drive           → "empty" | "occupied"
disk2iso/disc_type       → "audio-cd" | "dvd-video" | "cd-rom" | ...
disk2iso/disc_label      → "Pink Floyd - The Wall"
disk2iso/progress        → "45"        (Prozent)
disk2iso/progress_mb     → "320/650"   (MB)
disk2iso/eta             → "8"         (Minuten)
disk2iso/current_method  → "cdparanoia + lame"

# Statistiken (bei Änderung, retained)
disk2iso/stats/total     → "142"
disk2iso/stats/audio     → "38"
disk2iso/stats/data      → "54"
disk2iso/stats/dvd       → "32"
disk2iso/stats/bd        → "18"

# Events (nur bei Ereignissen, NOT retained)
disk2iso/event           → "finished" | "aborted" | "error"
disk2iso/event_message   → "Pink Floyd - The Wall (650MB) erfolgreich gespeichert"
```

### disk2iso Implementation

**Neue Bibliothek: `disk2iso-lib/lib-homeassistant.sh`**

```bash
# MQTT-Konfiguration (aus config.sh)
HA_MQTT_ENABLED=true
HA_MQTT_BROKER="homeassistant.local"
HA_MQTT_PORT=1883
HA_MQTT_USER=""       # Optional
HA_MQTT_PASSWORD=""   # Optional

# MQTT Publish Funktion
ha_mqtt_publish() {
    local topic="$1"
    local message="$2"
    local retain="${3:-false}"  # Retained message für Status
    
    if [[ "$HA_MQTT_ENABLED" == "true" ]] && command -v mosquitto_pub &>/dev/null; then
        local cmd="mosquitto_pub -h $HA_MQTT_BROKER -p $HA_MQTT_PORT -t disk2iso/$topic -m \"$message\""
        
        [[ "$retain" == "true" ]] && cmd="$cmd -r"
        [[ -n "$HA_MQTT_USER" ]] && cmd="$cmd -u $HA_MQTT_USER -P $HA_MQTT_PASSWORD"
        
        eval "$cmd" 2>/dev/null
    fi
}

# Status Updates (retained = immer sichtbar)
ha_update_status() {
    ha_mqtt_publish "status" "$1" true
}

ha_update_drive() {
    ha_mqtt_publish "drive" "$1" true
}

ha_update_progress() {
    local percent="$1"
    local mb_current="$2"
    local mb_total="$3"
    local eta_min="$4"
    
    ha_mqtt_publish "progress" "$percent" true
    ha_mqtt_publish "progress_mb" "$mb_current/$mb_total" true
    ha_mqtt_publish "eta" "$eta_min" true
}

ha_update_disc() {
    local type="$1"
    local label="$2"
    
    ha_mqtt_publish "disc_type" "$type" true
    ha_mqtt_publish "disc_label" "$label" true
}

# Event-Benachrichtigungen (NICHT retained)
ha_send_event() {
    local event_type="$1"  # finished, aborted, error
    local message="$2"
    
    ha_mqtt_publish "event" "$event_type" false
    ha_mqtt_publish "event_message" "$message" false
}

# Statistiken aktualisieren
ha_update_stats() {
    local audio=$(find "$OUTPUT_DIR/audio" -name "*.iso" 2>/dev/null | wc -l)
    local data=$(find "$OUTPUT_DIR/data" -name "*.iso" 2>/dev/null | wc -l)
    local dvd=$(find "$OUTPUT_DIR/dvd" -name "*.iso" 2>/dev/null | wc -l)
    local bd=$(find "$OUTPUT_DIR/bd" -name "*.iso" 2>/dev/null | wc -l)
    local total=$((audio + data + dvd + bd))
    
    ha_mqtt_publish "stats/total" "$total" true
    ha_mqtt_publish "stats/audio" "$audio" true
    ha_mqtt_publish "stats/data" "$data" true
    ha_mqtt_publish "stats/dvd" "$dvd" true
    ha_mqtt_publish "stats/bd" "$bd" true
}
```

**Integration in disk2iso.sh:**

```bash
# Beim Start
ha_update_status "idle"
ha_update_drive "empty"
ha_update_stats

# Disc eingelegt
ha_update_drive "occupied"
ha_update_status "detecting"

# Disc erkannt
ha_update_disc "$DISC_TYPE" "$DISC_LABEL"
ha_update_status "ripping"

# Während des Rippings (z.B. alle 5 Sekunden)
while ripping; do
    ha_update_progress "$PROGRESS_PCT" "$MB_DONE" "$MB_TOTAL" "$ETA_MIN"
    sleep 5
done

# Bei Erfolg
ha_update_status "finished"
ha_send_event "finished" "$DISC_LABEL ($SIZE_MB MB) erfolgreich gespeichert"
ha_update_stats

# Bei Fehler
ha_update_status "error"
ha_send_event "error" "Fehler beim Rippen von $DISC_LABEL: $ERROR_MSG"

# Disc ausgeworfen
ha_update_drive "empty"
ha_update_status "idle"
```

### Home Assistant Konfiguration

#### MQTT Sensoren

```yaml
# configuration.yaml
mqtt:
  sensor:
    # Status
    - name: "Disk2ISO Status"
      state_topic: "disk2iso/status"
      icon: mdi:disc-player
    
    - name: "Disk2ISO Laufwerk"
      state_topic: "disk2iso/drive"
      icon: mdi:disc
    
    # Disc-Infos
    - name: "Disk2ISO Disc-Typ"
      state_topic: "disk2iso/disc_type"
      icon: mdi:album
    
    - name: "Disk2ISO Disc-Label"
      state_topic: "disk2iso/disc_label"
    
    # Fortschritt
    - name: "Disk2ISO Fortschritt"
      state_topic: "disk2iso/progress"
      unit_of_measurement: "%"
      icon: mdi:percent
    
    - name: "Disk2ISO Fortschritt MB"
      state_topic: "disk2iso/progress_mb"
    
    - name: "Disk2ISO Restzeit"
      state_topic: "disk2iso/eta"
      unit_of_measurement: "min"
      icon: mdi:timer-sand
    
    - name: "Disk2ISO Methode"
      state_topic: "disk2iso/current_method"
    
    # Statistiken
    - name: "Disk2ISO Anzahl Gesamt"
      state_topic: "disk2iso/stats/total"
      icon: mdi:counter
    
    - name: "Disk2ISO Anzahl Audio"
      state_topic: "disk2iso/stats/audio"
      icon: mdi:music-box-multiple
    
    - name: "Disk2ISO Anzahl Daten"
      state_topic: "disk2iso/stats/data"
      icon: mdi:harddisk
    
    - name: "Disk2ISO Anzahl DVD"
      state_topic: "disk2iso/stats/dvd"
      icon: mdi:filmstrip
    
    - name: "Disk2ISO Anzahl BD"
      state_topic: "disk2iso/stats/bd"
      icon: mdi:disc
    
    # Events
    - name: "Disk2ISO Event"
      state_topic: "disk2iso/event"
    
    - name: "Disk2ISO Event Nachricht"
      state_topic: "disk2iso/event_message"
```

#### Benachrichtigungs-Automationen

```yaml
# automations.yaml
automation:
  - alias: "Disk2ISO Fertig Benachrichtigung"
    trigger:
      - platform: mqtt
        topic: "disk2iso/event"
        payload: "finished"
    action:
      - service: notify.notify  # Sendet an ALLE Geräte
        data:
          title: "✅ Disc fertig gerippt"
          message: "{{ states('sensor.disk2iso_event_nachricht') }}"
  
  - alias: "Disk2ISO Fehler Benachrichtigung"
    trigger:
      - platform: mqtt
        topic: "disk2iso/event"
        payload: "error"
    action:
      - service: notify.notify
        data:
          title: "❌ Disk2ISO Fehler"
          message: "{{ states('sensor.disk2iso_event_nachricht') }}"
          data:
            priority: high
            
  - alias: "Disk2ISO Abbruch Benachrichtigung"
    trigger:
      - platform: mqtt
        topic: "disk2iso/event"
        payload: "aborted"
    action:
      - service: notify.notify
        data:
          title: "⚠️ Ripping abgebrochen"
          message: "{{ states('sensor.disk2iso_event_nachricht') }}"
```

#### Dashboard Card

```yaml
# dashboard.yaml
type: vertical-stack
cards:
  - type: entities
    title: Disk2ISO Server
    entities:
      - entity: sensor.disk2iso_status
        name: Status
      - entity: sensor.disk2iso_laufwerk
        name: Laufwerk
      - entity: sensor.disk2iso_disc_typ
        name: Disc-Typ
      - entity: sensor.disk2iso_disc_label
        name: Aktuell
      - entity: sensor.disk2iso_methode
        name: Methode
  
  - type: custom:bar-card
    entity: sensor.disk2iso_fortschritt
    name: Fortschritt
    max: 100
    severity:
      - color: "#03a9f4"
        from: 0
        to: 100
  
  - type: entities
    entities:
      - entity: sensor.disk2iso_fortschritt_mb
        name: Kopiert
      - entity: sensor.disk2iso_restzeit
        name: Restzeit
  
  - type: glance
    title: Archiv-Statistik
    entities:
      - entity: sensor.disk2iso_anzahl_gesamt
        name: Gesamt
      - entity: sensor.disk2iso_anzahl_audio
        name: Audio
      - entity: sensor.disk2iso_anzahl_daten
        name: Daten
      - entity: sensor.disk2iso_anzahl_dvd
        name: DVD
      - entity: sensor.disk2iso_anzahl_bd
        name: Blu-ray
```

### Benötigte Pakete

**Auf dem disk2iso Server:**
```bash
sudo apt install mosquitto-clients
```

**Auf Home Assistant:**
- MQTT Integration aktivieren (Settings → Devices & Services → Add Integration → MQTT)
- MQTT Broker muss laufen (entweder Mosquitto Add-on oder externer Broker)

### Vorteile dieser Lösung

- ✅ **Eine einzige Technologie** - MQTT für alles
- ✅ **Robustheit** - Retained messages überleben HA-Neustarts
- ✅ **Minimale Dependencies** - Nur `mosquitto-clients` (~100KB)
- ✅ **Echtzeit-Updates** - Kein Polling nötig
- ✅ **Skalierbar** - Mehrere Laufwerke = mehr Topics
- ✅ **Standardkonform** - MQTT ist IoT-Standard

---

## 📝 Weitere Ideen

_(Platzhalter für weitere Brainstorming-Punkte)_

---

**Status:** Brainstorming  
**Letzte Aktualisierung:** 2025-12-31