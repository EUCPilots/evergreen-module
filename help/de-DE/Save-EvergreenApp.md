---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Save-EvergreenApp

## SYNOPSIS

Lädt die mit `Get-EvergreenApp` abgerufenen Ziel-URIs in eine Verzeichnisstruktur herunter.

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

Speichert die Ziel-URLs aus der Ausgabe von `Get-EvergreenApp` mithilfe der Eigenschaften des an die Funktion übergebenen Objekts in einer Verzeichnisstruktur unterhalb von -Path.

`Get-EvergreenApp` gibt ein Objekt zurück, das Anwendungseigenschaften enthalten kann, und zwar in der folgenden Reihenfolge: Product, Track, Channel, Release, Ring, Version, Language und (Prozessor-)Architecture. Es werden nur Eigenschaften verwendet, die im Zielobjekt vorhanden sind.

Damit lassen sich Installationsprogramme oder Updater der Zielanwendung ganz einfach in einer einheitlichen Verzeichnisstruktur speichern, ohne die Zielverzeichnisstruktur selbst erstellen oder andere Funktionen zum Herunterladen der Datei verwenden zu müssen.

Um das Standardverhalten zu überschreiben, bei dem die Verzeichnisstruktur anhand der Eigenschaften des an die Funktion übergebenen Objekts erstellt wird, verwenden Sie den Parameter `-CustomPath`, um einen exakten Speicherpfad anzugeben. Beachten Sie, dass bei dieser Methode die erste Datei heruntergeladen wird. Anschließend werden Dateien aus einem von `Get-EvergreenApp` übergebenen Objekt übersprungen, wenn sie denselben Namen haben.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -Path "C:\Temp\Adobe"
```

Beschreibung:
Lädt jede in den von `Get-EvergreenApp -Name "AdobeAcrobat"` zurückgegebenen URIs angegebene Datei in eine Verzeichnisstruktur unterhalb von C:\Temp\Adobe herunter. Für jede Datei entsteht beispielsweise folgende Verzeichnisstruktur: C:\Temp\Adobe\<Product>\<Track>\<Version>\<Language>\<Architecture>.

### EXAMPLE 2

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -CustomPath "C:\Temp\Adobe"
```

Beschreibung:
Lädt alle von `Get-EvergreenApp -Name "AdobeAcrobat"` zurückgegebenen URIs in ein Verzeichnis namens C:\Temp\Adobe herunter. Alle in der URI-Eigenschaft angegebenen Dateien werden in diesem Verzeichnis gespeichert.

## PARAMETERS

### -InputObject

`Save-EvergreenApp` akzeptiert das PSObject aus `Get-EvergreenApp`. `Save-EvergreenApp` prüft, ob mindestens die Eigenschaften Version und URI vorhanden sind.

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

Das Zielverzeichnis, unter dem eine Verzeichnisstruktur erstellt und Anwendungsinstallationsprogramme gespeichert werden. In der Regel wird für jede Anwendung ein eigener Zielpfad verwendet.

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

Gibt einen einzelnen Verzeichnispfad an, in dem alle Anwendungsinstallationsprogramme gespeichert werden. Es werden keine Unterverzeichnisse erstellt.

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
Default value: [System.Management.Automation.PSCredential]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProgress

`Save-EvergreenApp` verwendet `Invoke-WebRequest`, um Installationsprogramme der Zielanwendung herunterzuladen. Der Downloadfortschritt wird standardmäßig unterdrückt, um Downloads zu beschleunigen. Bei Verwendung von `-Verbose` wird der Downloadfortschritt jedoch angezeigt. Verwenden Sie `-NoProgress` zusammen mit `-Verbose`, um den Downloadfortschritt zu unterdrücken und gleichzeitig ausführliche Ausgaben anzuzeigen.

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

Zeigt an, was bei Ausführung des Cmdlets geschehen würde.
Das Cmdlet wird nicht ausgeführt.

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

### -Force

Erzwingt, dass diese Funktion die Installationsprogramme der Zielanwendung aus der URI-Eigenschaft herunterlädt, auch wenn sie bereits im Zielverzeichnis vorhanden sind.

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

### CommonParameters

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Save-EvergreenApp akzeptiert die Ausgabe von Get-EvergreenApp.

## OUTPUTS

### System.Management.Automation.PSObject

Gibt eine Liste der Pfade der heruntergeladenen Zieldateien zurück.

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Anwendungsinstallationsprogramme herunterladen:](https://eucpilots.com/evergreen/save)
