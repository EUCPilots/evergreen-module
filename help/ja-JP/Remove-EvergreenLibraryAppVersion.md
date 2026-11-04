---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Remove-EvergreenLibraryAppVersion/
schema: 2.0.0
---

# Remove-EvergreenLibraryAppVersion

## SYNOPSIS

各アプリケーション マニフェストの最新バージョンを保持しながら、古いアプリケーション インストーラーのバージョンを Evergreen ライブラリから削除します。

## SYNTAX

```powershell
Remove-EvergreenLibraryAppVersion [-Path] <FileInfo> [[-Keep] <Int32>] [[-Name] <String[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

`Remove-EvergreenLibraryAppVersion` は、Evergreen ライブラリのアプリケーション マニフェストから過去のバージョンを整理して削除します。

このコマンドレットは `EvergreenLibrary.json` の有無を確認し、`-Path` が Evergreen ライブラリを指していることを検証します。対象アプリケーションごとにアプリ マニフェスト（`<ApplicationName>.json`）を読み込み、バージョンを新しい順に並べ替え、`-Keep` で指定された数のエントリを保持し、古いインストーラー ファイルをディスクから削除して、保持したバージョンをアプリ マニフェストに書き戻します。

既定では、ライブラリ内のすべてのアプリケーションが処理され、最新の 3 バージョンが保持されます。

Windows PowerShell 5.1 と PowerShell 7 のいずれでも、保持数の上限は個々のマニフェスト エントリ数としてカウントされます。`-Keep 1` を使用した場合も、保持されたマニフェストは JSON 配列のままです。インストーラーのパスには、絶対パス、アプリケーション ディレクトリからの相対パス、または以前のモジュール バージョンで記録されたパス配列を指定できます。整理対象のエントリに記録されたインストーラー ファイルのみが削除され、保持されたエントリからも参照されているファイルは保持されます。アプリケーション ディレクトリ外のパス、および再解析ポイントを経由するパスはスキップされます。空のバージョン ディレクトリは削除されません。

以前の整理で残されたファイルは、そのエントリがマニフェストからなくなっている場合、このコマンドレットを再実行しても削除できません。このコマンドレットは、記録されていないインストーラー ファイルを検索しません。

`-Verbose` を使用すると、ライブラリ検証、アプリケーション選択、マニフェストの読み取り、バージョンの並べ替え、保持および整理対象のエントリ、スキップされたインストーラー ファイル、マニフェスト更新のトラブルシューティングに役立つ情報を表示できます。メッセージでは、整理予定と実際に削除されたファイルを区別し、`-WhatIf` によってスキップされた操作や確認が拒否された操作を報告します。詳細メッセージによって返されるオブジェクトは変化しません。

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary"
```

説明：
ライブラリ内のすべてのアプリケーションを処理し、アプリケーションごとに最新の 3 バージョンを保持します。古いインストーラー ファイルを削除し、各アプリ マニフェストを更新します。

### EXAMPLE 2

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 2 -Name "MicrosoftEdge", "Zoom"
```

説明：
MicrosoftEdge と Zoom のみを処理し、各アプリ マニフェストの最新 2 バージョンを保持して、古いインストーラー ファイルを削除します。

### EXAMPLE 3

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 5 -WhatIf
```

説明：
変更を加えずに、最新の 5 バージョンを保持する場合に変更されるファイルとマニフェストを表示します。

### EXAMPLE 4

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Name "MicrosoftEdge" -Keep 3 -WhatIf -Verbose
```

説明：
インストーラーを削除したりマニフェストを更新したりせずに、MicrosoftEdge の詳細なトラブルシューティング メッセージと予定されている変更を表示します。

## PARAMETERS

### -Path

Evergreen ライブラリのパスを指定します。パスは存在し、`EvergreenLibrary.json` を含む必要があります。

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

### -Keep

対象アプリケーションの各マニフェストに保持するバージョン数を指定します。古いバージョンは削除されます。

```yaml
Type: Int32
Parameter Sets: Path
Aliases:

Required: False
Position: 1
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

ライブラリ マニフェストに記載された、処理対象のアプリケーション名を 1 つ以上指定します。省略した場合は、すべてのアプリケーションが処理されます。

```yaml
Type: String[]
Parameter Sets: Path
Aliases:

Required: False
Position: 2
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

### System.IO.FileInfo

`Remove-EvergreenLibraryAppVersion` は `Path` のプロパティ名による入力を受け取ります。

## OUTPUTS

### System.Management.Automation.PSCustomObject

処理したアプリケーションごとに、次のプロパティを含むオブジェクトを 1 つ返します。

- `ApplicationName`
- `Keep`
- `KeptCount`
- `PrunedCount`：整理対象として選択されたエントリ数。
- `RemovedCount`：マニフェストから削除されたエントリ数。
- `RemovedFileCount`：実際に削除されたインストーラー ファイル数。
- `RemovedFiles`：実際に削除されたインストーラー ファイルのパス。
- `ManifestPath`

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen ライブラリの更新](https://eucpilots.com/evergreen/updatelibrary/)
