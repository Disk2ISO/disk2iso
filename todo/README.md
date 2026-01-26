# TODO-Ordner - Übersicht

**Stand:** 26. Januar 2026

## 📋 Hauptdokument

📌 **[Ausstehende_Anpassungen.md](Ausstehende_Anpassungen.md)** - Konsolidierte Master-Liste aller offenen Aufgaben

Diese Datei enthält:
- Alle kritischen Bugs (GitHub Issues)
- Alle geplanten Verbesserungen
- Langfristige Projekt-Konzepte
- Priorisierung nach Dringlichkeit

## 📂 Aktive Konzept-Dokumente

### Kurzfristige Features
- **[ForNextRelease.md](ForNextRelease.md)** - Ideen für Version 1.3.0
  - Auto-Cleanup Cronjob
  - Email-Benachrichtigungen
  - Audio-Normalization
  - ISO-Scanning-Cache

### Langfristige Projekte
- **[Frontend-Modularisierung.md](Frontend-Modularisierung.md)** - Dynamisches JS-Loading System
- **[Metadata-Cache-DB.md](Metadata-Cache-DB.md)** - Lokale Metadaten-Datenbank (10-40x schneller)
- **[Metadata-PlugIn_Konzept.md](Metadata-PlugIn_Konzept.md)** - Vollständige Plugin-Architektur

### Bug-Tracking
- **[GitHub-Issues.md](GitHub-Issues.md)** - Aktuelle GitHub Issues (14 Open, 6 Closed)

## 📚 Archiv

Abgeschlossene Aufgaben wurden nach [../doc/archive/](../doc/archive/) verschoben:

- ✅ `Logging-Konvertierung.md` - Alle 248 log_message Aufrufe konvertiert
- ✅ `Metadata-BEFORE-vs-AFTER.md` - BEFORE Copy Strategie implementiert
- ✅ `load-order-analysis.md` - Modul-Ladereihenfolge optimiert
- ✅ `module_dependencies_analysis.md` - Abhängigkeiten dokumentiert

## 🔄 Workflow

1. **Neue Aufgabe erkannt?** → Zu [Ausstehende_Anpassungen.md](Ausstehende_Anpassungen.md) hinzufügen
2. **Aufgabe abgeschlossen?** → Aus Liste entfernen, Status aktualisieren
3. **Konzept benötigt?** → Eigenes Dokument erstellen, in Ausstehende_Anpassungen verlinken
4. **Alles erledigt?** → Dokument nach `doc/archive/` verschieben

## 🎯 Aktuelle Prioritäten

Siehe [Ausstehende_Anpassungen.md](Ausstehende_Anpassungen.md) Sektion "Empfohlene Arbeitsreihenfolge"

**Sofort:**
1. GitHub #20 Template-Fix (5 Min)
2. GitHub #11 MQTT Debug (2 Std)
3. GitHub #9 ISO-Anzeige (4 Std)

**Diese Woche:**
4. Auto-Cleanup Cronjob (1 Tag)
5. GitHub #15 Fehlerbehandlung (2 Tage)
