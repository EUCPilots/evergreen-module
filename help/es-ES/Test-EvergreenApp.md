---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Test-EvergreenApp

## SYNOPSIS

Valida los URI de destino que se pasan a esta función desde `Get-EvergreenApp`.

## SYNTAX

```
Test-EvergreenApp [-InputObject] <PSObject> [-Proxy <String>] [-ProxyCredential <PSCredential>]
 [-UserAgent <String>] [-ConnectionTimeoutSeconds <Int32>] [-NoProgress] [<CommonParameters>]
```

## DESCRIPTION

Evergreen incluye la función `Test-EvergreenApp`, que valida las URL de los instaladores de aplicaciones devueltas por `Get-EvergreenApp`. Primero envía una solicitud HEAD y vuelve a intentarlo con un GET por rangos si la solicitud falla. La salida incluye el resultado, el código de estado HTTP cuando está disponible y el URI.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "MicrosoftOneDrive" | Test-EvergreenApp
```

Descripción:
Valida las propiedades URI de cada objeto devuelto por `Get-EvergreenApp -Name "MicrosoftOneDrive"` y devuelve un resultado, el código de estado cuando está disponible y el URI.

## PARAMETERS

### -InputObject

`Test-EvergreenApp` acepta objetos de aplicación de `Get-EvergreenApp` y requiere una propiedad URI no vacía. Los objetos no válidos generan una advertencia y un resultado false; el procesamiento continúa con los objetos siguientes.

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

### -Proxy

Especifica un servidor proxy para la solicitud, en lugar de conectarse directamente al recurso de Internet. Introduce el URI de un servidor proxy de red. Nota: la compatibilidad con servidores proxy es experimental.

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

Este parámetro solo es válido si también se usa el parámetro Proxy en el comando. Nota: la compatibilidad con servidores proxy es experimental y no se ha probado exhaustivamente.

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

El progreso se suprime de forma predeterminada. Si se usa `-Verbose`, se muestra el progreso, salvo que también se especifique `-NoProgress`.

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

### -ConnectionTimeoutSeconds

Especifica el número máximo de segundos de espera para cada solicitud web. El valor predeterminado es 30 segundos.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

Este cmdlet admite los parámetros comunes: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction y -WarningVariable. Para obtener más información, consulta [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Test-EvergreenApp acepta la salida de Get-EvergreenApp.

## OUTPUTS

### System.Management.Automation.PSObject

Proporciona objetos que contienen un resultado booleano, un código de estado HTTP cuando está disponible y el URI.

## NOTES

Sitio: https://eucpilots.com/evergreen

Autor: Aaron Parker

## RELATED LINKS

[Probar instaladores](https://eucpilots.com/evergreen/test/)
