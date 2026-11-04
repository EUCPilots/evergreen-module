---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenApp/
schema: 2.0.0
---

# Export-EvergreenApp

## SYNOPSIS

Exportiert die mit `Get-EvergreenApp` erfassten Anwendungsdetails in eine externe JSON-Datei. Diese Funktion liest vorhandene JSON-Daten für die Anwendung ein, fügt die neuen Versionsdaten hinzu, sortiert nach eindeutigen Versionen und schreibt anschließend den neuen Inhalt zurück in die Zieldatei.

## SYNTAX

```
Export-EvergreenApp [-InputObject] <Array> -Path <FileInfo> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Exportiert die mit `Get-EvergreenApp` erfassten Anwendungsdetails in eine externe JSON-Datei. Diese Funktion liest vorhandene JSON-Daten für die Anwendung ein, fügt die neuen Versionsdaten hinzu, sortiert nach eindeutigen Versionen und schreibt anschließend den neuen Inhalt zurück in die Zieldatei.

## EXAMPLES

### EXAMPLE 1

```powershell
$OneDrive = Get-EvergreenApp -Name "MicrosoftOneDrive"
Save-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive"
Export-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive\MicrosoftOneDrive.json"
```

Beschreibung:
`Get-EvergreenApp` gibt Versionsinformationen für `MicrosoftOneDrive` zurück. Anschließend wird `Save-EvergreenApp` verwendet, um die zurückgegebenen Installationsprogramme unter `C:\Evergreen\OneDrive` zu speichern. Mit `Export-EvergreenApp` werden die Versionsinformationen dann in `C:\Evergreen\OneDrive\MicrosoftOneDrive.json` gespeichert. Sind in der Zieldatei bereits Versionsinformationen enthalten, werden die zusätzlichen Versionsinformationen in derselben Datei gespeichert.

## PARAMETERS

### -InputObject

`Export-EvergreenApp` akzeptiert das PSObject aus `Get-EvergreenApp`.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

Gibt den Pfad zur JSON-Datei an, in der Versionsinformationen gespeichert werden. Wenn die Datei nicht vorhanden ist, muss das übergeordnete Verzeichnis bereits vorhanden sein.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### -WhatIf

Zeigt an, was bei Ausführung des Cmdlets geschehen würde. Das Cmdlet wird nicht ausgeführt.

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

### CommonParameters

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Export-EvergreenApp akzeptiert die Ausgabe von Get-EvergreenApp.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Anwendungsversionsinformationen exportieren](https://eucpilots.com/evergreen/export/)
