---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version:
schema: 2.0.0
---

# ConvertTo-DotNetVersionClass

## SYNOPSIS
Convertit une chaîne de version en une classe Version conforme aux normes .NET.

## SYNTAX

```
ConvertTo-DotNetVersionClass [-Version] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
La fonction ConvertTo-DotNetVersionClass prend une chaîne de version en entrée et la convertit en une classe Version .NET. 
Elle normalise les segments de la chaîne de version pour en obtenir exactement quatre, en additionnant les segments excédentaires 
ou en ajoutant des zéros si elle en comporte moins de quatre.

Si la conversion en classe Version .NET échoue, la fonction renvoie la chaîne de version normalisée sous forme de chaîne.

## EXAMPLES

### EXAMPLE 1

```
ConvertTo-DotNetVersionClass -Version "1.2.3.4"
1.2.3.4
```

### EXAMPLE 2

```
ConvertTo-DotNetVersionClass -Version "1.2.3"
1.2.3.0
```

### EXAMPLE 3

```
ConvertTo-DotNetVersionClass -Version "1.2.3.4.5"
1.2.3.9
```

## PARAMETERS

### -Version

Chaîne de version à convertir en classe de version conforme aux normes .NET.

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

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Exporter les informations de version d’une application](https://eucpilots.com/evergreen/convertversion/)
