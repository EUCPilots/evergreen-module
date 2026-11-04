---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Save-EvergreenApp

## SYNOPSIS

`Get-EvergreenApp` からこの関数に渡された対象 URI のファイルを、ディレクトリ構造内にダウンロードします。

## SYNTAX

### Path (Default)

```powershell
Save-EvergreenApp [-InputObject] <PSObject> [[-Path] <FileInfo>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-UserAgent <String>] [-Force] [-NoProgress] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### CustomPath

```powershell
Save-EvergreenApp [-InputObject] <PSObject> [[-CustomPath] <FileInfo>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-UserAgent <String>] [-Force] [-NoProgress] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

`Get-EvergreenApp` の出力からこの関数に渡された対象 URL を、関数に渡されたオブジェクトのプロパティを使用して -Path 以下のディレクトリ構造に保存します。

`Get-EvergreenApp` は、Product、Track、Channel、Release、Ring、Version、Language、（プロセッサ）Architecture の順で、アプリケーションのプロパティを含むオブジェクトを返します。対象オブジェクトに存在するプロパティのみが使用されます。

これにより、対象アプリケーションのインストーラーやアップデーターを一貫したディレクトリ構造に簡単に保存できます。ディレクトリ構造を自分で作成したり、ファイルをダウンロードするために別の関数を使用したりする必要はありません。

関数に渡されたオブジェクトのプロパティに基づいてディレクトリ構造を作成する既定の動作を上書きするには、`-CustomPath` パラメーターでファイルの保存先を正確に指定します。この方法では最初のファイルをダウンロードし、その後、`Get-EvergreenApp` から渡されたオブジェクトに同じ名前のファイルが含まれている場合、それらのファイルをスキップします。

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -Path "C:\Temp\Adobe"
```

説明：
`Get-EvergreenApp -Name "AdobeAcrobat"` が返す URI で指定された各ファイルを C:\Temp\Adobe 以下のディレクトリ構造にダウンロードします。ファイルごとに、次のようなディレクトリ構造になります：C:\Temp\Adobe\<Product>\<Track>\<Version>\<Language>\<Architecture>。

### EXAMPLE 2

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -CustomPath "C:\Temp\Adobe"
```

説明：
`Get-EvergreenApp -Name "AdobeAcrobat"` が返すすべての URI を、C:\Temp\Adobe という名前のディレクトリにダウンロードします。URI プロパティで指定されているすべてのファイルがこのディレクトリに保存されます。

## PARAMETERS

### -InputObject

`Save-EvergreenApp` は `Get-EvergreenApp` の PSObject を受け取ります。`Save-EvergreenApp` は少なくとも Version と URI の各プロパティが存在することを確認します。

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

ディレクトリ構造を作成し、アプリケーション インストーラーを保存する親ディレクトリです。通常、アプリケーションごとに異なるパスを指定します。

```yaml
Type: FileInfo
Parameter Sets: Path
Aliases:

Required: False
Position: 2
Default value: (Resolve-Path -Path $PWD)
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CustomPath

すべてのアプリケーション インストーラーを保存する単一のディレクトリ パスを指定します。サブディレクトリは作成されません。

```yaml
Type: FileInfo
Parameter Sets: CustomPath
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
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
Default value: [System.Management.Automation.PSCredential]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProgress

`Save-EvergreenApp` は `Invoke-WebRequest` を使用して対象アプリケーションのインストーラーをダウンロードします。ダウンロードを高速化するため、既定では進行状況が抑制されます。ただし、`-Verbose` を使用するとダウンロードの進行状況が表示されます。詳細出力を表示しながら進行状況を抑制するには、`-Verbose` とともに `-NoProgress` を使用します。

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

コマンドレットを実行した場合に何が起こるかを表示します。
コマンドレットは実行されません。

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

### -Force

対象ディレクトリにファイルがすでに存在する場合でも、URI プロパティから対象アプリケーションのインストーラーを強制的にダウンロードします。

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

### -UserAgent

Web 要求に使用するユーザー エージェント文字列を指定します。

既定のユーザー エージェントは次の文字列に似ていますが、オペレーティング システムやプラットフォームによって若干異なります。

Mozilla/5.0 (Macintosh; Darwin 22.2.0 Darwin Kernel Version 22.2.0: Fri Nov 11 02:04:44 PST 2022; root:xnu-8792.61.2~4/RELEASE_ARM64_T8103; en-AU) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6

ほとんどのインターネット ブラウザーで使用される標準のユーザー エージェント文字列で Web サイトをテストするには、PSUserAgent クラスの Chrome、FireFox、InternetExplorer、Opera、Safari などのプロパティを使用します。

たとえば、次のコマンドは Internet Explorer のユーザー エージェント文字列を使用します：Save-EvergreenApp -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)

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

### System.Management.Automation.PSObject

Save-EvergreenApp は Get-EvergreenApp の出力を受け取ります。

## OUTPUTS

### System.Management.Automation.PSObject

ダウンロードされた対象ファイルのパス一覧を提供します。

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[アプリケーション インストーラーのダウンロード：](https://eucpilots.com/evergreen/save)
