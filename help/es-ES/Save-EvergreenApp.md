---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Save-EvergreenApp

## SYNOPSIS

Descarga en una estructura de directorios los URI de destino que se pasan a esta función desde `Get-EvergreenApp`.

## SYNTAX

### Path (Default)

```powershell
Save-EvergreenApp [-InputObject] <PSObject> [[-Path] <FileInfo>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-UserAgent <String>] [-Force] [-NoProgress] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### CustomPath

```powershell
Save-EvergreenApp [-InputObject] <PSObject> [[-CustomPath] <FileInfo>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-UserAgent <String>] [-Force] [-NoProgress] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Guarda en una estructura de directorios bajo -Path las URL de destino que se pasan a esta función en la salida de `Get-EvergreenApp`, usando las propiedades del objeto que se pasa a la función.

`Get-EvergreenApp` devuelve un objeto que puede incluir propiedades de la aplicación como (en el siguiente orden) Product, Track, Channel, Release, Ring, Version, Language y Architecture (del procesador). Solo se usarán las propiedades que existan en el objeto de destino.

Esto simplifica el guardado de los instaladores o actualizadores de la aplicación de destino en una estructura de directorios uniforme, sin tener que crear dicha estructura ni usar otras funciones para descargar el archivo.

Para reemplazar el comportamiento predeterminado, que crea la estructura de directorios según las propiedades del objeto pasado a la función, usa el parámetro `-CustomPath` para especificar una ruta exacta donde guardar los archivos. Ten en cuenta que este método descarga el primer archivo y, después, omite los archivos del objeto pasado desde `Get-EvergreenApp` que tengan el mismo nombre.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -Path "C:\Temp\Adobe"
```

Descripción:
Descarga en una estructura de directorios bajo C:\Temp\Adobe cada archivo especificado en los URI devueltos por `Get-EvergreenApp -Name "AdobeAcrobat"`. El resultado es una estructura de directorios por archivo similar a: C:\Temp\Adobe\<Product>\<Track>\<Version>\<Language>\<Architecture>.

### EXAMPLE 2

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -CustomPath "C:\Temp\Adobe"
```

Descripción:
Descarga todos los URI devueltos por `Get-EvergreenApp -Name "AdobeAcrobat"` en el directorio C:\Temp\Adobe. Todos los archivos especificados en la propiedad URI se guardan en este directorio.

## PARAMETERS

### -InputObject

`Save-EvergreenApp` acepta el PSObject de `Get-EvergreenApp`. `Save-EvergreenApp` comprueba la existencia de, al menos, estas propiedades: Version y URI.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

Directorio de destino bajo el que se creará una estructura de directorios y se guardarán los instaladores de aplicaciones. Normalmente, la ruta de destino será específica de cada aplicación.

```yaml
Type: FileInfo
Parameter Sets: Path
Aliases:

Required: False
Position: 2
Default value: (Resolve-Path -Path $PWD)
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CustomPath

Especifica una única ruta de directorio donde se guardarán todos los instaladores de aplicaciones. No se crearán subdirectorios.

```yaml
Type: FileInfo
Parameter Sets: CustomPath
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
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
Default value: [System.Management.Automation.PSCredential]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProgress

`Save-EvergreenApp` usa `Invoke-WebRequest` para descargar instaladores de aplicaciones de destino. De forma predeterminada, se suprime el progreso de la descarga para acelerarla; sin embargo, si se usa `-Verbose`, se muestra dicho progreso. Usa `-NoProgress` junto con `-Verbose` para suprimir el progreso de la descarga y, al mismo tiempo, mostrar la salida detallada.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Muestra lo que ocurriría si se ejecutara el cmdlet.
El cmdlet no se ejecuta.

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

### -Force

Fuerza la descarga de los instaladores de la aplicación de destino desde la propiedad URI, incluso si ya existen en el directorio de destino.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserAgent

Especifica una cadena de agente de usuario para la solicitud web.

El agente de usuario predeterminado es similar al siguiente, con ligeras variaciones según el sistema operativo y la plataforma.

Mozilla/5.0 (Macintosh; Darwin 22.2.0 Darwin Kernel Version 22.2.0: Fri Nov 11 02:04:44 PST 2022; root:xnu-8792.61.2~4/RELEASE_ARM64_T8103; en-AU) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6

Para probar un sitio web con la cadena de agente de usuario estándar que utilizan la mayoría de los exploradores de Internet, usa las propiedades de la clase PSUserAgent, como Chrome, FireFox, InternetExplorer, Opera y Safari.

Por ejemplo, el siguiente comando usa la cadena de agente de usuario de Internet Explorer: Save-EvergreenApp -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)

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

### CommonParameters

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Save-EvergreenApp acepta la salida de Get-EvergreenApp.

## OUTPUTS

### System.Management.Automation.PSObject

Proporciona una lista de rutas de los archivos de destino descargados.

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Descargar instaladores de aplicaciones:](https://eucpilots.com/evergreen/save)
