---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenApp/
schema: 2.0.0
---

# Get-EvergreenApp

## SYNOPSIS

Gibt die neueste Version und die Download-URL(s) für eine vom Evergreen-Modul unterstützte Anwendung zurück.

## SYNTAX

```
Get-EvergreenApp [-Name] <String> [[-AppParams] <Hashtable>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-SkipCertificateCheck] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Durchsucht die im Modul enthaltenen internen Anwendungsfunktionen und Manifeste, um die neueste Version und Download-URL(s) der angegebenen Anwendung zu ermitteln.

Die Ausgabe dieser Funktion kann an Where-Object übergeben werden, um anhand von Eigenschaften wie Prozessorarchitektur, Dateityp oder anderen Eigenschaften einen bestimmten Download herauszufiltern.

`Get-EvergreenApp` verwendet offizielle Quellen der Hersteller, darunter Update-APIs, Webabfragen und Code-Repositorys, um zur Laufzeit Details einer Zielanwendung zurückzugeben.

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

Beschreibung:
Gibt mithilfe der offiziellen Microsoft-Edge-Update-API unter [https://edgeupdates.microsoft.com/api/products](https://edgeupdates.microsoft.com/api/products) die aktuelle Version und die Download-URLs für Microsoft Edge zurück.

### EXAMPLE 2

```powershell
Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

Beschreibung:
Gibt die aktuelle Version und Download-URL für den Stable-Kanal des 64-Bit-Enterprise-Rings von Microsoft Edge zurück.

### EXAMPLE 3

```powershell
(Get-EvergreenApp -Name "MicrosoftOneDrive" | Where-Object { $_.Type -eq "Exe" -and $_.Ring -eq "Production" }) | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
```

Beschreibung:
Gibt die aktuelle Version und Download-URL für den Production-Ring von Microsoft OneDrive zurück und wählt die neueste Version aus, falls mehrere Releases zurückgegeben werden.

### EXAMPLE 4

```powershell
Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language -eq "English" -and $_.Architecture -eq "x86" }
```

Beschreibung:
Gibt die aktuelle Version und Download-URL für die englischsprachige 32-Bit-Version von Adobe Acrobat Reader DC zurück.

### EXAMPLE 5

```powershell
Find-EvergreenApp -Name "Teams" | Get-EvergreenApp
```

Beschreibung:
Listet die verfügbaren Anwendungen auf, auf die die Zeichenfolge „Teams“ zutrifft (z. B. Microsoft Teams), und übergibt die Ausgabe an `Get-EvergreenApp`, das den passenden Anwendungsnamen abfragt. Beachten Sie, dass `Get-EvergreenApp` nur die erste in der Pipeline zurückgegebene Anwendung verarbeitet, nicht alle übereinstimmenden Anwendungen.

### EXAMPLE 6

```powershell
Get-EvergreenApp -Name "MicrosoftTeams" | Save-EvergreenApp -Path "C:\Apps\Teams"
```

Beschreibung:
`Get-EvergreenApp` gibt die Details der neuesten Version von Microsoft Teams zurück, die über die Pipeline an `Save-EvergreenApp` übergeben werden. Die Ausgabe wird verwendet, um die Ziel-URLs in einer auf dem zurückgegebenen Objekt basierenden Verzeichnisstruktur unter C:\Apps\Teams zu speichern. In diesem Fall werden die Eigenschaften Ring und Architecture des zurückgegebenen Objekts für die Verzeichnisstruktur verwendet.

### EXAMPLE 7

```powershell
Get-EvergreenApp -Name "MozillaFirefox" -AppParams @{ Language = "en-GB", "es-ES" }
```

Beschreibung:
Übergibt die Sprachen en-GB und es-ES an MozillaFirefox, damit Downloads für diese Sprachen statt für die Standardsprache en-US zurückgegeben werden.

### EXAMPLE 8

```powershell
Get-EvergreenApp -Name "GitHubRelease" -AppParams @{ Uri = "https://api.github.com/repos/atom/atom/releases/latest" }
```

Beschreibung:
Übergibt der internen Anwendungsfunktion für `GetHubRelease` ein benutzerdefiniertes Repository, anstatt das im Manifest hinterlegte Repository zu verwenden. Dadurch kann `Get-EvergreenApp` Releases einer auf GitHub gehosteten Anwendung finden, die noch nicht von Evergreen unterstützt wird.

## PARAMETERS

### -Name

Der Name der Anwendung, für die Details zurückgegeben werden sollen.
Die Liste der unterstützten Anwendungen finden Sie mit `Find-EvergreenApp`.

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

Eine Hashtabelle mit Parametern, die an die interne Anwendungsfunktion übergeben werden.
Akzeptiert eine Hashtabelle aus Schlüsseln und Werten, die an die interne Anwendungsfunktion übergeben werden, um zusätzliche Funktionen zu ermöglichen (abhängig von der Anwendungsfunktion).

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

Fordert Sie vor der Ausführung des Cmdlets zur Bestätigung auf.

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

Gibt einen Proxyserver für die Anforderung an, anstatt eine direkte Verbindung mit der Internetressource herzustellen. Geben Sie den URI eines Netzwerkproxyservers ein.

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

Dieser Parameter ist nur gültig, wenn der Parameter Proxy ebenfalls im Befehl verwendet wird.

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

Zeigt an, was bei Ausführung des Cmdlets geschehen würde. Das Cmdlet wird nicht ausgeführt.

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

Überspringt die Zertifikatsüberprüfung. Dies umfasst alle Validierungen wie Ablauf, Widerruf, vertrauenswürdige Stammzertifizierungsstelle usw.

Warnung: Die Verwendung dieses Parameters ist nicht sicher und wird nicht empfohlen. Dieser Schalter ist ausschließlich für den Fall vorgesehen, dass bei einem Hersteller vorübergehend ein Zertifikatsproblem besteht, und sollte nur zu Testzwecken verwendet werden. Die Verwendung erfolgt auf eigene Gefahr.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen verwenden](https://eucpilots.com/evergreen/use/)
