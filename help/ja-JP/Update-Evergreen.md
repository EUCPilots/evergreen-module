---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Update-Evergreen/
schema: 2.0.0
---

# Update-Evergreen

## SYNOPSIS

eucpilots/evergreen-apps GitHub リポジトリから Evergreen Apps の関数とマニフェストをダウンロードして同期します。

## SYNTAX

```
Update-Evergreen [-Force] [-Release <String>] [<CommonParameters>]
```

## DESCRIPTION

Evergreen のコア モジュールをアプリ固有のコードやマニフェストから分離できます。指定した GitHub リポジトリから /Apps と /Manifests の最新バージョンを、ユーザーが書き込み可能な場所（管理者権限不要）にダウンロードします。既定では、Windows のローカル キャッシュは %LocalAppData%\Evergreen に、macOS および Linux では ~/.evergreen にダウンロードされます。

## EXAMPLES

### EXAMPLE 1

```powershell
Update-Evergreen
```

説明：
eucpilots/evergreen-apps GitHub リポジトリから Evergreen Apps の関数とマニフェストをダウンロードして同期します。更新が必要な場合はローカル キャッシュを更新します。更新が不要な場合は何も行いません。

### EXAMPLE 2

```powershell
Update-Evergreen -Force
```

説明：
ローカル キャッシュの状態にかかわらず、eucpilots/evergreen-apps GitHub リポジトリから Evergreen Apps の関数とマニフェストをすべてダウンロードして同期します。

### EXAMPLE 2

```powershell
Update-Evergreen -Release "v25.09.27.16" -Force
```

説明：
eucpilots/evergreen-apps GitHub リポジトリから Evergreen Apps の関数とマニフェストの v25.09.27.16 リリースをダウンロードして同期します。

## PARAMETERS

### -Force

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Release

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS
