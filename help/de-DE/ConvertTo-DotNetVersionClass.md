---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version:
schema: 2.0.0
---

# ConvertTo-DotNetVersionClass

## SYNOPSIS
Konvertiert eine Versionszeichenfolge in eine standardkonforme .NET-Version-Klasse.

## SYNTAX

```
ConvertTo-DotNetVersionClass [-Version] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Die Funktion ConvertTo-DotNetVersionClass übernimmt eine Versionszeichenfolge als Eingabe und konvertiert sie in eine .NET-Version-Klasse.
Sie normalisiert die Segmente der Versionszeichenfolge und stellt sicher, dass sie genau vier Segmente enthält, indem überzählige Segmente addiert
oder fehlende Segmente mit Nullen aufgefüllt werden.

Wenn die Konvertierung in eine .NET-Version-Klasse fehlschlägt, gibt die Funktion die normalisierte Versionszeichenfolge als Zeichenfolge zurück.

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

Eine Versionszeichenfolge, die in eine standardkonforme .NET-Version-Klasse konvertiert werden soll.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Anwendungsversionsinformationen exportieren](https://eucpilots.com/evergreen/convertversion/)
