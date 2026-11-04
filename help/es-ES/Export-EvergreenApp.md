---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenApp/
schema: 2.0.0
---

# Export-EvergreenApp

## SYNOPSIS

Exporta los detalles de la aplicación obtenidos por `Get-EvergreenApp` a un archivo JSON externo. Esta función lee cualquier JSON existente para esa aplicación, añade el contenido de la nueva versión, ordena las versiones únicas y, a continuación, escribe el nuevo contenido en el archivo JSON de destino.

## SYNTAX

```
Export-EvergreenApp [-InputObject] <Array> -Path <FileInfo> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Exporta los detalles de la aplicación obtenidos por `Get-EvergreenApp` a un archivo JSON externo. Esta función lee cualquier JSON existente para esa aplicación, añade el contenido de la nueva versión, ordena las versiones únicas y, a continuación, escribe el nuevo contenido en el archivo JSON de destino.

## EXAMPLES

### EXAMPLE 1

```powershell
$OneDrive = Get-EvergreenApp -Name "MicrosoftOneDrive"
Save-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive"
Export-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive\MicrosoftOneDrive.json"
```

Descripción:
`Get-EvergreenApp` devuelve la información de versión de `MicrosoftOneDrive`. A continuación, se usa `Save-EvergreenApp` para guardar los instaladores devueltos en `C:\Evergreen\OneDrive`. Después, se guarda la información de versión en `C:\Evergreen\OneDrive\MicrosoftOneDrive.json` con `Export-EvergreenApp`. Si ya hay información de versión almacenada en el archivo de destino, la información de versión adicional se guarda en el mismo archivo.

## PARAMETERS

### -InputObject

`Export-EvergreenApp` acepta el PSObject de `Get-EvergreenApp`.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

Especifica la ruta al archivo JSON donde se almacenará la información de versión. Si el archivo no existe, el directorio principal debe existir.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### -WhatIf

Muestra lo que ocurriría si se ejecutara el cmdlet. El cmdlet no se ejecuta.

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

### CommonParameters

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Export-EvergreenApp acepta la salida de Get-EvergreenApp.

## OUTPUTS

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Exportar información de la versión de la aplicación](https://eucpilots.com/evergreen/export/)
