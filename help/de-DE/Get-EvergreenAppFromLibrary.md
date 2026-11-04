---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibraryApp/
schema: 2.0.0
---

# Get-EvergreenLibraryApp

## SYNOPSIS

Gibt Details zu einer angegebenen Anwendung aus einer Evergreen-Bibliothek zurück. Die Ausgabe enthält Versions- und Pfadinformationen, mit denen Anwendungsdateien aus der Bibliothek installiert werden können.

## SYNTAX

```
Get-EvergreenLibraryApp [-Inventory] <PSObject> [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Gibt Details zu einer angegebenen Anwendung aus einer Evergreen-Bibliothek zurück, einschließlich aller in der Bibliothek gespeicherten Versions- und Binär-/Installationsprogramminformationen. Die Details werden nach Versionsnummer absteigend sortiert, sodass die neueste Version verwendet oder mit Where-Object eine bestimmte Version gefiltert werden kann.

## EXAMPLES

### Example 1

```powershell
PS C:\> Get-EvergreenLibrary -Path "\\server\EvergreenLibrary" | Get-EvergreenLibraryApp -Name "MicrosoftVisualStudioCode"

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

Gibt Details zu Microsoft Visual Studio Code aus der Evergreen-Bibliothek unter \\server\EvergreenLibrary zurück, die über die Pipeline von Get-EvergreenLibrary an Get-EvergreenLibraryApp übergeben wird.

### Example 2

```powershell
PS C:\> $Library = Get-EvergreenLibrary -Path "\\server\EvergreenLibrary"
PS C:\> Get-EvergreenLibraryApp -Inventory $Library -Name "MicrosoftTeams"

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

Verwendet Get-EvergreenLibrary, um Details zur Evergreen-Bibliothek unter \\server\EvergreenLibrary in einem Objekt namens $Library abzulegen. Dieses Objekt wird dann in der Befehlszeile mit Get-EvergreenLibraryApp verwendet, um Details zu Microsoft Teams zurückzugeben.

## PARAMETERS

### -InputObject

`Get-EvergreenLibraryApp` akzeptiert die PSObject-Ausgabe von `Get-EvergreenLibrary`. `Get-EvergreenLibraryApp` prüft, ob dieses Objekt die Eigenschaft Inventory enthält, und löst andernfalls einen Fehler aus.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name

Der Name der Anwendung, für die Details zurückgegeben werden sollen.
Die Liste der unterstützten Anwendungen finden Sie mit `Find-EvergreenApp`.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Eine Evergreen-Bibliothek erstellen:](https://eucpilots.com/evergreen/getlibrary.html)
