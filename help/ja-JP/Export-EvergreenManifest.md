---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenManifest/
schema: 2.0.0
---

# Export-EvergreenManifest

## SYNOPSIS

Evergreen アプリケーションの JSON マニフェストをハッシュテーブルとしてエクスポートします。

## SYNTAX

```
Export-EvergreenManifest [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Evergreen アプリケーションの JSON マニフェストを、スクリプトでの使用や外部ファイルへの保存など、さまざまな用途に利用できるハッシュテーブルとしてエクスポートします。

## EXAMPLES

### EXAMPLE 1

```powershell
Export-EvergreenManifest -Name "MicrosoftEdge"
```

説明：
アプリケーション「MicrosoftEdge」のマニフェストをエクスポートします。

## PARAMETERS

### -Name

詳細を取得するアプリケーション名。サポートされているアプリケーションの一覧は `Find-EvergreenApp` で確認できます。

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
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

[Evergreen の概要](https://eucpilots.com/evergreen/)
