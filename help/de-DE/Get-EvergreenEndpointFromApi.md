---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenEndpointFromApi/
schema: 2.0.0
---

# Get-EvergreenEndpointFromApi

## SYNOPSIS

Gibt ein Array mit den Anwendungen, Endpunkten und Ports zurück, die Evergreen zum Abrufen von Anwendungsupdates und Download-URLs benötigt.

## SYNTAX

```
Get-EvergreenEndpointFromApi [-Name] <String> [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Fragt die Evergreen-API ab, um Endpunkt-URLs und TCP-Ports zurückzugeben, die Evergreen benötigt, um Anwendungsversionen zu finden und Installationsprogramme herunterzuladen.

Die zurückgegebene Endpunktliste kann zu Prüfzwecken sowie zum Definieren einer Zulassungsliste für Firewalls oder Proxyserver verwendet werden, wenn der Internetzugriff eingeschränkt ist.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenEndpointFromApi

Application  Endpoints                                                                              Ports
-----------  ---------                                                                              -----
1Password    {1password.com, app-updates.agilebits.com, downloads.1password.com, cdn.agilebits.com} {443}
1Password7   {1password.com, c.1password.com, download.app.com"}                                    {443}
1PasswordCLI {app-updates.agilebits.com, cache.agilebits.com, developer.1password.com}              {443}
7zip         {nchc.dl.sourceforge.net, sourceforge.net, www.7-zip.org, versaweb.dl.sourceforge.net} {443}
7ZipZS       {api.github.com, mcmilk.de, github.com}                                                {443}
```

Beschreibung:
Gibt die Liste der Endpunkt-URL-Quellen und Ports für alle derzeit von Evergreen unterstützten Anwendungen zurück.

### EXAMPLE 2

```powershell
Get-EvergreenEndpointFromApi -Name "MicrosoftEdge", "MicrosoftTeams"

Application    Endpoints                                                                              Ports
-----------    ---------                                                                              -----
MicrosoftEdge  {edgeupdates.microsoft.com, www.microsoft.com, msedge.sf.dl.delivery.mp.microsoft.com} {443}
MicrosoftTeams {config.teams.microsoft.com, www.microsoft.com, statics.teams.cdn.office.net}          {443}
```

Beschreibung:
Gibt die Liste der Endpunkt-URL-Quellen und Ports zum Ermitteln der Anwendungsversionen und Downloads für Microsoft Edge und Microsoft Teams zurück.

### EXAMPLE 3

```powershell
Get-EvergreenEndpointFromApi | Select-Object -ExpandProperty Endpoints -Unique

1password.com
app-updates.agilebits.com
downloads.1password.com
cdn.agilebits.com
c.1password.com
```

Beschreibung:
Gibt ein einfaches Array aller eindeutigen Endpunkt-URLs für die derzeit von Evergreen unterstützten Anwendungen zurück.

## PARAMETERS

### -Name

Der Name der Anwendung, für die Details zurückgegeben werden sollen.
Die Liste der unterstützten Anwendungen finden Sie mit `Find-EvergreenApp`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Array

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Von Evergreen verwendete Endpunkte abrufen](https://eucpilots.com/evergreen/endpoints/)
