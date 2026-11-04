---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibrary/
schema: 2.0.0
---

# Get-EvergreenLibrary

## SYNOPSIS

Devuelve detalles sobre una biblioteca de Evergreen, incluidos los detalles de las aplicaciones configuradas en la biblioteca y los binarios y versiones de aplicaciones descargados.

## SYNTAX

### Path

```
Get-EvergreenLibrary [-Path] <FileInfo> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### URI

```
Get-EvergreenLibrary -Uri <Uri> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Devuelve detalles sobre una biblioteca de Evergreen en una ruta especificada.
Incluye los detalles de la biblioteca almacenados en `EvergreenLibrary.json` y la información de versiones de aplicaciones almacenada para cada aplicación de la biblioteca.
Las descargas y la información de versiones de las aplicaciones deben descargarse primero mediante `Invoke-EvergreenLibraryUpdate`.

## EXAMPLES

### Example 1
```
PS C:\> Get-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Devuelve detalles sobre la biblioteca de Evergreen en \\server\EvergreenLibrary, incluida la información de versiones de aplicaciones almacenada para cada aplicación.

### Example 2
```
PS C:\> Get-EvergreenLibrary -Uri "https://st5srpuzr5v74.blob.core.windows.net/library/EvergreenLibrary.json"
```

Devuelve detalles sobre la biblioteca de Evergreen de la cuenta de almacenamiento "st5srpuzr5v74", en el contenedor "library", incluida la información de versiones de aplicaciones almacenada para cada aplicación.

## PARAMETERS

### -Path

Especifica la ruta local o UNC a la biblioteca de Evergreen.

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

### -Uri

Especifica el URI a una biblioteca de Evergreen alojada en el almacenamiento de blobs de una cuenta de Azure Storage.

```yaml
Type: Uri
Parameter Sets: URI
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.FileInfo

## OUTPUTS

### System.Object

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Crear una biblioteca de Evergreen](https://eucpilots.com/evergreen/getlibrary.html)
