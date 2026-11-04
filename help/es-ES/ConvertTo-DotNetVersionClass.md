---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version:
schema: 2.0.0
---

# ConvertTo-DotNetVersionClass

## SYNOPSIS
Convierte una cadena de versión en una clase Version estándar compatible con .NET.

## SYNTAX

```
ConvertTo-DotNetVersionClass [-Version] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
La función ConvertTo-DotNetVersionClass toma una cadena de versión como entrada y la convierte en una clase Version de .NET.
Normaliza los segmentos de la cadena de versión para que tenga exactamente cuatro segmentos, ya sea sumando los segmentos sobrantes
o añadiendo ceros si hay menos de cuatro segmentos.

Si se produce un error al convertirla en una clase Version de .NET, la función devuelve la cadena de versión normalizada como una cadena.

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

Cadena de versión que se va a convertir en una clase de versión estándar compatible con .NET.

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

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Exportar información de la versión de la aplicación](https://eucpilots.com/evergreen/convertversion/)
