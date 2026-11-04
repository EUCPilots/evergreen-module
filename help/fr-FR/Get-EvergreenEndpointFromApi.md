---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenEndpointFromApi/
schema: 2.0.0
---

# Get-EvergreenEndpointFromApi

## SYNOPSIS

Renvoie un tableau des applications, des points de terminaison et des ports nécessaires à Evergreen pour obtenir les mises à jour d’applications et les URL de téléchargement.

## SYNTAX

```
Get-EvergreenEndpointFromApi [-Name] <String> [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Interroge l’API Evergreen pour renvoyer les URL des points de terminaison et les ports TCP nécessaires pour utiliser Evergreen afin de trouver les versions des applications et de télécharger leurs programmes d’installation.

La liste des points de terminaison renvoyée peut servir à des fins d’audit et à définir une liste d’autorisation pour les pare-feu ou les serveurs proxy lorsque l’accès à Internet est restreint.

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

Description :
Renvoie la liste des URL sources des points de terminaison et des ports de toutes les applications actuellement prises en charge par Evergreen.

### EXAMPLE 2

```powershell
Get-EvergreenEndpointFromApi -Name "MicrosoftEdge", "MicrosoftTeams"

Application    Endpoints                                                                              Ports
-----------    ---------                                                                              -----
MicrosoftEdge  {edgeupdates.microsoft.com, www.microsoft.com, msedge.sf.dl.delivery.mp.microsoft.com} {443}
MicrosoftTeams {config.teams.microsoft.com, www.microsoft.com, statics.teams.cdn.office.net}          {443}
```

Description :
Renvoie la liste des URL sources des points de terminaison et des ports utilisés pour déterminer les versions et les téléchargements de Microsoft Edge et Microsoft Teams.

### EXAMPLE 3

```powershell
Get-EvergreenEndpointFromApi | Select-Object -ExpandProperty Endpoints -Unique

1password.com
app-updates.agilebits.com
downloads.1password.com
cdn.agilebits.com
c.1password.com
```

Description :
Renvoie un tableau simple de toutes les URL de points de terminaison uniques des applications actuellement prises en charge par Evergreen.

## PARAMETERS

### -Name

Nom de l’application dont les détails doivent être renvoyés.
La liste des applications prises en charge est disponible avec `Find-EvergreenApp`.

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

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Array

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Récupérer les points de terminaison utilisés par Evergreen](https://eucpilots.com/evergreen/endpoints/)
