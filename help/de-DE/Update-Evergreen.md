---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Update-Evergreen/
schema: 2.0.0
---

# Update-Evergreen

## SYNOPSIS

Lädt die Evergreen-Apps-Funktionen und -Manifeste aus dem GitHub-Repository eucpilots/evergreen-apps herunter und synchronisiert sie.

## SYNTAX

```
Update-Evergreen [-Force] [-Release <String>] [<CommonParameters>]
```

## DESCRIPTION

Ermöglicht die Trennung des Evergreen-Kernmoduls von anwendungsspezifischem Code und Manifesten. Lädt die neuesten Versionen von /Apps und /Manifests aus einem angegebenen GitHub-Repository an einen vom Benutzer beschreibbaren Speicherort herunter (keine Administratorrechte erforderlich). Standardmäßig wird der lokale Cache unter Windows nach %LocalAppData%\Evergreen und unter macOS und Linux nach ~/.evergreen heruntergeladen.

## EXAMPLES

### EXAMPLE 1

```powershell
Update-Evergreen
```

Beschreibung:
Lädt die Evergreen-Apps-Funktionen und -Manifeste aus dem GitHub-Repository eucpilots/evergreen-apps herunter und synchronisiert sie. Falls Aktualisierungen erforderlich sind, wird der lokale Cache aktualisiert. Ist keine Aktualisierung erforderlich, wird nichts geändert.

### EXAMPLE 2

```powershell
Update-Evergreen -Force
```

Beschreibung:
Erzwingt unabhängig vom Zustand des lokalen Caches einen vollständigen Download und eine Synchronisierung der Evergreen-Apps-Funktionen und -Manifeste aus dem GitHub-Repository eucpilots/evergreen-apps.

### EXAMPLE 2

```powershell
Update-Evergreen -Release "v25.09.27.16" -Force
```

Beschreibung:
Lädt das Release v25.09.27.16 der Evergreen-Apps-Funktionen und -Manifeste aus dem GitHub-Repository eucpilots/evergreen-apps herunter und synchronisiert es.

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

Dieses Cmdlet unterstützt die allgemeinen Parameter: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction und -WarningVariable. Weitere Informationen finden Sie unter [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS
