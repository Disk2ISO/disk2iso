# TMDB API-Key Beschaffung

## Übersicht

Ab Version 1.2.0 unterstützt disk2iso die automatische Metadaten-Beschaffung für DVDs und Blu-rays über die **The Movie Database (TMDB) API**. Dies ermöglicht:

- 🎬 **Film-Metadaten**: Titel, Originaltitel, Erscheinungsjahr
- 🖼️ **Cover-Artwork**: Poster und Backdrops in hoher Qualität
- 📝 **Zusatzinformationen**: Genre, Laufzeit, Produktionsland
- ⭐ **Bewertungen**: TMDB-Bewertung und Popularität

## Voraussetzungen

- Kostenloser TMDB-Account
- Email-Verifizierung
- Akzeptanz der TMDB API Terms of Use
- **Kein** Zahlungsmittel erforderlich

## Schritt-für-Schritt Anleitung

### 1. TMDB-Account erstellen

1. Besuche https://www.themoviedb.org/signup
2. Fülle das Registrierungsformular aus:
   - Benutzername
   - Email-Adresse
   - Passwort
   - Sprache (z.B. Deutsch)
3. Akzeptiere die Nutzungsbedingungen
4. Klicke auf **"Sign Up"**
5. Bestätige deine Email-Adresse über den Bestätigungslink

### 2. API-Key beantragen

1. Logge dich bei TMDB ein
2. Navigiere zu **Settings** (Einstellungen):
   - Klicke auf dein Profilbild (oben rechts)
   - Wähle **"Settings"** aus dem Dropdown
3. Wähle im linken Menü **"API"**
4. Klicke auf **"Request an API Key"** oder **"Create"**
5. Wähle den Typ: **"Developer"** (für nicht-kommerzielle Nutzung)
6. Fülle das Formular aus:
   - **Application Name**: z.B. "disk2iso Media Archiving"
   - **Application URL**: Optional (kann leer bleiben oder GitHub-URL)
   - **Application Summary**: 
     ```
     Automatische Archivierung von DVDs und Blu-rays als ISO-Images
     mit Metadaten-Anreicherung für persönliche Medien-Bibliothek.
     ```
7. Akzeptiere die **API Terms of Use**
8. Klicke auf **"Submit"**

### 3. API-Key kopieren

Nach der Genehmigung (meist sofort):

1. Navigiere zurück zu **Settings → API**
2. Du siehst zwei Keys:
   - **API Key (v3 auth)**: ← Dieser wird für disk2iso benötigt
   - **API Read Access Token (v4 auth)**: Nicht benötigt
3. Kopiere den **API Key (v3 auth)** - er hat das Format:
   ```
   1234567890abcdef1234567890abcdef
   ```
   (32 hexadezimale Zeichen)

### 4. API-Key in disk2iso konfigurieren

#### Option A: Web-Interface (empfohlen)

1. Öffne das disk2iso Web-Interface
2. Navigiere zu **Einstellungen** (Zahnrad-Symbol)
3. Scrolle zu **"TMDB API-Key"**
4. Füge deinen API-Key ein
5. Klicke auf **"Speichern"**
6. Der Service wird automatisch neu gestartet

#### Option B: Manuelle Konfiguration

Bearbeite `/opt/disk2iso/lib/config.sh`:

```bash
# TMDB API-Key für DVD/Blu-ray Metadaten
TMDB_API_KEY="1234567890abcdef1234567890abcdef"
```

Starte den Service neu:
```bash
sudo systemctl restart disk2iso.service
```

## API-Limits

TMDB API v3 (kostenlos):

- **Rate Limit**: 40 Requests pro 10 Sekunden
- **Tages-Limit**: Keines für non-commercial use
- **Kosten**: Kostenlos

disk2iso macht pro DVD/Blu-ray:
- 1 Request: Film-Suche nach Titel
- 1 Request: Cover-Download
- **Gesamt**: ~2 Requests pro Disc

→ Bei 40 Requests/10s können ~200 Discs pro Minute verarbeitet werden

## Datenschutz

TMDB-API-Anfragen enthalten:
- Film-Titel (aus DVD/Blu-ray Label)
- API-Key (zur Authentifizierung)
- IP-Adresse (technisch notwendig)

**KEINE** persönlichen Daten, Medienbibliotheks-Inhalte oder Nutzungsstatistiken werden übertragen.

## Troubleshooting

### Fehler: "Invalid API key"

- Prüfe, ob der Key korrekt kopiert wurde (32 Zeichen, keine Leerzeichen)
- Stelle sicher, dass der v3 API Key verwendet wird (nicht v4 Token)
- Überprüfe, ob der Key aktiviert ist (Settings → API)

### Fehler: "Rate limit exceeded"

- Warte 10 Sekunden
- disk2iso enthält automatische Rate-Limiting-Logik
- Bei Massen-Archivierung: Pause zwischen Batches einlegen

### Keine Metadaten gefunden

- Film könnte in TMDB fehlen (vor allem bei sehr alten/obskuren Titeln)
- Disc-Label könnte zu generisch sein (z.B. "DISC_1")
- Manuelle Metadaten-Eingabe über Web-Interface möglich

## Links

- TMDB Website: https://www.themoviedb.org
- API Dokumentation: https://developer.themoviedb.org/docs
- API Status: https://status.themoviedb.org
- Support: https://www.themoviedb.org/talk

## Rechtliches

Verwendung der TMDB API unterliegt den [TMDB Terms of Use](https://www.themoviedb.org/terms-of-use).

Attribution gemäß API-Richtlinien:
> "This product uses the TMDB API but is not endorsed or certified by TMDB."

TMDB-Logo und Metadaten © The Movie Database (TMDB)
