---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Test-EvergreenApp

## SYNOPSIS

`Get-EvergreenApp` からこの関数に渡された対象 URI を検証します。

## SYNTAX

```
Test-EvergreenApp [-InputObject] <PSObject> [-Proxy <String>] [-ProxyCredential <PSCredential>]
 [-UserAgent <String>] [-ConnectionTimeoutSeconds <Int32>] [-NoProgress] [<CommonParameters>]
```

## DESCRIPTION

Evergreen には、`Get-EvergreenApp` が返すアプリケーション インストーラー URL を検証する `Test-EvergreenApp` 関数が含まれています。最初に HEAD 要求を送信し、失敗した要求は範囲指定の GET で再試行します。出力には結果、取得できる場合は HTTP ステータス コード、および URI が含まれます。

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "MicrosoftOneDrive" | Test-EvergreenApp
```

説明：
`Get-EvergreenApp -Name "MicrosoftOneDrive"` が返す各オブジェクトの URI プロパティを検証し、結果、取得できる場合はステータス コード、および URI を返します。

## PARAMETERS

### -InputObject

`Test-EvergreenApp` は `Get-EvergreenApp` のアプリケーション オブジェクトを受け取り、空でない URI プロパティを必要とします。無効なオブジェクトの場合は警告と false の結果が出力されますが、後続のオブジェクトの処理は続行されます。

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

### -Proxy

インターネット リソースに直接接続する代わりに、要求に使用するプロキシ サーバーを指定します。ネットワーク プロキシ サーバーの URI を入力してください。注：プロキシのサポートは試験的なものです。

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

このパラメーターは、コマンドで Proxy パラメーターも使用する場合にのみ有効です。注：プロキシ サーバーのサポートは試験的なものであり、十分にテストされていません。

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

既定では進行状況は抑制されます。`-Verbose` を使用すると、`-NoProgress` も指定されていない限り進行状況が表示されます。

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

### -ConnectionTimeoutSeconds

各 Web 要求の待機時間の最大秒数を指定します。既定値は 30 秒です。

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### System.Management.Automation.PSObject

Test-EvergreenApp は Get-EvergreenApp の出力を受け取ります。

## OUTPUTS

### System.Management.Automation.PSObject

Boolean 型の結果、取得できる場合は HTTP ステータス コード、および URI を含むオブジェクトを提供します。

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[インストーラーのテスト](https://eucpilots.com/evergreen/test/)
