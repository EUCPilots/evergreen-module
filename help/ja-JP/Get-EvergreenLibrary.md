---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibrary/
schema: 2.0.0
---

# Get-EvergreenLibrary

## SYNOPSIS

Evergreen ライブラリの詳細を返します。ライブラリに設定されたアプリケーション、およびダウンロード済みのアプリケーション バイナリとバージョンの情報が含まれます。

## SYNTAX

### Path

```
Get-EvergreenLibrary [-Path] <FileInfo> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### URI

```
Get-EvergreenLibrary -Uri <Uri> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
指定されたパスにある Evergreen ライブラリの詳細を返します。
これには、`EvergreenLibrary.json` に保存されているライブラリの詳細と、ライブラリ内の各アプリケーションについて保存されたバージョン情報が含まれます。
アプリケーションのダウンロードとバージョン情報は、事前に `Invoke-EvergreenLibraryUpdate` を使用してダウンロードしておく必要があります。

## EXAMPLES

### Example 1
```
PS C:\> Get-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

\\server\EvergreenLibrary にある Evergreen ライブラリの詳細を返します。各アプリケーションについて保存されているバージョン情報も含まれます。

### Example 2
```
PS C:\> Get-EvergreenLibrary -Uri "https://st5srpuzr5v74.blob.core.windows.net/library/EvergreenLibrary.json"
```

"st5srpuzr5v74" ストレージ アカウントの "library" コンテナーにある Evergreen ライブラリの詳細を返します。各アプリケーションについて保存されているバージョン情報も含まれます。

## PARAMETERS

### -Path

Evergreen ライブラリのローカル パスまたは UNC パスを指定します。

```yaml
Type: FileInfo
Parameter Sets: Path
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Uri

Azure ストレージ アカウントの Blob Storage でホストされている Evergreen ライブラリの URI を指定します。

```yaml
Type: Uri
Parameter Sets: URI
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### System.IO.FileInfo

## OUTPUTS

### System.Object

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen ライブラリの作成](https://eucpilots.com/evergreen/getlibrary.html)
