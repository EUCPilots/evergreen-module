---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppFromLibrary/
schema: 2.0.0
---

# Get-EvergreenAppFromLibrary

## SYNOPSIS

Returns details for a specified application from an Evergreen library.

## SYNTAX

```
Get-EvergreenAppFromLibrary [-Inventory] <PSObject> [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Returns details for a specified application from an Evergreen Library including all version and binaries / installer information stored in the library. Details returned are in descending order by version number so that the latest version can be used or a specific version filtered with Where-Object.

## EXAMPLES

### Example 1

```powershell
PS C:\> Get-EvergreenLibrary -Path "\\server\EvergreenLibrary" | Get-EvergreenAppFromLibrary -Name "MicrosoftVisualStudioCode"

Version      : 1.74.3
URI          : https://az764295.vo.msecnd.net/stable/97dec172d3256f8ca4bfb2143f3f76b503ca0534/VSCodeSetup-x64-1.74.3.exe
Sha256       : cea32aa015116f8346e054c59497908f6da6059361c1b33d5b68059031f2dc97
Platform     : win32-x64
Path         : \\server\EvergreenLibrary\MicrosoftVisualStudioCode\Stable\1.74.3\x64\VSCodeSetup-x64-1.74.3.exe
Channel      : Stable
Architecture : x64

Version      : 1.74.0
URI          : https://az764295.vo.msecnd.net/stable/5235c6bb189b60b01b1f49062f4ffa42384f8c91/VSCodeSetup-x64-1.74.0.exe
Sha256       : fbe977aa69a1c1438d2c2b9d5525415e1fd8d97b6dbb149301a7c3bf3a84b14a
Platform     : win32-x64
Path         : \\server\EvergreenLibrary\MicrosoftVisualStudioCode\Stable\1.74.3\x64\VSCodeSetup-x64-1.74.0.exe
Channel      : Stable
Architecture : x64
```

Returns details about Microsoft Visual Studio Code from the Evergreen library at \\server\EvergreenLibrary that is sent to Get-EvergreenAppFromLibrary from Get-EvergreenLibrary via the pipeline.

### Example 2

```powershell
PS C:\> $Library = Get-EvergreenLibrary -Path "\\server\EvergreenLibrary"
PS C:\> Get-EvergreenAppFromLibrary -Inventory $Library -Name "MicrosoftTeams"

Version      : 1.5.00.36367
URI          : https://statics.teams.cdn.office.net/production-windows-x64/1.5.00.36367/Teams_windows_x64.msi
Type         : msi
Ring         : General
Path         : \\server\EvergreenLibrary\MicrosoftTeams\General\1.5.00.36367\x64\Teams_windows_x64.msi
Architecture : x64

Version      : 1.5.00.31168
URI          : https://statics.teams.cdn.office.net/production-windows-x64/1.5.00.31168/Teams_windows_x64.msi
Type         : msi
Ring         : General
Path         : \\server\EvergreenLibrary\MicrosoftTeams\General\1.5.00.31168\x64\Teams_windows_x64.msi
Architecture : x64
```

Uses Get-EvergreenLibrary to place details about the Evergreen library at \\server\EvergreenLibrary into an object called $Library, which is then used on the command line for Get-EvergreenAppFromLibrary to return details about Microsoft Teams. `Get-EvergreenLibraryApp` is an alias for this command.

## PARAMETERS

### -Inventory

The inventory object returned by `Get-EvergreenLibrary`. The command requires the object to have an `Inventory` property.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue, ByPropertyName)
Accept wildcard characters: False
```

### -Name

The application name to return details for.
The list of supported applications can be found with `Find-EvergreenApp`.

```yaml
Type: String
Parameter Sets: (All)
Aliases: ApplicationName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Create an Evergreen library:](https://eucpilots.com/evergreen/getlibrary.html)
