---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenManifest/
schema: 2.0.0
---

# Export-EvergreenManifest

## SYNOPSIS

Exportiert ein JSON-Manifest einer Evergreen-Anwendung als Hashtabelle.

## SYNTAX

```
Export-EvergreenManifest [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Exportiert ein JSON-Manifest einer Evergreen-Anwendung als Hashtabelle, die für verschiedene Funktionen verwendet werden kann, etwa für Skripte oder zum Speichern in einer externen Datei.

## EXAMPLES

### EXAMPLE 1

```powershell
Export-EvergreenManifest -Name "MicrosoftEdge"
```

Beschreibung:
Exportiert das Anwendungsmanifest für die Anwendung „MicrosoftEdge“.

## PARAMETERS

### -Name

Der Name der Anwendung, für die Details zurückgegeben werden sollen. Die Liste der unterstützten Anwendungen finden Sie mit `Find-EvergreenApp`.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Erste Schritte mit Evergreen](https://eucpilots.com/evergreen/)
