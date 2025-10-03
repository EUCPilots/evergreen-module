---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/New-EvergreenLibrary/
schema: 2.0.0
---

# New-EvergreenLibrary

## SYNOPSIS

Creates an Evergreen library at the specified path.

## SYNTAX

```
New-EvergreenLibrary [-Path] <FileInfo> [-Name <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Creates an Evergreen library at the specified path. An Evergreen library is a directory with a manifest file that defines the application installers to be stored in the library (`EvergreenLibrary.json`). `New-EvergreenLibrary` will create a default library in the specified path, after which the manifest file can be manually updated to define the application list for the library.

## EXAMPLES

### EXAMPLE 1

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Description:
Creates a new Evergreen library in the path \\server\EvergreenLibrary.

### EXAMPLE 2

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary" -Name "AzureVirtualDesktopProd"
```

Description:
Creates a new Evergreen library in the path \\server\EvergreenLibrary. Assigns the name AzureVirtualDesktopProd to the manifest file - `EvergreenLibrary.json`.

## PARAMETERS

### -Path

Specifies the path to the Evergreen library. It is expected that the target location is empty. If the path includes EvergreenLibrary.json, `New-EvergreenLibrary` will not make changes to the manifest.

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

Specify a name for the library.

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

### System.String

New-EvergreenLibrary accepts string parameters.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen-docs
Author: Aaron Parker
## RELATED LINKS

[Create an Evergreen library:](https://eucpilots.com/evergreen-docs/newlibrary/)
