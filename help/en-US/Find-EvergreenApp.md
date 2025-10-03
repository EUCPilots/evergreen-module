---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/Find-EvergreenApp/
schema: 2.0.0
---

# Find-EvergreenApp

## SYNOPSIS

Outputs a table with the applications that Evergreen supports.

## SYNTAX

```
Find-EvergreenApp [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION

Returns a table built from the internal application manifests to list the applications supported by Evergreen. The table includes the Name (the internal name used when querying for the application via `Get-EvergreenApp`), Application (typically the full vendor and application name) and Link (a URL hosting official vendor information about the application) properties.

## EXAMPLES

### EXAMPLE 1

```powershell
Find-EvergreenApp
```

Description:
Returns a table with the all of the applications currently supported by Evergreen.

### EXAMPLE 2

```powershell
Find-EvergreenApp -Name "Edge"
```

Description:
Returns a table with the all of the currently supported applications that match "Edge".

### EXAMPLE 3

```powershell
Find-EvergreenApp -Name "Microsoft"
```

Description:
Returns a table with the all of the currently supported applications that match "Microsoft".

## PARAMETERS

### -Name

The application name to return details for.
This can be the entire application name or a portion thereof.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS

[Find supported applications](https://eucpilots.com/evergreen-docs/find/)
