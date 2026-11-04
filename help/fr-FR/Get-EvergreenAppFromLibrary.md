---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibraryApp/
schema: 2.0.0
---

# Get-EvergreenLibraryApp

## SYNOPSIS

Renvoie les détails d’une application spécifiée dans une bibliothèque Evergreen. Le résultat inclut les informations de version et de chemin d’accès de l’application, qui peuvent servir à installer les fichiers binaires de l’application depuis la bibliothèque.

## SYNTAX

```
Get-EvergreenLibraryApp [-Inventory] <PSObject> [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Renvoie les détails d’une application spécifiée dans une bibliothèque Evergreen, y compris toutes les informations de version et de fichiers binaires/programmes d’installation qui y sont stockées. Les détails sont renvoyés par numéro de version décroissant afin de pouvoir utiliser la version la plus récente ou filtrer une version précise avec Where-Object.

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

Renvoie les détails de Microsoft Visual Studio Code issus de la bibliothèque Evergreen située dans \\server\EvergreenLibrary, transmis via le pipeline de Get-EvergreenLibrary à Get-EvergreenLibraryApp.

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

Utilise Get-EvergreenLibrary pour placer dans un objet nommé $Library les détails de la bibliothèque Evergreen située dans \\server\EvergreenLibrary. Cet objet est ensuite utilisé dans la commande Get-EvergreenLibraryApp pour renvoyer les détails de Microsoft Teams.

## PARAMETERS

### -InputObject

`Get-EvergreenLibraryApp` accepte l’objet PSObject renvoyé par `Get-EvergreenLibrary`. `Get-EvergreenLibraryApp` vérifie la présence de la propriété Inventory sur cet objet et génère une erreur si elle est absente.

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

Nom de l’application dont les détails doivent être renvoyés.
La liste des applications prises en charge est disponible avec `Find-EvergreenApp`.

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

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Créer une bibliothèque Evergreen :](https://eucpilots.com/evergreen/getlibrary.html)
