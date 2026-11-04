---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/New-EvergreenLibrary/
schema: 2.0.0
---

# New-EvergreenLibrary

## SYNOPSIS

指定されたパスに Evergreen ライブラリを作成します。

## SYNTAX

```
New-EvergreenLibrary [-Path] <FileInfo> [-Name <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

指定されたパスに Evergreen ライブラリを作成します。Evergreen ライブラリは、ライブラリに保存するアプリケーション インストーラーを定義するマニフェスト ファイル（`EvergreenLibrary.json`）を含むディレクトリです。`New-EvergreenLibrary` は指定されたパスに既定のライブラリを作成します。その後、マニフェスト ファイルを手動で更新して、ライブラリのアプリケーション一覧を定義できます。

## EXAMPLES

### EXAMPLE 1

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

説明：
パス \\server\EvergreenLibrary に新しい Evergreen ライブラリを作成します。

### EXAMPLE 2

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary" -Name "AzureVirtualDesktopProd"
```

説明：
パス \\server\EvergreenLibrary に新しい Evergreen ライブラリを作成し、マニフェスト ファイル `EvergreenLibrary.json` に AzureVirtualDesktopProd という名前を割り当てます。

## PARAMETERS

### -Path

Evergreen ライブラリのパスを指定します。対象の場所は空であることを想定しています。パスに EvergreenLibrary.json が含まれている場合、`New-EvergreenLibrary` はマニフェストを変更しません。

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name

ライブラリ名を指定します。

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

### -WhatIf

コマンドレットを実行した場合に何が起こるかを表示します。

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

### CommonParameters

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### System.String

New-EvergreenLibrary は文字列パラメーターを受け取ります。

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen
Author: Aaron Parker
## RELATED LINKS

[Evergreen ライブラリの作成：](https://eucpilots.com/evergreen/newlibrary/)
