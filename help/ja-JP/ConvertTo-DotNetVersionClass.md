---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version:
schema: 2.0.0
---

# ConvertTo-DotNetVersionClass

## SYNOPSIS
バージョン文字列を標準の .NET 互換 Version クラスに変換します。

## SYNTAX

```
ConvertTo-DotNetVersionClass [-Version] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
ConvertTo-DotNetVersionClass 関数は、バージョン文字列を入力として受け取り、.NET Version クラスに変換します。
バージョン文字列のセグメントを正規化し、余分なセグメントを合算するか、
4 つ未満の場合はゼロで補完して、正確に 4 つのセグメントにします。

変換に失敗した場合、関数は正規化済みのバージョン文字列を文字列として返します。

## EXAMPLES

### EXAMPLE 1

```
ConvertTo-DotNetVersionClass -Version "1.2.3.4"
1.2.3.4
```

### EXAMPLE 2

```
ConvertTo-DotNetVersionClass -Version "1.2.3"
1.2.3.0
```

### EXAMPLE 3

```
ConvertTo-DotNetVersionClass -Version "1.2.3.4.5"
1.2.3.9
```

## PARAMETERS

### -Version

標準の .NET 互換バージョン クラスに変換するバージョン文字列。

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

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[アプリケーションのバージョン情報のエクスポート](https://eucpilots.com/evergreen/convertversion/)
