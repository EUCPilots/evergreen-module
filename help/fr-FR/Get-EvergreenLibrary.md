---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenLibrary/
schema: 2.0.0
---

# Get-EvergreenLibrary

## SYNOPSIS

Renvoie des détails sur une bibliothèque Evergreen, notamment sur les applications configurées dans la bibliothèque ainsi que sur les versions et les fichiers binaires téléchargés.

## SYNTAX

### Path

```
Get-EvergreenLibrary [-Path] <FileInfo> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### URI

```
Get-EvergreenLibrary -Uri <Uri> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Renvoie des détails sur une bibliothèque Evergreen située à un chemin d’accès spécifié.
Ces détails incluent les informations de la bibliothèque stockées dans `EvergreenLibrary.json` et les informations de version enregistrées pour chaque application de la bibliothèque.
Les téléchargements des applications et leurs informations de version doivent d’abord être récupérés avec `Invoke-EvergreenLibraryUpdate`.

## EXAMPLES

### Example 1
```
PS C:\> Get-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Renvoie des détails sur la bibliothèque Evergreen située dans \\server\EvergreenLibrary, notamment les informations de version enregistrées pour chaque application.

### Example 2
```
PS C:\> Get-EvergreenLibrary -Uri "https://st5srpuzr5v74.blob.core.windows.net/library/EvergreenLibrary.json"
```

Renvoie des détails sur la bibliothèque Evergreen du compte de stockage « st5srpuzr5v74 », dans le conteneur « library », notamment les informations de version enregistrées pour chaque application.

## PARAMETERS

### -Path

Spécifie le chemin d’accès local ou UNC à la bibliothèque Evergreen.

```yaml
Type: FileInfo
Parameter Sets: Path
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Uri

Spécifie l’URI d’une bibliothèque Evergreen hébergée dans le stockage Blob d’un compte de stockage Azure.

```yaml
Type: Uri
Parameter Sets: URI
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.FileInfo

## OUTPUTS

### System.Object

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Créer une bibliothèque Evergreen](https://eucpilots.com/evergreen/getlibrary.html)
