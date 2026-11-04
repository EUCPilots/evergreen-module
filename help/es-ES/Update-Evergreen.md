---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Update-Evergreen/
schema: 2.0.0
---

# Update-Evergreen

## SYNOPSIS

Descarga y sincroniza las funciones y los manifiestos de Evergreen Apps desde el repositorio de GitHub eucpilots/evergreen-apps.

## SYNTAX

```
Update-Evergreen [-Force] [-Release <String>] [<CommonParameters>]
```

## DESCRIPTION

Permite separar el módulo principal de Evergreen del código y los manifiestos específicos de las aplicaciones. Descarga las versiones más recientes de /Apps y /Manifests desde un repositorio de GitHub especificado a una ubicación en la que el usuario tenga permiso de escritura (no se requieren permisos de administrador). De forma predeterminada, la caché local se descarga en %LocalAppData%\Evergreen en Windows y en ~/.evergreen en macOS y Linux.

## EXAMPLES

### EXAMPLE 1

```powershell
Update-Evergreen
```

Descripción:
Descarga y sincroniza las funciones y los manifiestos de Evergreen Apps desde el repositorio de GitHub eucpilots/evergreen-apps. Si es necesario actualizar, se actualiza la caché local. Si no es necesario, no se realiza ninguna actualización.

### EXAMPLE 2

```powershell
Update-Evergreen -Force
```

Descripción:
Fuerza la descarga y sincronización completas de las funciones y los manifiestos de Evergreen Apps desde el repositorio de GitHub eucpilots/evergreen-apps, independientemente del estado de la caché local.

### EXAMPLE 2

```powershell
Update-Evergreen -Release "v25.09.27.16" -Force
```

Descripción:
Descarga y sincroniza la versión v25.09.27.16 de las funciones y los manifiestos de Evergreen Apps desde el repositorio de GitHub eucpilots/evergreen-apps.

## PARAMETERS

### -Force

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

### -Release

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

## OUTPUTS

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS
