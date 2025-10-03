---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/Get-EvergreenAppFromApi/
schema: 2.0.0
---

# Get-EvergreenAppFromApi

## SYNOPSIS

Returns the latest version and download URL/s for an application supported by the Evergreen module. This function returns the same data as Get-EvergreenApp, but queries the Evergreen App Tracker API for this data.

## SYNTAX

```
Get-EvergreenAppFromApi [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Returns the latest version and download URL/s for an application supported by the Evergreen module. This function returns the same data as Get-EvergreenApp, but queries the Evergreen App Tracker API for this data. Data for the API is from a key/value store updated by Get-EvergreenApp every 12-hours.

## EXAMPLES

### Example 1

```powershell
Get-EvergreenAppFromApi -Name "MicrosoftEdge"

Version      : 89.0.774.76
Platform     : Windows
Channel      : Stable
Release      : Enterprise
Architecture : x64
Date         : 12/4/2021
Hash         : 9E7A29B4BE6E1CD707F80B4B79008F19D2D5DD5C774D317A493EC6DE5BE0B7D7
URI          : https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/4d12f620-174c-4259-85e6-8a80ea45ff10/MicrosoftEdgeEnterpriseX64.msi
```

Description:
Returns the current version and download URLs for Microsoft Edge using the official Microsoft Edge update API at [https://edgeupdates.microsoft.com/api/products](https://edgeupdates.microsoft.com/api/products).

### EXAMPLE 2

```powershell
Get-EvergreenAppFromApi -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

Description:
Returns the current version and download URL for the Stable channel of the 64-bit Enterprise ring of Microsoft Edge.

## PARAMETERS

### -Name

The application name to return details for.
The list of supported applications can be found with `Find-EvergreenApp`.

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

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS

[https://eucpilots.com/evergreen-docs/invoke/](https://eucpilots.com/evergreen-docs/invoke/)
