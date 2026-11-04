---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/New-EvergreenLibrary/
schema: 2.0.0
---

# New-EvergreenLibrary

## SYNOPSIS

Erstellt am angegebenen Pfad eine Evergreen-Bibliothek.

## SYNTAX

```
New-EvergreenLibrary [-Path] <FileInfo> [-Name <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Erstellt am angegebenen Pfad eine Evergreen-Bibliothek. Eine Evergreen-Bibliothek ist ein Verzeichnis mit einer Manifestdatei (`EvergreenLibrary.json`), in der die in der Bibliothek zu speichernden Anwendungsinstallationsprogramme festgelegt sind. `New-EvergreenLibrary` erstellt am angegebenen Pfad eine Standardbibliothek. Anschließend kann die Manifestdatei manuell bearbeitet werden, um die Anwendungsliste der Bibliothek festzulegen.

## EXAMPLES

### EXAMPLE 1

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Beschreibung:
Erstellt eine neue Evergreen-Bibliothek unter dem Pfad \\server\EvergreenLibrary.

### EXAMPLE 2

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary" -Name "AzureVirtualDesktopProd"
```

Beschreibung:
Erstellt eine neue Evergreen-Bibliothek unter dem Pfad \\server\EvergreenLibrary. Weist der Manifestdatei `EvergreenLibrary.json` den Namen AzureVirtualDesktopProd zu.

## PARAMETERS

### -Path

Gibt den Pfad zur Evergreen-Bibliothek an. Der Zielspeicherort sollte leer sein. Wenn der Pfad EvergreenLibrary.json enthält, nimmt `New-EvergreenLibrary` keine Änderungen am Manifest vor.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name

Gibt einen Namen für die Bibliothek an.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Zeigt an, was bei Ausführung des Cmdlets geschehen würde.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Fordert Sie vor der Ausführung des Cmdlets zur Bestätigung auf.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

New-EvergreenLibrary akzeptiert Zeichenfolgenparameter.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen
Author: Aaron Parker
## RELATED LINKS

[Eine Evergreen-Bibliothek erstellen:](https://eucpilots.com/evergreen/newlibrary/)
