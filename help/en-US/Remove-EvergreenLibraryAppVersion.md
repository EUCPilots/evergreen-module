---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Remove-EvergreenLibraryAppVersion/
schema: 2.0.0
---

# Remove-EvergreenLibraryAppVersion

## SYNOPSIS

Removes old application installer versions from an Evergreen library while keeping the newest versions in each application manifest.

## SYNTAX

```powershell
Remove-EvergreenLibraryAppVersion [-Path] <FileInfo> [[-Keep] <Int32>] [[-Name] <String[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

`Remove-EvergreenLibraryAppVersion` prunes historical versions from an Evergreen library application manifest.

The cmdlet validates that `-Path` points to an Evergreen library by checking for `EvergreenLibrary.json`. For each target application, it reads the app manifest (`<ApplicationName>.json`), sorts versions from newest to oldest, keeps the number of entries defined by `-Keep`, removes older installer files from disk, and writes the retained versions back to the app manifest.

By default, all applications in the library are processed and the latest 3 versions are retained.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary"
```

Description:
Processes all applications in the library and keeps the latest 3 versions per application. Older installer files are removed and each app manifest is updated.

### EXAMPLE 2

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 2 -Name "MicrosoftEdge", "Zoom"
```

Description:
Processes only MicrosoftEdge and Zoom, keeping the latest 2 versions in each app manifest and removing older installer files.

### EXAMPLE 3

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 5 -WhatIf
```

Description:
Shows what files and manifests would be changed while keeping the latest 5 versions, without making any changes.

## PARAMETERS

### -Path

Specifies the path to an Evergreen library. The path must exist and contain `EvergreenLibrary.json`.

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

Specifies how many versions to retain in each target application manifest. Older versions are removed.

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

Specifies one or more application names from the library manifest to process. If omitted, all applications are processed.

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

Shows what would happen if the cmdlet runs.

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

Prompts you for confirmation before running the cmdlet.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.FileInfo

`Remove-EvergreenLibraryAppVersion` accepts input by property name for `Path`.

## OUTPUTS

### System.Management.Automation.PSCustomObject

Returns one object per processed application with the following properties:

- `ApplicationName`
- `Keep`
- `KeptCount`
- `RemovedCount`
- `RemovedFiles`
- `ManifestPath`

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Update an Evergreen library](https://eucpilots.com/evergreen/updatelibrary/)
