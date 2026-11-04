---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Find-EvergreenApp/
schema: 2.0.0
---

# Find-EvergreenApp

## SYNOPSIS

Gibt eine Tabelle mit den von Evergreen unterstützten Anwendungen aus.

## SYNTAX

```
Find-EvergreenApp [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION

Gibt eine aus den internen Anwendungsmanifesten erstellte Tabelle mit den von Evergreen unterstützten Anwendungen zurück. Die Tabelle enthält die Eigenschaften Name (der interne Name, der beim Abfragen der Anwendung mit `Get-EvergreenApp` verwendet wird), Application (in der Regel der vollständige Hersteller- und Anwendungsname) und Link (eine URL mit offiziellen Herstellerinformationen zur Anwendung).

## EXAMPLES

### EXAMPLE 1

```powershell
Find-EvergreenApp
```

Beschreibung:
Gibt eine Tabelle mit allen derzeit von Evergreen unterstützten Anwendungen zurück.

### EXAMPLE 2

```powershell
Find-EvergreenApp -Name "Edge"
```

Beschreibung:
Gibt eine Tabelle mit allen derzeit unterstützten Anwendungen zurück, auf die „Edge“ zutrifft.

### EXAMPLE 3

```powershell
Find-EvergreenApp -Name "Microsoft"
```

Beschreibung:
Gibt eine Tabelle mit allen derzeit unterstützten Anwendungen zurück, auf die „Microsoft“ zutrifft.

## PARAMETERS

### -Name

Der Name der Anwendung, für die Details zurückgegeben werden sollen.
Dabei kann es sich um den vollständigen Anwendungsnamen oder einen Teil davon handeln.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Unterstützte Anwendungen suchen](https://eucpilots.com/evergreen/find/)
