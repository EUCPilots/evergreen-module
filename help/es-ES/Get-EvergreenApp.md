---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenApp/
schema: 2.0.0
---

# Get-EvergreenApp

## SYNOPSIS

Devuelve la versión más reciente y las URL de descarga de una aplicación compatible con el módulo Evergreen.

## SYNTAX

```
Get-EvergreenApp [-Name] <String> [[-AppParams] <Hashtable>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-SkipCertificateCheck] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Consulta las funciones y los manifiestos internos de aplicaciones incluidos en el módulo para encontrar la versión más reciente y los enlaces de descarga de la aplicación especificada.

La salida de esta función se puede pasar a Where-Object para filtrar una descarga concreta según propiedades como la arquitectura del procesador, el tipo de archivo u otras propiedades.

`Get-EvergreenApp` usa fuentes oficiales de los proveedores, como API de actualización, consultas web y ubicaciones de repositorios de código, para devolver en tiempo de ejecución los detalles de una aplicación de destino.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "MicrosoftEdge"

Version      : 89.0.774.76
Platform     : Windows
Channel      : Stable
Release      : Enterprise
Architecture : x64
Date         : 12/4/2021
Hash         : 9E7A29B4BE6E1CD707F80B4B79008F19D2D5DD5C774D317A493EC6DE5BE0B7D7
URI          : https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/4d12f620-174c-4259-85e6-8a80ea45ff10/MicrosoftEdgeEnterpriseX64.msi
```

Descripción:
Devuelve la versión actual y las URL de descarga de Microsoft Edge mediante la API oficial de actualización de Microsoft Edge en [https://edgeupdates.microsoft.com/api/products](https://edgeupdates.microsoft.com/api/products).

### EXAMPLE 2

```powershell
Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

Descripción:
Devuelve la versión actual y la URL de descarga del canal Stable de la edición Enterprise de 64 bits de Microsoft Edge.

### EXAMPLE 3

```powershell
(Get-EvergreenApp -Name "MicrosoftOneDrive" | Where-Object { $_.Type -eq "Exe" -and $_.Ring -eq "Production" }) | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
```

Descripción:
Devuelve la versión actual y la URL de descarga del anillo Production de Microsoft OneDrive y selecciona la versión más reciente si se devuelve más de una versión.

### EXAMPLE 4

```powershell
Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language -eq "English" -and $_.Architecture -eq "x86" }
```

Descripción:
Devuelve la versión actual y la URL de descarga que coinciden con la edición en inglés de 32 bits de Adobe Acrobat Reader DC.

### EXAMPLE 5

```powershell
Find-EvergreenApp -Name "Teams" | Get-EvergreenApp
```

Descripción:
Enumera las aplicaciones disponibles que coinciden con la cadena "Teams" (por ejemplo, Microsoft Teams) y pasa la salida a `Get-EvergreenApp`, que consulta el nombre de la aplicación coincidente. Ten en cuenta que `Get-EvergreenApp` solo procesará la primera aplicación devuelta en la canalización, no todas las aplicaciones coincidentes.

### EXAMPLE 6

```powershell
Get-EvergreenApp -Name "MicrosoftTeams" | Save-EvergreenApp -Path "C:\Apps\Teams"
```

Descripción:
`Get-EvergreenApp` devuelve los detalles de la versión más reciente de Microsoft Teams, que se pasa mediante la canalización a `Save-EvergreenApp`. La salida se usa para guardar las URL de destino en C:\Apps\Teams, en una estructura de directorios basada en el objeto devuelto. En este caso, las propiedades Ring y Architecture del objeto devuelto se usarán en la estructura de directorios.

### EXAMPLE 7

```powershell
Get-EvergreenApp -Name "MozillaFirefox" -AppParams @{ Language = "en-GB", "es-ES" }
```

Descripción:
Pasa los idiomas en-GB y es-ES a MozillaFirefox para que devuelva las descargas de esos idiomas en lugar del idioma predeterminado en-US.

### EXAMPLE 8

```powershell
Get-EvergreenApp -Name "GitHubRelease" -AppParams @{ Uri = "https://api.github.com/repos/atom/atom/releases/latest" }
```

Descripción:
Pasa un repositorio personalizado a la función interna de aplicación `GetHubRelease` en lugar de usar el repositorio incluido en el manifiesto. Así, `Get-EvergreenApp` puede encontrar las versiones de una aplicación alojada en GitHub que aún no es compatible con Evergreen.

## PARAMETERS

### -Name

Nombre de la aplicación cuyos detalles se van a devolver.
La lista de aplicaciones compatibles se puede consultar con `Find-EvergreenApp`.

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

### -AppParams

Tabla hash de parámetros que se pasarán a la función interna de aplicación.
Acepta una tabla hash de claves y valores que se pasarán a la función interna de aplicación para habilitar funcionalidades adicionales (según la función de aplicación).

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

### -SkipCertificateCheck

Omite las comprobaciones de validación de certificados. Esto incluye todas las validaciones, como la caducidad, la revocación y la entidad de certificación raíz de confianza.

Advertencia: el uso de este parámetro no es seguro y no se recomienda. Este modificador solo está pensado para usarse cuando un proveedor tiene un problema temporal con un certificado y únicamente con fines de prueba. Úsalo bajo tu propia responsabilidad.

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

[Usar Evergreen](https://eucpilots.com/evergreen/use/)
