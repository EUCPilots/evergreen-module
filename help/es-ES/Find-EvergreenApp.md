---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Find-EvergreenApp/
schema: 2.0.0
---

# Find-EvergreenApp

## SYNOPSIS

Muestra una tabla con las aplicaciones compatibles con Evergreen.

## SYNTAX

```
Find-EvergreenApp [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION

Devuelve una tabla creada a partir de los manifiestos internos de aplicaciones para enumerar las aplicaciones compatibles con Evergreen. La tabla incluye las propiedades Name (el nombre interno que se usa al consultar la aplicación mediante `Get-EvergreenApp`), Application (normalmente, el nombre completo del proveedor y de la aplicación) y Link (una URL que aloja información oficial del proveedor sobre la aplicación).

## EXAMPLES

### EXAMPLE 1

```powershell
Find-EvergreenApp
```

Descripción:
Devuelve una tabla con todas las aplicaciones compatibles actualmente con Evergreen.

### EXAMPLE 2

```powershell
Find-EvergreenApp -Name "Edge"
```

Descripción:
Devuelve una tabla con todas las aplicaciones compatibles actualmente que coinciden con "Edge".

### EXAMPLE 3

```powershell
Find-EvergreenApp -Name "Microsoft"
```

Descripción:
Devuelve una tabla con todas las aplicaciones compatibles actualmente que coinciden con "Microsoft".

## PARAMETERS

### -Name

Nombre de la aplicación cuyos detalles se van a devolver.
Puede ser el nombre completo de la aplicación o una parte de él.

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

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Buscar aplicaciones compatibles](https://eucpilots.com/evergreen/find/)
