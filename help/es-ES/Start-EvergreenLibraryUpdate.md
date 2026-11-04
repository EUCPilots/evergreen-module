---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Start-EvergreenLibraryUpdate/
schema: 2.0.0
---

# Start-EvergreenLibraryUpdate

## SYNOPSIS

Invoca la actualización y descarga de instaladores de aplicaciones en una biblioteca de Evergreen. `Start-EvergreenLibraryUpdate` lee el manifiesto de la biblioteca (`EvergreenLibrary.json`), que define las aplicaciones de la biblioteca, y usa `Get-EvergreenApp` y `Save-EvergreenApp` para descargar los instaladores más recientes en la biblioteca.

## SYNTAX

```
Start-EvergreenLibraryUpdate [-Path] <FileInfo> [-Proxy <String>] [-ProxyCredential <PSCredential>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Una biblioteca de Evergreen permite mantener varias versiones de los instaladores de aplicaciones, en lugar de usar siempre el instalador más reciente. Permite instalar la versión de una aplicación necesaria para un entorno específico, incluida la posibilidad de volver a una versión anterior. Una biblioteca de Evergreen también permite crear una imagen sin acceso a Internet: basta con descargar los instaladores de aplicaciones en la biblioteca y usarlos después durante el proceso de creación de la imagen.

`Start-EvergreenLibraryUpdate` invoca la actualización y descarga de instaladores de aplicaciones en una biblioteca de Evergreen. `Start-EvergreenLibraryUpdate` lee el manifiesto de la biblioteca (`EvergreenLibrary.json`), que define las aplicaciones de la biblioteca, y usa `Get-EvergreenApp` y `Save-EvergreenApp` para descargar los instaladores más recientes en la biblioteca.

## EXAMPLES

### EXAMPLE 1

```powershell
Start-EvergreenLibraryUpdate -Path "\\server\EvergreenLibrary"
```

Descripción:
`Start-EvergreenLibraryUpdate` lee el manifiesto `EvergreenLibrary.json` de la biblioteca, ubicado en \\server\EvergreenLibrary, que define las aplicaciones de esa biblioteca. Usa `Get-EvergreenApp` y `Save-EvergreenApp` para descargar los instaladores más recientes en la biblioteca.

## PARAMETERS

### -Path

Especifica la ruta a la biblioteca de Evergreen. La ruta debe incluir EvergreenLibrary.json, en la estructura esperada, que define las aplicaciones que se almacenarán en la biblioteca.

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

### -Proxy

Especifica un servidor proxy para la solicitud, en lugar de conectarse directamente al recurso de Internet. Introduce el URI de un servidor proxy de red.

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

### -ProxyCredential

Especifica una cuenta de usuario con permiso para usar el servidor proxy indicado por el parámetro Proxy. De forma predeterminada, se usa el usuario actual.

Escribe un nombre de usuario, como User01 o Domain01\User01, User@Domain.Com, o introduce un objeto `PSCredential`, como el generado por el cmdlet `Get-Credential`.

Este parámetro solo es válido si también se usa el parámetro Proxy en el comando.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

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

Start-EvergreenLibraryUpdate acepta un parámetro de cadena.

## OUTPUTS

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Actualizar una biblioteca de Evergreen](https://eucpilots.com/evergreen/updatelibrary/)
