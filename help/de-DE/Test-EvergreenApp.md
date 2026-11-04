---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Test-EvergreenApp

## SYNOPSIS

Überprüft die Ziel-URIs, die dieser Funktion von `Get-EvergreenApp` übergeben werden.

## SYNTAX

```
Test-EvergreenApp [-InputObject] <PSObject> [-Proxy <String>] [-ProxyCredential <PSCredential>]
 [-UserAgent <String>] [-ConnectionTimeoutSeconds <Int32>] [-NoProgress] [<CommonParameters>]
```

## DESCRIPTION

Evergreen enthält die Funktion `Test-EvergreenApp`, die von `Get-EvergreenApp` zurückgegebene URLs von Anwendungsinstallationsprogrammen überprüft. Zunächst wird eine HEAD-Anforderung gesendet. Fehlgeschlagene Anforderungen werden mit einer GET-Anforderung mit Bereichsangabe wiederholt. Die Ausgabe enthält das Ergebnis, sofern verfügbar den HTTP-Statuscode und den URI.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "MicrosoftOneDrive" | Test-EvergreenApp
```

Beschreibung:
Überprüft die URI-Eigenschaften jedes von `Get-EvergreenApp -Name "MicrosoftOneDrive"` zurückgegebenen Objekts und gibt ein Ergebnis, sofern verfügbar den Statuscode und den URI zurück.

## PARAMETERS

### -InputObject

`Test-EvergreenApp` akzeptiert Anwendungsobjekte von `Get-EvergreenApp` und erfordert eine nicht leere URI-Eigenschaft. Ungültige Objekte erzeugen eine Warnung und ein false-Ergebnis; die Verarbeitung wird mit nachfolgenden Objekten fortgesetzt.

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

Gibt einen Proxyserver für die Anforderung an, anstatt eine direkte Verbindung mit der Internetressource herzustellen. Geben Sie den URI eines Netzwerkproxyservers ein. Hinweis: Die Proxyunterstützung ist experimentell.

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

Gibt ein Benutzerkonto an, das zur Verwendung des mit dem Parameter Proxy angegebenen Proxyservers berechtigt ist. Standardmäßig wird der aktuelle Benutzer verwendet.

Geben Sie einen Benutzernamen ein, z. B. User01 oder Domain01\User01, User@Domain.Com, oder geben Sie ein `PSCredential`-Objekt ein, etwa ein mit dem Cmdlet `Get-Credential` generiertes Objekt.

Dieser Parameter ist nur gültig, wenn der Parameter Proxy ebenfalls im Befehl verwendet wird. Hinweis: Die Unterstützung für Proxyserver ist experimentell und wurde nicht umfassend getestet.

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

Der Fortschritt wird standardmäßig unterdrückt. Bei Verwendung von `-Verbose` wird er angezeigt, sofern nicht auch `-NoProgress` angegeben wird.

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

Gibt eine Benutzer-Agent-Zeichenfolge für die Webanforderung an.

Der Standardbenutzer-Agent ähnelt dem folgenden und variiert geringfügig je nach Betriebssystem und Plattform.

Mozilla/5.0 (Macintosh; Darwin 22.2.0 Darwin Kernel Version 22.2.0: Fri Nov 11 02:04:44 PST 2022; root:xnu-8792.61.2~4/RELEASE_ARM64_T8103; en-AU) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6

Um eine Website mit der standardmäßigen Benutzer-Agent-Zeichenfolge der meisten Internetbrowser zu testen, verwenden Sie Eigenschaften der Klasse PSUserAgent, z. B. Chrome, FireFox, InternetExplorer, Opera und Safari.

Der folgende Befehl verwendet beispielsweise die Benutzer-Agent-Zeichenfolge für Internet Explorer: Save-EvergreenApp -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)

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

Gibt die maximale Anzahl von Sekunden an, die auf jede Webanforderung gewartet wird. Der Standardwert beträgt 30 Sekunden.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Test-EvergreenApp akzeptiert die Ausgabe von Get-EvergreenApp.

## OUTPUTS

### System.Management.Automation.PSObject

Gibt Objekte zurück, die ein boolesches Ergebnis, sofern verfügbar einen HTTP-Statuscode und den URI enthalten.

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Installationsprogramme testen](https://eucpilots.com/evergreen/test/)
