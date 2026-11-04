---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenApp/
schema: 2.0.0
---

# Export-EvergreenApp

## SYNOPSIS

`Get-EvergreenApp` で取得したアプリケーションの詳細を外部 JSON ファイルにエクスポートします。この関数は対象アプリケーションの既存の JSON を読み込み、新しいバージョン情報を追加してバージョンが重複しないように並べ替えた後、更新内容を対象の JSON ファイルに書き戻します。

## SYNTAX

```
Export-EvergreenApp [-InputObject] <Array> -Path <FileInfo> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Get-EvergreenApp` で取得したアプリケーションの詳細を外部 JSON ファイルにエクスポートします。この関数は対象アプリケーションの既存の JSON を読み込み、新しいバージョン情報を追加してバージョンが重複しないように並べ替えた後、更新内容を対象の JSON ファイルに書き戻します。

## EXAMPLES

### EXAMPLE 1

```powershell
$OneDrive = Get-EvergreenApp -Name "MicrosoftOneDrive"
Save-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive"
Export-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive\MicrosoftOneDrive.json"
```

説明：
`Get-EvergreenApp` は `MicrosoftOneDrive` のバージョン情報を返します。次に `Save-EvergreenApp` を使用して、返されたインストーラーを `C:\Evergreen\OneDrive` に保存します。続いて `Export-EvergreenApp` でバージョン情報を `C:\Evergreen\OneDrive\MicrosoftOneDrive.json` に保存します。対象ファイルにすでにバージョン情報がある場合は、追加のバージョン情報が同じファイルに保存されます。

## PARAMETERS

### -InputObject

`Export-EvergreenApp` は `Get-EvergreenApp` の PSObject を受け取ります。

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

バージョン情報を保存する JSON ファイルのパスを指定します。ファイルが存在しない場合、親ディレクトリはすでに存在している必要があります。

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Confirm

コマンドレットの実行前に確認を求めます。

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

コマンドレットを実行した場合に何が起こるかを表示します。コマンドレットは実行されません。

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### System.Management.Automation.PSObject

Export-EvergreenApp は Get-EvergreenApp の出力を受け取ります。

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[アプリケーションのバージョン情報のエクスポート](https://eucpilots.com/evergreen/export/)
