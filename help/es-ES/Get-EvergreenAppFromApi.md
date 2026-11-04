---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppFromApi/
schema: 2.0.0
---

# Get-EvergreenAppFromApi

## SYNOPSIS

Devuelve la versión más reciente y las URL de descarga de una aplicación compatible con el módulo Evergreen. Esta función devuelve los mismos datos que Get-EvergreenApp, pero consulta la API de Evergreen App Tracker para obtenerlos.

## SYNTAX

```
Get-EvergreenAppFromApi [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Devuelve la versión más reciente y las URL de descarga de una aplicación compatible con el módulo Evergreen. Esta función devuelve los mismos datos que Get-EvergreenApp, pero consulta la API de Evergreen App Tracker para obtenerlos. Los datos de la API proceden de un almacén de clave/valor que Get-EvergreenApp actualiza cada 12 horas.

## EXAMPLES

### Example 1

```powershell
Get-EvergreenAppFromApi -Name "MicrosoftEdge"

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
Get-EvergreenAppFromApi -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

Descripción:
Devuelve la versión actual y la URL de descarga del canal Stable de la edición Enterprise de 64 bits de Microsoft Edge.

## PARAMETERS

### -Name

Nombre de la aplicación cuyos detalles se van a devolver.
La lista de aplicaciones compatibles se puede consultar con `Find-EvergreenApp`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

[https://eucpilots.com/evergreen/invoke/](https://eucpilots.com/evergreen/invoke/)
