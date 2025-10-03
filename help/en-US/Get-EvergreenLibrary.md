---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/Get-EvergreenLibrary/
schema: 2.0.0
---

# Get-EvergreenLibrary

## SYNOPSIS

Returns details about an Evergreen library including details about the applications configured in the library and the downloaded application binaries and versions.

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
Returns details about an Evergreen library at a specified path.
This will include details of the library stored in `EvergreenLibrary.json` and application version information stored for each application in the library.
Application downloads and application version information must first be downloaded via `Invoke-EvergreenLibraryUpdate`.

## EXAMPLES

### Example 1
```
PS C:\> Get-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Returns details about the Evergreen library at \\server\EvergreenLibrary, including application version information stored for each application.

### Example 2
```
PS C:\> Get-EvergreenLibrary -Uri "https://st5srpuzr5v74.blob.core.windows.net/library/EvergreenLibrary.json"
```

Returns details about the Evergreen library at on the storage account - "st5srpuzr5v74" under the container "library", including application version information stored for each application.

## PARAMETERS

### -Path

Specify the local or UNC path to the Evergreen Library.

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

Specify the URI to an Evergreen Library hosted on blob storage on an Azure storage account.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.FileInfo

## OUTPUTS

### System.Object

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS

[Create an Evergreen library](https://eucpilots.com/evergreen-docs/getlibrary.html)
