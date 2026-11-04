---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenManifest/
schema: 2.0.0
---

# Export-EvergreenManifest

## SYNOPSIS

Exporta un manifiesto JSON de aplicación de Evergreen como una tabla hash.

## SYNTAX

```
Export-EvergreenManifest [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Exporta un manifiesto JSON de aplicación de Evergreen como una tabla hash que se puede usar en distintas funciones, por ejemplo, en scripts o para guardar en un archivo externo.

## EXAMPLES

### EXAMPLE 1

```powershell
Export-EvergreenManifest -Name "MicrosoftEdge"
```

Descripción:
Exporta el manifiesto de la aplicación "MicrosoftEdge".

## PARAMETERS

### -Name

Nombre de la aplicación cuyos detalles se van a devolver. La lista de aplicaciones compatibles se puede consultar con `Find-EvergreenApp`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

[Introducción a Evergreen](https://eucpilots.com/evergreen/)
