# Kapitel 8.2: Widget-Struktur Übersicht

Diese Übersicht dokumentiert alle Widget-Komponenten des disk2iso Webinterfaces, organisiert nach den verschiedenen Seiten der Anwendung.

## Dateistruktur

Jedes Widget besteht aus drei Komponenten:
- **HTML Template**: `www/templates/widgets/<name>.html`
- **JavaScript**: `www/static/js/widgets/<name>.js`
- **Python Middleware**: `www/routes/widgets/<name>.py`

Die Namenskonvention ist: `<typ>_<größe>_<modul>.ext`
- `<typ>`: Funktion des Widgets (settings, dependencies, status, etc.)
- `<größe>`: Grid-Größe in Format BxH (z.B. 4x2, 3x4)
- `<modul>`: Zugehöriges Modul (audio, dvd, systeminfo, etc.)

---

Einstellungen Seite (Settings)
===============================

| Modul          | HTML Template                    | JavaScript                       | Python Middleware          |
|----------------|----------------------------------|----------------------------------|----------------------------|
| libconfig      | settings_4x2_config.html         | settings_4x2_config.js           | settings_config.py         |
| libdrivestat   | settings_4x3_drivestat.html      | settings_4x3_drivestat.js        | settings_drivestat.py      |
| libcommon      | settings_4x2_common.html         | settings_4x2_common.js           | settings_common.py         |
| libaudio       | settings_4x2_audio.html          | settings_4x2_audio.js            | settings_audio.py          |
| libdvd         | settings_4x2_dvd.html            | settings_4x2_dvd.js              | settings_dvd.py            |
| libbluray      | settings_4x2_bluray.html         | settings_4x2_bluray.js           | settings_bluray.py         |
| libmetadata    | settings_4x6_metadata.html       | settings_4x6_metadata.js         | settings_metadata.py       |
| libcdtext      | settings_4x4_cdtext.html         | settings_4x4_cdtext.js           | settings_cdtext.py         |
| libmusicbrainz | settings_4x4_musicbrainz.html    | settings_4x4_musicbrainz.js      | settings_musicbrainz.py    |
| libtmdb        | settings_4x4_tmdb.html           | settings_4x4_tmdb.js             | settings_tmdb.py           |
| libmqtt        | settings_4x7_mqtt.html           | settings_4x7_mqtt.js             | settings_mqtt.py           |

Systeminfo Seite (System)
==========================

| Modul          | HTML Template                    | JavaScript                       | Python Middleware              |
|----------------|----------------------------------|----------------------------------|--------------------------------|
| libsysteminfo  | sysinfo_3x5_systeminfo.html      | sysinfo_3x5_systeminfo.js        | sysinfo_systeminfo.py          |
| libsysteminfo  | softwarecheck_3x2_systeminfo.html| softwarecheck_3x2_systeminfo.js  | softwarecheck_systeminfo.py    |
| libsysteminfo  | dependencies_4x2_systeminfo.html | dependencies_4x2_systeminfo.js   | dependencies_systeminfo.py     |
| libaudio       | dependencies_4x2_audio.html      | dependencies_4x2_audio.js        | dependencies_audio.py          |
| libdvd         | dependencies_4x2_dvd.html        | dependencies_4x2_dvd.js          | dependencies_dvd.py            |
| libbluray      | dependencies_4x2_bluray.html     | dependencies_4x2_bluray.js       | dependencies_bluray.py         |
| libmetadata    | dependencies_4x2_metadata.html   | dependencies_4x2_metadata.js     | dependencies_metadata.py       |
| libcdtext      | dependencies_4x2_cdtext.html     | dependencies_4x2_cdtext.js       | dependencies_cdtext.py         |
| libmusicbrainz | dependencies_4x2_musicbrainz.html| dependencies_4x2_musicbrainz.js  | dependencies_musicbrainz.py    |
| libtmdb        | dependencies_4x2_tmdb.html       | dependencies_4x2_tmdb.js         | dependencies_tmdb.py           |
| libmqtt        | dependencies_4x2_mqtt.html       | dependencies_4x2_mqtt.js         | dependencies_mqtt.py           |

Index Seite (Dashboard)
========================

| Modul          | HTML Template                    | JavaScript                       | Python Middleware              |
|----------------|----------------------------------|----------------------------------|--------------------------------|
| libsysteminfo  | archiv_3x2_systeminfo.html       | archiv_3x2_systeminfo.js         | archiv_systeminfo.py           |
| libsysteminfo  | outputdir_3x4_systeminfo.html    | outputdir_3x4_systeminfo.js      | outputdir_systeminfo.py        |
| libsysteminfo  | status_3x4_disk2iso.html         | status_3x4_disk2iso.js           | status_disk2iso.py             |
| libsysteminfo  | status_3x4_disk2iso-web.html     | status_3x4_disk2iso-web.js       | status_disk2iso_web.py         |
| libmqtt        | status_3x4_mqtt.html             | status_3x4_mqtt.js               | status_mqtt.py                 |
| libsysteminfo  | livestatus_6x6_systeminfo.html   | livestatus_6x6_systeminfo.js     | (dynamisch geladen)            |

Archiv Seite (Archive)
=======================

| Modul          | HTML Template                    | JavaScript                       | Python Middleware              |
|----------------|----------------------------------|----------------------------------|--------------------------------|
| libmetadata    | archivecard_2x5_metadata.html    | (in archive.js integriert)       | (dynamisch generiert)          |

---

## Anmerkungen

- Alle Widget-Größen (z.B. 4x2, 3x4) beziehen sich auf das Grid-Layout des Webinterfaces
- Die größeren Widgets (z.B. 4x6, 4x7) sind in der Regel komplexere Konfigurationsformulare
- Das livestatus-Widget wird dynamisch aktualisiert und hat keine separate Middleware-Datei
- Archivkarten werden pro Eintrag dynamisch generiert

---

**[← Zurück zur Anhang-Übersicht](../08_Anhaenge.md)** | **[Abhängigkeiten](08-1_Abhaengigkeiten.md)** | **[Prozessanalyse](08-3_Prozessanalyse.md)** →

---

**Version**: 1.2.0 | **Letzte Aktualisierung**: 07.02.2026


