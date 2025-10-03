---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/Export-EvergreenManifest/
schema: 2.0.0
---

# Export-EvergreenManifest

## SYNOPSIS

Exports an Evergreen application JSON manifest as a hashtable.

## SYNTAX

```
Export-EvergreenManifest [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Exports an Evergreen application JSON manifest as a hashtable that can be used for various functions including scripting or saving to an external file.

## EXAMPLES

### EXAMPLE 1

```powershell
Export-EvergreenManifest -Name "MicrosoftEdge"
```

Description:
Exports the application manifest for the application "MicrosoftEdge".

## PARAMETERS

### -Name

The application name to return details for. The list of supported applications can be found with `Find-EvergreenApp`.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS

[Getting started with Evergreen](https://eucpilots.com/evergreen-docs/)
