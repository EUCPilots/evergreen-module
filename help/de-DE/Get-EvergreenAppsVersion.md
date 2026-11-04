---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppsVersion/
schema: 2.0.0
---

# Get-EvergreenAppsVersion

## SYNOPSIS

Gibt die neueste Release-Version des Evergreen-Apps-Repositorys zurück.

## SYNTAX

```
Get-EvergreenAppsVersion [<CommonParameters>]
```

## DESCRIPTION

Fragt die GitHub-Releases-API nach dem neuesten Release des Evergreen-Apps-Repositorys ab und gibt dessen Version zurück.

Es gelten die Ratenbegrenzungen der GitHub-API. Legen Sie die Umgebungsvariable `GITHUB_TOKEN` oder `GH_TOKEN` fest, um eine authentifizierte Anforderung zu verwenden.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenAppsVersion
```

Beschreibung:
Gibt die neueste verfügbare Release-Version des Evergreen-Apps-Repositorys zurück.

## PARAMETERS

### CommonParameters

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.String

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen-Apps-Repository](https://github.com/EUCPilots/evergreen-apps)
