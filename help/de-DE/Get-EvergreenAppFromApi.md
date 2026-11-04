---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppFromApi/
schema: 2.0.0
---

# Get-EvergreenAppFromApi

## SYNOPSIS

Gibt die neueste Version und die Download-URL(s) für eine vom Evergreen-Modul unterstützte Anwendung zurück. Diese Funktion liefert dieselben Daten wie Get-EvergreenApp, fragt diese jedoch über die Evergreen App Tracker-API ab.

## SYNTAX

```
Get-EvergreenAppFromApi [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Gibt die neueste Version und die Download-URL(s) für eine vom Evergreen-Modul unterstützte Anwendung zurück. Diese Funktion liefert dieselben Daten wie Get-EvergreenApp, fragt diese jedoch über die Evergreen App Tracker-API ab. Die API-Daten stammen aus einem Schlüssel/Wert-Speicher, der alle 12 Stunden von Get-EvergreenApp aktualisiert wird.

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

Beschreibung:
Gibt mithilfe der offiziellen Microsoft-Edge-Update-API unter [https://edgeupdates.microsoft.com/api/products](https://edgeupdates.microsoft.com/api/products) die aktuelle Version und die Download-URLs für Microsoft Edge zurück.

### EXAMPLE 2

```powershell
Get-EvergreenAppFromApi -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

Beschreibung:
Gibt die aktuelle Version und Download-URL für den Stable-Kanal des 64-Bit-Enterprise-Rings von Microsoft Edge zurück.

## PARAMETERS

### -Name

Der Name der Anwendung, für die Details zurückgegeben werden sollen.
Die Liste der unterstützten Anwendungen finden Sie mit `Find-EvergreenApp`.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[https://eucpilots.com/evergreen/invoke/](https://eucpilots.com/evergreen/invoke/)
