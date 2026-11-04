---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppsVersion/
schema: 2.0.0
---

# Get-EvergreenAppsVersion

## SYNOPSIS

Evergreen apps リポジトリの最新リリース バージョンを返します。

## SYNTAX

```
Get-EvergreenAppsVersion [<CommonParameters>]
```

## DESCRIPTION

GitHub Releases API に問い合わせて Evergreen apps リポジトリの最新リリースを取得し、そのバージョンを返します。

GitHub API のレート制限が適用されます。認証済みの要求を使用するには、`GITHUB_TOKEN` または `GH_TOKEN` 環境変数を設定します。

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenAppsVersion
```

説明：
Evergreen apps リポジトリで利用可能な最新リリース バージョンを返します。

## PARAMETERS

### CommonParameters

このコマンドレットは、共通パラメーター -Debug、-ErrorAction、-ErrorVariable、-InformationAction、-InformationVariable、-OutVariable、-OutBuffer、-PipelineVariable、-Verbose、-WarningAction、-WarningVariable をサポートします。詳細については、[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216) を参照してください。

## INPUTS

### None

## OUTPUTS

### System.String

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen apps リポジトリ](https://github.com/EUCPilots/evergreen-apps)
