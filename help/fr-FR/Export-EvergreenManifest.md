---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenManifest/
schema: 2.0.0
---

# Export-EvergreenManifest

## SYNOPSIS

Exporte un manifeste JSON d’application Evergreen sous forme de table de hachage.

## SYNTAX

```
Export-EvergreenManifest [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Exporte un manifeste JSON d’application Evergreen sous forme de table de hachage, qui peut être utilisé par différentes fonctions, notamment dans des scripts ou pour être enregistré dans un fichier externe.

## EXAMPLES

### EXAMPLE 1

```powershell
Export-EvergreenManifest -Name "MicrosoftEdge"
```

Description :
Exporte le manifeste de l’application « MicrosoftEdge ».

## PARAMETERS

### -Name

Nom de l’application dont les détails doivent être renvoyés. La liste des applications prises en charge est disponible avec `Find-EvergreenApp`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
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

[Prise en main d’Evergreen](https://eucpilots.com/evergreen/)
