---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version:
schema: 2.0.0
---

# ConvertTo-DotNetVersionClass

## SYNOPSIS
Converts a version string to a four-component .NET Version.

## SYNTAX

```
ConvertTo-DotNetVersionClass [-Version] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Separators (periods, underscores, plus signs, and hyphens) delimit version components. Numeric components must use ASCII digits. Text components are mapped to stable SHA-256-derived integers; this allows conversion but does not preserve semantic version ordering, so the resulting .NET Version should not be used to compare prerelease or other text-labeled versions.

Versions with fewer than four components are padded with zeros. Components after the third are summed into the fourth component, which saturates at Int32.MaxValue. Invalid or out-of-range numeric components result in an error.

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

A version string to convert to a standard .NET compliant version class.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

A version string with numeric or text components separated by periods, underscores, plus signs, or hyphens.

## OUTPUTS

### System.Version

A four-component .NET Version. Text-derived components are not suitable for semantic version ordering.

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Export application version information](https://eucpilots.com/evergreen/convertversion/)
