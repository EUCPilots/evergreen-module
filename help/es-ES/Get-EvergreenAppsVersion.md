---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppsVersion/
schema: 2.0.0
---

# Get-EvergreenAppsVersion

## SYNOPSIS

Devuelve la versión de la versión más reciente del repositorio de Evergreen Apps.

## SYNTAX

```
Get-EvergreenAppsVersion [<CommonParameters>]
```

## DESCRIPTION

Consulta la API de versiones de GitHub para obtener la versión más reciente del repositorio de Evergreen Apps y la devuelve.

Se aplican los límites de frecuencia de la API de GitHub. Establece la variable de entorno `GITHUB_TOKEN` o `GH_TOKEN` para usar una solicitud autenticada.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenAppsVersion
```

Descripción:
Devuelve la versión más reciente disponible del repositorio de Evergreen Apps.

## PARAMETERS

### CommonParameters

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.String

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Repositorio de Evergreen Apps](https://github.com/EUCPilots/evergreen-apps)
