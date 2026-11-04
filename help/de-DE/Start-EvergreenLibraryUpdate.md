---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Start-EvergreenLibraryUpdate/
schema: 2.0.0
---

# Start-EvergreenLibraryUpdate

## SYNOPSIS

Startet die Aktualisierung und den Download von Anwendungsinstallationsprogrammen in einer Evergreen-Bibliothek. `Start-EvergreenLibraryUpdate` liest das Bibliotheksmanifest (`EvergreenLibrary.json`), in dem die Anwendungen der Bibliothek festgelegt sind, und verwendet `Get-EvergreenApp` und `Save-EvergreenApp`, um die neuesten Installationsprogramme in die Bibliothek herunterzuladen.

## SYNTAX

```
Start-EvergreenLibraryUpdate [-Path] <FileInfo> [-Proxy <String>] [-ProxyCredential <PSCredential>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Eine Evergreen-Bibliothek kann mehrere Versionen von Anwendungsinstallationsprogrammen verwalten, sodass nicht immer das neueste Installationsprogramm verwendet werden muss. Eine Evergreen-Bibliothek ermöglicht die Installation der für eine bestimmte Umgebung benötigten Anwendungsversion, einschließlich eines Rollbacks auf eine frühere Version. Außerdem können Sie damit Images ohne Internetzugriff erstellen: Laden Sie die Installationsprogramme in die Bibliothek herunter und verwenden Sie sie anschließend beim Erstellen des Images.

`Start-EvergreenLibraryUpdate` startet die Aktualisierung und den Download von Anwendungsinstallationsprogrammen in einer Evergreen-Bibliothek. `Start-EvergreenLibraryUpdate` liest das Bibliotheksmanifest (`EvergreenLibrary.json`), in dem die Anwendungen der Bibliothek festgelegt sind, und verwendet `Get-EvergreenApp` und `Save-EvergreenApp`, um die neuesten Installationsprogramme in die Bibliothek herunterzuladen.

## EXAMPLES

### EXAMPLE 1

```powershell
Start-EvergreenLibraryUpdate -Path "\\server\EvergreenLibrary"
```

Beschreibung:
`Start-EvergreenLibraryUpdate` liest das Bibliotheksmanifest `EvergreenLibrary.json` unter \\server\EvergreenLibrary, in dem die Anwendungen dieser Bibliothek festgelegt sind. Es verwendet `Get-EvergreenApp` und `Save-EvergreenApp`, um die neuesten Installationsprogramme in die Bibliothek herunterzuladen.

## PARAMETERS

### -Path

Gibt den Pfad zur Evergreen-Bibliothek an. Der Pfad muss EvergreenLibrary.json in der erwarteten Struktur enthalten. In dieser Datei sind die in der Bibliothek zu speichernden Anwendungen festgelegt.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WhatIf

Zeigt an, was bei Ausführung des Cmdlets geschehen würde.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Fordert Sie vor der Ausführung des Cmdlets zur Bestätigung auf.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Proxy

Gibt einen Proxyserver für die Anforderung an, anstatt eine direkte Verbindung mit der Internetressource herzustellen. Geben Sie den URI eines Netzwerkproxyservers ein.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyCredential

Gibt ein Benutzerkonto an, das zur Verwendung des mit dem Parameter Proxy angegebenen Proxyservers berechtigt ist. Standardmäßig wird der aktuelle Benutzer verwendet.

Geben Sie einen Benutzernamen ein, z. B. User01 oder Domain01\User01, User@Domain.Com, oder geben Sie ein `PSCredential`-Objekt ein, etwa ein mit dem Cmdlet `Get-Credential` generiertes Objekt.

Dieser Parameter ist nur gültig, wenn der Parameter Proxy ebenfalls im Befehl verwendet wird.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

Start-EvergreenLibraryUpdate akzeptiert einen Zeichenfolgenparameter.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Eine Evergreen-Bibliothek aktualisieren](https://eucpilots.com/evergreen/updatelibrary/)
