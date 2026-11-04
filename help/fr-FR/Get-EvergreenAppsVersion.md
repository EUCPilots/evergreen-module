---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppsVersion/
schema: 2.0.0
---

# Get-EvergreenAppsVersion

## SYNOPSIS

Renvoie la dernière version publiée du dépôt des applications Evergreen.

## SYNTAX

```
Get-EvergreenAppsVersion [<CommonParameters>]
```

## DESCRIPTION

Interroge l’API GitHub Releases pour obtenir la dernière version publiée du dépôt des applications Evergreen et en renvoie le numéro.

Les limites de débit de l’API GitHub s’appliquent. Définissez la variable d’environnement `GITHUB_TOKEN` ou `GH_TOKEN` pour effectuer une requête authentifiée.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenAppsVersion
```

Description :
Renvoie la dernière version publiée disponible du dépôt des applications Evergreen.

## PARAMETERS

### CommonParameters

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.String

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Dépôt des applications Evergreen](https://github.com/EUCPilots/evergreen-apps)
