---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version:
schema: 2.0.0
---

# ConvertTo-DotNetVersionClass

## SYNOPSIS
Converts a version string to a standard .NET compliant Version class.

## SYNTAX

```
ConvertTo-DotNetVersionClass [-Version] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-DotNetVersionClass function takes a version string as input and converts it into a .NET Version class. 
It normalizes the segments of the version string, ensuring it has exactly four segments by either summing excess segments 
or padding with zeros if there are fewer than four segments.

If the conversion to a .NET Version class fails, the function will return the normalized version string as a string.

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
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS

[Export application version information](https://eucpilots.com/evergreen-docs/convertversion/)
