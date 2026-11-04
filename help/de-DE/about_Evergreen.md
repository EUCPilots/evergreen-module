# Evergreen

## about_Evergreen

### SHORT DESCRIPTION

Gibt die neueste Version und die Download-URLs für eine Reihe gängiger Windows-Anwendungen zurück.

### LONG DESCRIPTION

Evergreen ist ein PowerShell-Modul, das die neueste Version und die Download-URLs für eine Reihe gängiger Windows-Anwendungen zurückgibt. Das Modul umfasst einfache Funktionen, die in Skripten für verschiedene Aufgaben verwendet werden können, darunter:

- Die neueste Version einer bestimmten Anwendung abrufen, um sie mit einer bereits installierten oder heruntergeladenen Version zu vergleichen
- Die URL der neuesten Anwendungsversion zurückgeben, um sie zur lokalen Installation oder Bereitstellung auf Zielcomputern herunterzuladen

Evergreen ist für den Einsatz in Lösungen zur Automatisierung von Softwarebereitstellungen vorgesehen. Dazu gehören beispielsweise:

- Imageerstellung mit Hashicorp Packer – Images können mit den neuesten Versionen einer Reihe von Anwendungen erstellt werden
- Anwendungen in Microsoft Endpoint Manager importieren – Configuration Manager oder Microsoft Intune mit den neuesten Anwendungsversionen auf dem aktuellen Stand halten
- Eine Bibliothek mit Anwendungsinstallationsprogrammen erstellen – durch regelmäßiges Ausführen von Evergreen-Funktionen können Sie die aktuelle Version einer Anwendung abrufen, herunterladen und für die spätere Verwendung in einer Anwendungsverzeichnisstruktur speichern
- Manifeste an `Winget`, `Chocolatey` oder ähnliche Dienste übermitteln – Evergreen kann ein Objekt mit Versionsnummer und Download-URL zurückgeben, das zum Erstellen von Manifesten für die neuesten Versionen verwendet werden kann

Zu den wichtigsten Funktionen von Evergreen gehören:

- `Get-EvergreenApp` – gibt Details zum neuesten Release einer Anwendung zurück, einschließlich Versionsnummer und Download-URL
- `Save-EvergreenApp` – vereinfacht das Herunterladen von Anwendungs-URLs, die von `Get-EvergreenApp` zurückgegeben werden
- `Find-EvergreenApp` – listet die vom Modul unterstützten Anwendungen auf
