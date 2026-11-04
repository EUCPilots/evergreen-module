---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/New-EvergreenLibrary/
schema: 2.0.0
---

# New-EvergreenLibrary

## SYNOPSIS

Crea una biblioteca de Evergreen en la ruta especificada.

## SYNTAX

```
New-EvergreenLibrary [-Path] <FileInfo> [-Name <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Crea una biblioteca de Evergreen en la ruta especificada. Una biblioteca de Evergreen es un directorio con un archivo de manifiesto que define los instaladores de aplicaciones que se almacenarán en la biblioteca (`EvergreenLibrary.json`). `New-EvergreenLibrary` crea una biblioteca predeterminada en la ruta especificada; después, el archivo de manifiesto se puede actualizar manualmente para definir la lista de aplicaciones de la biblioteca.

## EXAMPLES

### EXAMPLE 1

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Descripción:
Crea una nueva biblioteca de Evergreen en la ruta \\server\EvergreenLibrary.

### EXAMPLE 2

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary" -Name "AzureVirtualDesktopProd"
```

Descripción:
Crea una nueva biblioteca de Evergreen en la ruta \\server\EvergreenLibrary. Asigna el nombre AzureVirtualDesktopProd al archivo de manifiesto `EvergreenLibrary.json`.

## PARAMETERS

### -Path

Especifica la ruta a la biblioteca de Evergreen. Se espera que la ubicación de destino esté vacía. Si la ruta incluye EvergreenLibrary.json, `New-EvergreenLibrary` no modificará el manifiesto.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name

Especifica un nombre para la biblioteca.

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

### -WhatIf

Muestra lo que ocurriría si se ejecutara el cmdlet.

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

Solicita confirmación antes de ejecutar el cmdlet.

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

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

New-EvergreenLibrary acepta parámetros de cadena.

## OUTPUTS

## NOTES

Sitio: https://eucpilots.com/evergreen
Autor: Aaron Parker
## RELATED LINKS

[Crear una biblioteca de Evergreen:](https://eucpilots.com/evergreen/newlibrary/)
