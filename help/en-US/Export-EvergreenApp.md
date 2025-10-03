---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/Export-EvergreenApp/
schema: 2.0.0
---

# Export-EvergreenApp

## SYNOPSIS

Exports application details gathered by `Get-EvergreenApp` to an external JSON file. This function reads any existing JSON for that application, adds the new version content, sorts for unique versions, then outputs the new content back to the target JSON file.

## SYNTAX

```
Export-EvergreenApp [-InputObject] <Array> -Path <FileInfo> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Export application details gathered by `Get-EvergreenApp` to an external JSON file. This function reads any existing JSON for that application, adds the new version content, sorts for unique versions, then outputs the new content back to the target JSON file.

## EXAMPLES

### EXAMPLE 1

```powershell
$OneDrive = Get-EvergreenApp -Name "MicrosoftOneDrive"
Save-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive"
Export-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive\MicrosoftOneDrive.json"
```

Description:
`Get-EvergreenApp` returns version information for `MicrosoftOneDrive`. `Save-EvergreenApp` is then used to save the returned installers to `C:\Evergreen\OneDrive`. Version information is then saved to `C:\Evergreen\OneDrive\MicrosoftOneDrive.json` with `Export-EvergreenApp`. If version information is already stored in the target file, the additional version information is saved to the same file.

## PARAMETERS

### -InputObject

`Export-EvergreenApp` accepts the PSObject from `Get-EvergreenApp`.

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

Specifies a path to the JSON file where version information will be stored. If the file does not exist, the parent directory must already exist.

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

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Export-EvergreenApp accepts the output from Get-EvergreenApp.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS

[Export application version information](https://eucpilots.com/evergreen-docs/export/)
