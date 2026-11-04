---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Start-EvergreenLibraryUpdate/
schema: 2.0.0
---

# Start-EvergreenLibraryUpdate

## SYNOPSIS

Evergreen ライブラリ内のアプリケーション インストーラーの更新とダウンロードを実行します。`Start-EvergreenLibraryUpdate` は、ライブラリ内のアプリケーションを定義するライブラリ マニフェスト（`EvergreenLibrary.json`）を読み込み、`Get-EvergreenApp` と `Save-EvergreenApp` を使用して最新のインストーラーをライブラリにダウンロードします。

## SYNTAX

```
Start-EvergreenLibraryUpdate [-Path] <FileInfo> [-Proxy <String>] [-ProxyCredential <PSCredential>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Evergreen ライブラリを使用すると、常に最新のインストーラーを使用するのではなく、複数のバージョンのアプリケーション インストーラーを維持できます。特定の環境で必要なバージョンのアプリケーションをインストールでき、以前のバージョンへのロールバックも可能です。また、アプリケーション インストーラーをライブラリにダウンロードしてイメージのビルド時に使用すれば、インターネット アクセスなしでイメージをビルドできます。

`Start-EvergreenLibraryUpdate` は Evergreen ライブラリ内のアプリケーション インストーラーの更新とダウンロードを実行します。ライブラリ内のアプリケーションを定義するライブラリ マニフェスト（`EvergreenLibrary.json`）を読み込み、`Get-EvergreenApp` と `Save-EvergreenApp` を使用して最新のインストーラーをライブラリにダウンロードします。

## EXAMPLES

### EXAMPLE 1

```powershell
Start-EvergreenLibraryUpdate -Path "\\server\EvergreenLibrary"
```

説明：
`Start-EvergreenLibraryUpdate` は \\server\EvergreenLibrary にある、そのライブラリのアプリケーションを定義するライブラリ マニフェスト `EvergreenLibrary.json` を読み込みます。`Get-EvergreenApp` と `Save-EvergreenApp` を使用して、最新のインストーラーをライブラリにダウンロードします。

## PARAMETERS

### -Path

Evergreen ライブラリのパスを指定します。パスには、ライブラリに保存するアプリケーションを定義する EvergreenLibrary.json が想定される構造で含まれている必要があります。

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

### -Proxy

インターネット リソースに直接接続する代わりに、要求に使用するプロキシ サーバーを指定します。ネットワーク プロキシ サーバーの URI を入力してください。

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

### -ProxyCredential

Proxy パラメーターで指定したプロキシ サーバーを使用する権限を持つユーザー アカウントを指定します。既定値は現在のユーザーです。

User01、Domain01\User01、User@Domain.Com などのユーザー名を入力するか、`Get-Credential` コマンドレットで生成したものなどの `PSCredential` オブジェクトを入力します。

このパラメーターは、コマンドで Proxy パラメーターも使用する場合にのみ有効です。

```yaml
Type: PSCredential
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

### System.String

Start-EvergreenLibraryUpdate は文字列パラメーターを受け取ります。

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen ライブラリの更新](https://eucpilots.com/evergreen/updatelibrary/)
