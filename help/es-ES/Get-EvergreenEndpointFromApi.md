---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenEndpointFromApi/
schema: 2.0.0
---

# Get-EvergreenEndpointFromApi

## SYNOPSIS

Devuelve una matriz de aplicaciones, puntos de conexión y puertos que Evergreen necesita para obtener actualizaciones de aplicaciones y URL de descarga de aplicaciones.

## SYNTAX

```
Get-EvergreenEndpointFromApi [-Name] <String> [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Consulta la API de Evergreen para devolver las URL de los puntos de conexión y los puertos TCP necesarios para usar Evergreen y encontrar versiones de aplicaciones y descargar instaladores.

La lista de puntos de conexión devuelta se puede usar con fines de auditoría y para definir una lista de permitidos en firewalls o servidores proxy cuando el acceso a Internet está restringido.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenEndpointFromApi

Application  Endpoints                                                                              Ports
-----------  ---------                                                                              -----
1Password    {1password.com, app-updates.agilebits.com, downloads.1password.com, cdn.agilebits.com} {443}
1Password7   {1password.com, c.1password.com, download.app.com"}                                    {443}
1PasswordCLI {app-updates.agilebits.com, cache.agilebits.com, developer.1password.com}              {443}
7zip         {nchc.dl.sourceforge.net, sourceforge.net, www.7-zip.org, versaweb.dl.sourceforge.net} {443}
7ZipZS       {api.github.com, mcmilk.de, github.com}                                                {443}
```

Descripción:
Devuelve la lista de fuentes de URL de puntos de conexión y puertos de todas las aplicaciones compatibles actualmente con Evergreen.

### EXAMPLE 2

```powershell
Get-EvergreenEndpointFromApi -Name "MicrosoftEdge", "MicrosoftTeams"

Application    Endpoints                                                                              Ports
-----------    ---------                                                                              -----
MicrosoftEdge  {edgeupdates.microsoft.com, www.microsoft.com, msedge.sf.dl.delivery.mp.microsoft.com} {443}
MicrosoftTeams {config.teams.microsoft.com, www.microsoft.com, statics.teams.cdn.office.net}          {443}
```

Descripción:
Devuelve la lista de fuentes de URL de puntos de conexión y puertos para determinar las versiones y descargas de Microsoft Edge y Microsoft Teams.

### EXAMPLE 3

```powershell
Get-EvergreenEndpointFromApi | Select-Object -ExpandProperty Endpoints -Unique

1password.com
app-updates.agilebits.com
downloads.1password.com
cdn.agilebits.com
c.1password.com
```

Descripción:
Devuelve una matriz sencilla con todas las URL de puntos de conexión únicas de las aplicaciones compatibles actualmente con Evergreen.

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

### CommonParameters

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Array

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Recuperar los puntos de conexión que usa Evergreen](https://eucpilots.com/evergreen/endpoints/)
