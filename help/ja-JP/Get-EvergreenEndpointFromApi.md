---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenEndpointFromApi/
schema: 2.0.0
---

# Get-EvergreenEndpointFromApi

## SYNOPSIS

Evergreen がアプリケーションの更新情報とダウンロード URL を取得するために必要な、アプリケーション、エンドポイント、ポートの配列を返します。

## SYNTAX

```
Get-EvergreenEndpointFromApi [-Name] <String> [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Evergreen でアプリケーションのバージョンを検索し、インストーラーをダウンロードするために必要なエンドポイント URL と TCP ポートを返すよう、Evergreen API に問い合わせます。

返されたエンドポイントの一覧は監査に使用でき、インターネット アクセスが制限されている環境では、ファイアウォールやプロキシ サーバーの許可リストを定義する際にも使用できます。

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenEndpointFromApi

Application  Endpoints                                                                              Ports
-----------  ---------                                                                              -----
1Password    {1password.com, app-updates.agilebits.com, downloads.1password.com, cdn.agilebits.com} {443}
1Password7   {1password.com, c.1password.com, download.app.com"}                                    {443}
1PasswordCLI {app-updates.agilebits.com, cache.agilebits.com, developer.1password.com}              {443}
7zip         {nchc.dl.sourceforge.net, sourceforge.net, www.7-zip.org, versaweb.dl.sourceforge.net} {443}
7ZipZS       {api.github.com, mcmilk.de, github.com}                                                {443}
```

説明：
現在 Evergreen がサポートしているすべてのアプリケーションのエンドポイント URL ソースとポートの一覧を返します。

### EXAMPLE 2

```powershell
Get-EvergreenEndpointFromApi -Name "MicrosoftEdge", "MicrosoftTeams"

Application    Endpoints                                                                              Ports
-----------    ---------                                                                              -----
MicrosoftEdge  {edgeupdates.microsoft.com, www.microsoft.com, msedge.sf.dl.delivery.mp.microsoft.com} {443}
MicrosoftTeams {config.teams.microsoft.com, www.microsoft.com, statics.teams.cdn.office.net}          {443}
```

説明：
Microsoft Edge と Microsoft Teams のアプリケーション バージョンおよびダウンロードの判定に使用するエンドポイント URL ソースとポートの一覧を返します。

### EXAMPLE 3

```powershell
Get-EvergreenEndpointFromApi | Select-Object -ExpandProperty Endpoints -Unique

1password.com
app-updates.agilebits.com
downloads.1password.com
cdn.agilebits.com
c.1password.com
```

説明：
現在 Evergreen がサポートしているアプリケーションの一意なエンドポイント URL をすべて含む単純な配列を返します。

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

### CommonParameters

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### System.Array

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen が使用するエンドポイントの取得](https://eucpilots.com/evergreen/endpoints/)
