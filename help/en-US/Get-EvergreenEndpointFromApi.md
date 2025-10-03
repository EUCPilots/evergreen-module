---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/Get-EvergreenEndpointFromApi/
schema: 2.0.0
---

# Get-EvergreenEndpointFromApi

## SYNOPSIS

Returns an array of applications, endpoints and ports required by Evergreen to source application updates and URLs for application downloads.

## SYNTAX

```
Get-EvergreenEndpointFromApi [-Name] <String> [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Queries the Evergreen API to return endpoints URLs and TCP ports required to use Evergreen to find application versions and download application installers.

The list of endpoints returned can be used for auditing purposes and to define an allow list for firewalls or proxy servers where internet access is restricted.

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

Description:
Returns the list of endpoint URL sources and ports for all of the applications currently supported by Evergreen.

### EXAMPLE 2

```powershell
Get-EvergreenEndpointFromApi -Name "MicrosoftEdge", "MicrosoftTeams"

Application    Endpoints                                                                              Ports
-----------    ---------                                                                              -----
MicrosoftEdge  {edgeupdates.microsoft.com, www.microsoft.com, msedge.sf.dl.delivery.mp.microsoft.com} {443}
MicrosoftTeams {config.teams.microsoft.com, www.microsoft.com, statics.teams.cdn.office.net}          {443}
```

Description:
Returns the list of endpoint URL sources and ports for determining the application versions and downloads for Microsoft Edge and Microsoft Teams.

### EXAMPLE 3

```powershell
Get-EvergreenEndpointFromApi | Select-Object -ExpandProperty Endpoints -Unique

1password.com
app-updates.agilebits.com
downloads.1password.com
cdn.agilebits.com
c.1password.com
```

Description:
Returns a simple array of all of the unique endpoint URLs for the applications currently supported by Evergreen.

## PARAMETERS

### -Name

The application name to return details for.
The list of supported applications can be found with `Find-EvergreenApp`.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Array

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS

[Retrieve endpoints used by Evergreen](https://eucpilots.com/evergreen-docs/endpoints/)
