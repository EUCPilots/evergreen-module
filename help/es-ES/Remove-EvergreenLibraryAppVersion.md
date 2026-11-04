---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Remove-EvergreenLibraryAppVersion/
schema: 2.0.0
---

# Remove-EvergreenLibraryAppVersion

## SYNOPSIS

Quita las versiones antiguas de los instaladores de aplicaciones de una biblioteca de Evergreen y conserva las versiones más recientes de cada manifiesto de aplicación.

## SYNTAX

```powershell
Remove-EvergreenLibraryAppVersion [-Path] <FileInfo> [[-Keep] <Int32>] [[-Name] <String[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

`Remove-EvergreenLibraryAppVersion` depura las versiones históricas de un manifiesto de aplicación de una biblioteca de Evergreen.

El cmdlet valida que `-Path` apunte a una biblioteca de Evergreen comprobando la existencia de `EvergreenLibrary.json`. Para cada aplicación de destino, lee el manifiesto de la aplicación (`<ApplicationName>.json`), ordena las versiones de más reciente a más antigua, conserva el número de entradas definido por `-Keep`, elimina del disco los archivos de instalación anteriores y escribe las versiones conservadas en el manifiesto de la aplicación.

De forma predeterminada, se procesan todas las aplicaciones de la biblioteca y se conservan las 3 versiones más recientes.

El límite de conservación cuenta entradas individuales del manifiesto tanto en Windows PowerShell 5.1 como en PowerShell 7. El manifiesto conservado sigue siendo una matriz JSON, incluso cuando se usa `-Keep 1`. Las rutas de los instaladores pueden ser absolutas, relativas al directorio de la aplicación o matrices de rutas registradas por versiones anteriores del módulo. Solo se eliminan los archivos de instalación registrados en las entradas depuradas; se conservan los archivos a los que también hacen referencia las entradas conservadas. Se omiten las rutas fuera del directorio de la aplicación y las rutas que atraviesan puntos de reanálisis. No se eliminan los directorios de versiones vacíos.

Los archivos que queden tras una depuración anterior no se podrán eliminar al volver a ejecutar este cmdlet si sus entradas ya no están en el manifiesto. Este cmdlet no busca archivos de instalación que no estén registrados.

Usa `-Verbose` para diagnosticar la validación de la biblioteca, la selección de aplicaciones, la lectura de manifiestos, la ordenación de versiones, las entradas conservadas y depuradas, los archivos de instalación omitidos y las actualizaciones de manifiestos. Los mensajes distinguen la depuración prevista de los archivos realmente eliminados e indican las acciones omitidas por `-WhatIf` o por el rechazo de la confirmación. Los mensajes detallados no modifican los objetos devueltos.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary"
```

Descripción:
Procesa todas las aplicaciones de la biblioteca y conserva las 3 versiones más recientes de cada aplicación. Se eliminan los archivos de instalación antiguos y se actualiza cada manifiesto de aplicación.

### EXAMPLE 2

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 2 -Name "MicrosoftEdge", "Zoom"
```

Descripción:
Procesa solo MicrosoftEdge y Zoom, conserva las 2 versiones más recientes en cada manifiesto de aplicación y elimina los archivos de instalación anteriores.

### EXAMPLE 3

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 5 -WhatIf
```

Descripción:
Muestra qué archivos y manifiestos cambiarían al conservar las 5 versiones más recientes, sin realizar ningún cambio.

### EXAMPLE 4

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Name "MicrosoftEdge" -Keep 3 -WhatIf -Verbose
```

Descripción:
Muestra mensajes de diagnóstico detallados y los cambios previstos para MicrosoftEdge sin eliminar instaladores ni actualizar su manifiesto.

## PARAMETERS

### -Path

Especifica la ruta a una biblioteca de Evergreen. La ruta debe existir y contener `EvergreenLibrary.json`.

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

Especifica cuántas versiones se conservarán en cada manifiesto de aplicación de destino. Se quitan las versiones anteriores.

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

Especifica uno o varios nombres de aplicación del manifiesto de la biblioteca que se procesarán. Si se omite, se procesan todas las aplicaciones.

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

### System.IO.FileInfo

`Remove-EvergreenLibraryAppVersion` acepta entrada por nombre de propiedad para `Path`.

## OUTPUTS

### System.Management.Automation.PSCustomObject

Devuelve un objeto por cada aplicación procesada con las propiedades siguientes:

- `ApplicationName`
- `Keep`
- `KeptCount`
- `PrunedCount`: número de entradas seleccionadas para depuración.
- `RemovedCount`: número de entradas eliminadas del manifiesto.
- `RemovedFileCount`: número de archivos de instalación realmente eliminados.
- `RemovedFiles`: rutas de los archivos de instalación realmente eliminados.
- `ManifestPath`

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Actualizar una biblioteca de Evergreen](https://eucpilots.com/evergreen/updatelibrary/)
