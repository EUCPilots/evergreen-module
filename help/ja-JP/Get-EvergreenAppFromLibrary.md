---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibraryApp/
schema: 2.0.0
---

# Get-EvergreenLibraryApp

## SYNOPSIS

Evergreen ライブラリから指定したアプリケーションの詳細を返します。出力には、ライブラリ内のアプリケーション バイナリのインストールに使用できる、アプリケーションのバージョンとパスの情報が含まれます。

## SYNTAX

```
Get-EvergreenLibraryApp [-Inventory] <PSObject> [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Evergreen ライブラリから指定したアプリケーションの詳細を返します。ライブラリに保存されているすべてのバージョンとバイナリ／インストーラーの情報が含まれます。詳細はバージョン番号の降順で返されるため、最新バージョンを使用したり、Where-Object で特定のバージョンをフィルターしたりできます。

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

Get-EvergreenLibrary からパイプライン経由で Get-EvergreenLibraryApp に渡された、\\server\EvergreenLibrary の Evergreen ライブラリにある Microsoft Visual Studio Code の詳細を返します。

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

Get-EvergreenLibrary を使用して、\\server\EvergreenLibrary の Evergreen ライブラリの詳細を $Library というオブジェクトに格納します。その後、コマンド ラインでこのオブジェクトを Get-EvergreenLibraryApp に使用して、Microsoft Teams の詳細を返します。

## PARAMETERS

### -InputObject

`Get-EvergreenLibraryApp` は `Get-EvergreenLibrary` の PSObject 出力を受け取ります。`Get-EvergreenLibraryApp` はこのオブジェクトに Inventory プロパティが存在するかを確認し、存在しない場合はエラーをスローします。

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

詳細を取得するアプリケーション名。
サポートされているアプリケーションの一覧は `Find-EvergreenApp` で確認できます。

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

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen ライブラリの作成：](https://eucpilots.com/evergreen/getlibrary.html)
