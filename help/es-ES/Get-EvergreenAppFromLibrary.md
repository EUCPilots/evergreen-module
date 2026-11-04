---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibraryApp/
schema: 2.0.0
---

# Get-EvergreenLibraryApp

## SYNOPSIS

Devuelve los detalles de una aplicación especificada de una biblioteca de Evergreen. La salida incluye la información de versión y ruta de la aplicación que se puede usar para instalar los binarios de la aplicación desde la biblioteca.

## SYNTAX

```
Get-EvergreenLibraryApp [-Inventory] <PSObject> [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Devuelve los detalles de una aplicación especificada de una biblioteca de Evergreen, incluida toda la información de versiones y binarios/instaladores almacenada en la biblioteca. Los detalles devueltos se ordenan de forma descendente por número de versión para que se pueda usar la versión más reciente o filtrar una versión específica con Where-Object.

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

Devuelve los detalles de Microsoft Visual Studio Code de la biblioteca de Evergreen en \\server\EvergreenLibrary, que se pasa mediante la canalización a Get-EvergreenLibraryApp desde Get-EvergreenLibrary.

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

Usa Get-EvergreenLibrary para colocar en un objeto llamado $Library los detalles de la biblioteca de Evergreen en \\server\EvergreenLibrary. A continuación, ese objeto se usa en la línea de comandos de Get-EvergreenLibraryApp para devolver los detalles de Microsoft Teams.

## PARAMETERS

### -InputObject

`Get-EvergreenLibraryApp` acepta la salida PSObject de `Get-EvergreenLibrary`. `Get-EvergreenLibraryApp` comprueba si existe la propiedad Inventory en este objeto y genera un error si no existe.

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

Nombre de la aplicación cuyos detalles se van a devolver.
La lista de aplicaciones compatibles se puede consultar con `Find-EvergreenApp`.

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

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Crear una biblioteca de Evergreen:](https://eucpilots.com/evergreen/getlibrary.html)
