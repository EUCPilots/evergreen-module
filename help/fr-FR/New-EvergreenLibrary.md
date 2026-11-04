---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/New-EvergreenLibrary/
schema: 2.0.0
---

# New-EvergreenLibrary

## SYNOPSIS

Crée une bibliothèque Evergreen au chemin d’accès spécifié.

## SYNTAX

```
New-EvergreenLibrary [-Path] <FileInfo> [-Name <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Crée une bibliothèque Evergreen au chemin d’accès spécifié. Une bibliothèque Evergreen est un répertoire contenant un fichier manifeste qui définit les programmes d’installation à stocker dans la bibliothèque (`EvergreenLibrary.json`). `New-EvergreenLibrary` crée une bibliothèque par défaut au chemin indiqué ; le fichier manifeste peut ensuite être modifié manuellement pour définir la liste des applications de la bibliothèque.

## EXAMPLES

### EXAMPLE 1

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary"
```

Description :
Crée une bibliothèque Evergreen dans le chemin d’accès \\server\EvergreenLibrary.

### EXAMPLE 2

```powershell
New-EvergreenLibrary -Path "\\server\EvergreenLibrary" -Name "AzureVirtualDesktopProd"
```

Description :
Crée une bibliothèque Evergreen dans le chemin d’accès \\server\EvergreenLibrary. Attribue le nom AzureVirtualDesktopProd au fichier manifeste `EvergreenLibrary.json`.

## PARAMETERS

### -Path

Spécifie le chemin d’accès à la bibliothèque Evergreen. L’emplacement cible doit être vide. Si le chemin contient EvergreenLibrary.json, `New-EvergreenLibrary` ne modifie pas le manifeste.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name

Spécifie un nom pour la bibliothèque.

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

### -WhatIf

Affiche ce qui se passerait si l’applet de commande était exécutée.

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

Demande une confirmation avant d’exécuter l’applet de commande.

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

### CommonParameters

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

New-EvergreenLibrary accepte des paramètres de type chaîne.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen
Author: Aaron Parker
## RELATED LINKS

[Créer une bibliothèque Evergreen :](https://eucpilots.com/evergreen/newlibrary/)
