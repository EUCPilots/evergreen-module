---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Find-EvergreenApp/
schema: 2.0.0
---

# Find-EvergreenApp

## SYNOPSIS

Affiche un tableau des applications prises en charge par Evergreen.

## SYNTAX

```
Find-EvergreenApp [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION

Renvoie un tableau généré à partir des manifestes d’application internes, qui répertorie les applications prises en charge par Evergreen. Le tableau contient les propriétés Name (nom interne utilisé pour interroger l’application avec `Get-EvergreenApp`), Application (généralement le nom complet de l’éditeur et de l’application) et Link (URL vers des informations officielles de l’éditeur sur l’application).

## EXAMPLES

### EXAMPLE 1

```powershell
Find-EvergreenApp
```

Description :
Renvoie un tableau de toutes les applications actuellement prises en charge par Evergreen.

### EXAMPLE 2

```powershell
Find-EvergreenApp -Name "Edge"
```

Description :
Renvoie un tableau de toutes les applications actuellement prises en charge dont le nom contient « Edge ». 

### EXAMPLE 3

```powershell
Find-EvergreenApp -Name "Microsoft"
```

Description :
Renvoie un tableau de toutes les applications actuellement prises en charge dont le nom contient « Microsoft ». 

## PARAMETERS

### -Name

Nom de l’application dont les détails doivent être renvoyés.
Il peut s’agir du nom complet de l’application ou d’une partie de celui-ci.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

[Rechercher les applications prises en charge](https://eucpilots.com/evergreen/find/)
