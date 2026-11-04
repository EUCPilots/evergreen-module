---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppFromApi/
schema: 2.0.0
---

# Get-EvergreenAppFromApi

## SYNOPSIS

Renvoie la dernière version et les URL de téléchargement d’une application prise en charge par le module Evergreen. Cette fonction renvoie les mêmes données que Get-EvergreenApp, mais interroge l’API Evergreen App Tracker pour les obtenir.

## SYNTAX

```
Get-EvergreenAppFromApi [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Renvoie la dernière version et les URL de téléchargement d’une application prise en charge par le module Evergreen. Cette fonction renvoie les mêmes données que Get-EvergreenApp, mais interroge l’API Evergreen App Tracker pour les obtenir. Les données de l’API proviennent d’un magasin clé/valeur mis à jour par Get-EvergreenApp toutes les 12 heures.

## EXAMPLES

### Example 1

```powershell
Get-EvergreenAppFromApi -Name "MicrosoftEdge"

Version      : 89.0.774.76
Platform     : Windows
Channel      : Stable
Release      : Enterprise
Architecture : x64
Date         : 12/4/2021
Hash         : 9E7A29B4BE6E1CD707F80B4B79008F19D2D5DD5C774D317A493EC6DE5BE0B7D7
URI          : https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/4d12f620-174c-4259-85e6-8a80ea45ff10/MicrosoftEdgeEnterpriseX64.msi
```

Description :
Renvoie la version actuelle et les URL de téléchargement de Microsoft Edge à l’aide de l’API officielle de mise à jour Microsoft Edge à l’adresse [https://edgeupdates.microsoft.com/api/products](https://edgeupdates.microsoft.com/api/products).

### EXAMPLE 2

```powershell
Get-EvergreenAppFromApi -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

Description :
Renvoie la version actuelle et l’URL de téléchargement de Microsoft Edge pour le canal Stable et l’anneau Enterprise 64 bits.

## PARAMETERS

### -Name

Nom de l’application dont les détails doivent être renvoyés.
La liste des applications prises en charge est disponible avec `Find-EvergreenApp`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[https://eucpilots.com/evergreen/invoke/](https://eucpilots.com/evergreen/invoke/)
