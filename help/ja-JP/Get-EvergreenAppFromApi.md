---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppFromApi/
schema: 2.0.0
---

# Get-EvergreenAppFromApi

## SYNOPSIS

Evergreen モジュールがサポートするアプリケーションの最新バージョンとダウンロード URL を返します。この関数は Get-EvergreenApp と同じデータを返しますが、Evergreen App Tracker API に問い合わせてデータを取得します。

## SYNTAX

```
Get-EvergreenAppFromApi [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Evergreen モジュールがサポートするアプリケーションの最新バージョンとダウンロード URL を返します。この関数は Get-EvergreenApp と同じデータを返しますが、Evergreen App Tracker API に問い合わせてデータを取得します。API のデータは、Get-EvergreenApp によって 12 時間ごとに更新されるキー/値ストアから取得されます。

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

説明：
[https://edgeupdates.microsoft.com/api/products](https://edgeupdates.microsoft.com/api/products) の Microsoft Edge 公式更新 API を使用して、Microsoft Edge の現在のバージョンとダウンロード URL を返します。

### EXAMPLE 2

```powershell
Get-EvergreenAppFromApi -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

説明：
Microsoft Edge の 64 ビット Enterprise リングの Stable チャネルについて、現在のバージョンとダウンロード URL を返します。

## PARAMETERS

### -Name

詳細を取得するアプリケーション名。
サポートされているアプリケーションの一覧は `Find-EvergreenApp` で確認できます。

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

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[https://eucpilots.com/evergreen/invoke/](https://eucpilots.com/evergreen/invoke/)
