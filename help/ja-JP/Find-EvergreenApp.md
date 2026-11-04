---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Find-EvergreenApp/
schema: 2.0.0
---

# Find-EvergreenApp

## SYNOPSIS

Evergreen がサポートするアプリケーションを表形式で出力します。

## SYNTAX

```
Find-EvergreenApp [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION

内部アプリケーション マニフェストから作成した表を返し、Evergreen がサポートするアプリケーションを一覧表示します。表には、Name（`Get-EvergreenApp` でアプリケーションを照会する際に使用する内部名）、Application（通常はベンダー名とアプリケーション名の完全名）、Link（アプリケーションに関するベンダー公式情報の URL）の各プロパティが含まれます。

## EXAMPLES

### EXAMPLE 1

```powershell
Find-EvergreenApp
```

説明：
現在 Evergreen がサポートしているすべてのアプリケーションを含む表を返します。

### EXAMPLE 2

```powershell
Find-EvergreenApp -Name "Edge"
```

説明：
現在サポートされているアプリケーションのうち、「Edge」に一致するものを含む表を返します。

### EXAMPLE 3

```powershell
Find-EvergreenApp -Name "Microsoft"
```

説明：
現在サポートされているアプリケーションのうち、「Microsoft」に一致するものを含む表を返します。

## PARAMETERS

### -Name

詳細を取得するアプリケーション名。
アプリケーション名全体、またはその一部を指定できます。

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

[サポートされているアプリケーションの検索](https://eucpilots.com/evergreen/find/)
