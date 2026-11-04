---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Remove-EvergreenLibraryAppVersion/
schema: 2.0.0
---

# Remove-EvergreenLibraryAppVersion

## SYNOPSIS

Entfernt alte Versionen von Anwendungsinstallationsprogrammen aus einer Evergreen-Bibliothek und behält dabei die neuesten Versionen in jedem Anwendungsmanifest bei.

## SYNTAX

```powershell
Remove-EvergreenLibraryAppVersion [-Path] <FileInfo> [[-Keep] <Int32>] [[-Name] <String[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

`Remove-EvergreenLibraryAppVersion` entfernt ältere Versionen aus einem Anwendungsmanifest einer Evergreen-Bibliothek.

Das Cmdlet überprüft, ob `-Path` auf eine Evergreen-Bibliothek verweist, indem es nach `EvergreenLibrary.json` sucht. Für jede Zielanwendung liest es das Anwendungsmanifest (`<ApplicationName>.json`), sortiert die Versionen von neu nach alt, behält die mit `-Keep` festgelegte Anzahl von Einträgen bei, entfernt ältere Installationsdateien vom Datenträger und schreibt die beibehaltenen Versionen zurück in das Anwendungsmanifest.

Standardmäßig werden alle Anwendungen in der Bibliothek verarbeitet und jeweils die neuesten 3 Versionen beibehalten.

Die Aufbewahrungsgrenze zählt einzelne Manifesteinträge sowohl in Windows PowerShell 5.1 als auch in PowerShell 7. Das beibehaltene Manifest bleibt ein JSON-Array, auch wenn `-Keep 1` verwendet wird. Installationspfade können absolut, relativ zum Anwendungsverzeichnis oder Arrays von Pfaden sein, die von älteren Modulversionen aufgezeichnet wurden. Entfernt werden nur Installationsdateien, die in ausgesonderten Einträgen aufgeführt sind. Dateien, auf die auch beibehaltene Einträge verweisen, bleiben erhalten. Pfade außerhalb des Anwendungsverzeichnisses sowie Pfade, die Reparse Points durchlaufen, werden übersprungen. Leere Versionsverzeichnisse werden nicht entfernt.

Dateien, die nach einem früheren Bereinigungsvorgang zurückgeblieben sind, können durch erneute Ausführung dieses Cmdlets nicht entfernt werden, wenn ihre Einträge nicht mehr im Manifest enthalten sind. Dieses Cmdlet sucht nicht nach nicht erfassten Installationsdateien.

Verwenden Sie `-Verbose` zur Fehlerbehebung bei der Bibliotheksüberprüfung, Anwendungsauswahl, beim Lesen von Manifesten, Sortieren von Versionen, Beibehalten und Aussondern von Einträgen, Überspringen von Installationsdateien und Aktualisieren von Manifesten. Die Meldungen unterscheiden geplante Bereinigungen von tatsächlich entfernten Dateien und weisen auf Aktionen hin, die durch `-WhatIf` übersprungen oder bei der Bestätigung abgelehnt wurden. Ausführliche Meldungen ändern die zurückgegebenen Objekte nicht.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary"
```

Beschreibung:
Verarbeitet alle Anwendungen in der Bibliothek und behält für jede Anwendung die neuesten 3 Versionen bei. Ältere Installationsdateien werden entfernt und jedes Anwendungsmanifest wird aktualisiert.

### EXAMPLE 2

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 2 -Name "MicrosoftEdge", "Zoom"
```

Beschreibung:
Verarbeitet nur MicrosoftEdge und Zoom, behält in jedem Anwendungsmanifest die neuesten 2 Versionen bei und entfernt ältere Installationsdateien.

### EXAMPLE 3

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 5 -WhatIf
```

Beschreibung:
Zeigt an, welche Dateien und Manifeste geändert würden, wobei die neuesten 5 Versionen beibehalten werden, ohne Änderungen vorzunehmen.

### EXAMPLE 4

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Name "MicrosoftEdge" -Keep 3 -WhatIf -Verbose
```

Beschreibung:
Zeigt ausführliche Fehlersuchmeldungen und geplante Änderungen für MicrosoftEdge an, ohne Installationsprogramme zu löschen oder das Manifest zu aktualisieren.

## PARAMETERS

### -Path

Gibt den Pfad zu einer Evergreen-Bibliothek an. Der Pfad muss vorhanden sein und `EvergreenLibrary.json` enthalten.

```yaml
Type: FileInfo
Parameter Sets: Path
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Keep

Gibt an, wie viele Versionen in jedem Zielanwendungsmanifest beibehalten werden. Ältere Versionen werden entfernt.

```yaml
Type: Int32
Parameter Sets: Path
Aliases:

Required: False
Position: 1
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Gibt einen oder mehrere Anwendungsnamen aus dem Bibliotheksmanifest an, die verarbeitet werden sollen. Wenn nichts angegeben wird, werden alle Anwendungen verarbeitet.

```yaml
Type: String[]
Parameter Sets: Path
Aliases:

Required: False
Position: 2
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

### System.IO.FileInfo

`Remove-EvergreenLibraryAppVersion` akzeptiert Eingaben über den Eigenschaftsnamen für `Path`.

## OUTPUTS

### System.Management.Automation.PSCustomObject

Gibt für jede verarbeitete Anwendung ein Objekt mit den folgenden Eigenschaften zurück:

- `ApplicationName`
- `Keep`
- `KeptCount`
- `PrunedCount`: Anzahl der zum Entfernen ausgewählten Einträge.
- `RemovedCount`: Anzahl der aus dem Manifest entfernten Einträge.
- `RemovedFileCount`: Anzahl der tatsächlich gelöschten Installationsdateien.
- `RemovedFiles`: Pfade der tatsächlich gelöschten Installationsdateien.
- `ManifestPath`

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Eine Evergreen-Bibliothek aktualisieren](https://eucpilots.com/evergreen/updatelibrary/)
