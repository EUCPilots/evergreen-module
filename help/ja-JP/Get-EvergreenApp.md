---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenApp/
schema: 2.0.0
---

# Get-EvergreenApp

## SYNOPSIS

Evergreen モジュールがサポートするアプリケーションの最新バージョンとダウンロード URL を返します。

## SYNTAX

```
Get-EvergreenApp [-Name] <String> [[-AppParams] <Hashtable>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-SkipCertificateCheck] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

モジュールに含まれる内部アプリケーション関数とマニフェストを照会し、指定したアプリケーションの最新バージョンとダウンロードリンクを取得します。

この関数の出力を Where-Object に渡すと、プロセッサ アーキテクチャ、ファイルの種類、その他のプロパティに基づいて特定のダウンロードをフィルターできます。

`Get-EvergreenApp` は、更新 API、Web クエリ、コード リポジトリなどのベンダー公式ソースを使用して、実行時に対象アプリケーションの詳細を返します。

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "MicrosoftEdge"

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
Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

説明：
Microsoft Edge の 64 ビット Enterprise リングの Stable チャネルについて、現在のバージョンとダウンロード URL を返します。

### EXAMPLE 3

```powershell
(Get-EvergreenApp -Name "MicrosoftOneDrive" | Where-Object { $_.Type -eq "Exe" -and $_.Ring -eq "Production" }) | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
```

説明：
Microsoft OneDrive の Production リングの現在のバージョンとダウンロード URL を返します。複数のリリースが返された場合は最新バージョンを選択します。

### EXAMPLE 4

```powershell
Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language -eq "English" -and $_.Architecture -eq "x86" }
```

説明：
英語版 32 ビットの Adobe Acrobat Reader DC に一致する現在のバージョンとダウンロード URL を返します。

### EXAMPLE 5

```powershell
Find-EvergreenApp -Name "Teams" | Get-EvergreenApp
```

説明：
文字列「Teams」に一致する利用可能なアプリケーション（例：Microsoft Teams）を一覧表示し、その出力を `Get-EvergreenApp` に渡して一致するアプリケーション名を照会します。`Get-EvergreenApp` はパイプラインで返された複数の一致すべてではなく、最初のアプリケーションのみを処理します。

### EXAMPLE 6

```powershell
Get-EvergreenApp -Name "MicrosoftTeams" | Save-EvergreenApp -Path "C:\Apps\Teams"
```

説明：
`Get-EvergreenApp` は Microsoft Teams の最新バージョンの詳細を返し、それがパイプライン経由で `Save-EvergreenApp` に渡されます。出力を使用して、返されたオブジェクトに基づくディレクトリ構造で対象 URL を C:\Apps\Teams に保存します。この場合、返されたオブジェクトの Ring および Architecture プロパティがディレクトリ構造に使用されます。

### EXAMPLE 7

```powershell
Get-EvergreenApp -Name "MozillaFirefox" -AppParams @{ Language = "en-GB", "es-ES" }
```

説明：
既定の en-US ではなく、en-GB および es-ES 言語のダウンロードを返すように MozillaFirefox に指定します。

### EXAMPLE 8

```powershell
Get-EvergreenApp -Name "GitHubRelease" -AppParams @{ Uri = "https://api.github.com/repos/atom/atom/releases/latest" }
```

説明：
マニフェストに埋め込まれたリポジトリの代わりに、`GetHubRelease` 用の内部アプリケーション関数にカスタム リポジトリを渡します。これにより、Evergreen がまだサポートしていない GitHub 上のアプリケーションのリリースを `Get-EvergreenApp` で検索できます。

## PARAMETERS

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

### -AppParams

内部アプリケーション関数に渡すパラメーターのハッシュテーブル。
キーと値のハッシュテーブルを受け取り、内部アプリケーション関数に渡して追加機能を有効にします（利用できる機能はアプリケーション関数によって異なります）。

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

### -SkipCertificateCheck

証明書の有効期限、失効、信頼されたルート機関など、すべての証明書検証をスキップします。

警告：このパラメーターの使用は安全ではなく、推奨されません。このスイッチは、ベンダー側で一時的な証明書の問題が発生した場合に限り、テスト目的でのみ使用してください。使用は自己責任で行ってください。

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

[Evergreen の使用](https://eucpilots.com/evergreen/use/)
