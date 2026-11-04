---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibrary/
schema: 2.0.0
---

# Get-EvergreenLibrary

## SYNOPSIS

Gibt Details zu einer Evergreen-Bibliothek zurück, einschließlich der darin konfigurierten Anwendungen sowie der heruntergeladenen Anwendungsdateien und Versionen.

## SYNTAX

### Path

```
Get-EvergreenLibrary [-Path] <FileInfo> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### URI

```
Get-EvergreenLibrary -Uri <Uri> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gibt Details zu einer Evergreen-Bibliothek am angegebenen Pfad zurück.
Dazu gehören die in `EvergreenLibrary.json` gespeicherten Bibliotheksdetails und die für jede Anwendung in der Bibliothek gespeicherten Versionsinformationen.
Anwendungsdownloads und Versionsinformationen müssen zunächst mit `Invoke-EvergreenLibraryUpdate` heruntergeladen werden.

## EXAMPLES

### Example 1
```
PS C:\> Get-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Gibt Details zur Evergreen-Bibliothek unter \\server\EvergreenLibrary zurück, einschließlich der für jede Anwendung gespeicherten Versionsinformationen.

### Example 2
```
PS C:\> Get-EvergreenLibrary -Uri "https://st5srpuzr5v74.blob.core.windows.net/library/EvergreenLibrary.json"
```

Gibt Details zur Evergreen-Bibliothek im Speicherkonto „st5srpuzr5v74“ im Container „library“ zurück, einschließlich der für jede Anwendung gespeicherten Versionsinformationen.

## PARAMETERS

### -Path

Gibt den lokalen oder UNC-Pfad zur Evergreen-Bibliothek an.

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

### -Uri

Gibt den URI einer Evergreen-Bibliothek an, die im Blob-Speicher eines Azure-Speicherkontos gehostet wird.

```yaml
Type: Uri
Parameter Sets: URI
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.FileInfo

## OUTPUTS

### System.Object

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Eine Evergreen-Bibliothek erstellen](https://eucpilots.com/evergreen/getlibrary.html)
