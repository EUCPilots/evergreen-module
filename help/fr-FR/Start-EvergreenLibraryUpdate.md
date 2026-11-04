---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Start-EvergreenLibraryUpdate/
schema: 2.0.0
---

# Start-EvergreenLibraryUpdate

## SYNOPSIS

Déclenche la mise à jour et le téléchargement des programmes d’installation d’applications dans une bibliothèque Evergreen. `Start-EvergreenLibraryUpdate` lit le manifeste de la bibliothèque (`EvergreenLibrary.json`), qui définit les applications qu’elle contient, et utilise `Get-EvergreenApp` et `Save-EvergreenApp` pour y télécharger les derniers programmes d’installation.

## SYNTAX

```
Start-EvergreenLibraryUpdate [-Path] <FileInfo> [-Proxy <String>] [-ProxyCredential <PSCredential>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Une bibliothèque Evergreen permet de conserver plusieurs versions des programmes d’installation d’une application au lieu d’utiliser systématiquement la dernière version. Elle permet d’installer la version requise dans un environnement spécifique, y compris de revenir à une version précédente. Elle permet également de créer une image sans accès à Internet, en téléchargeant les programmes d’installation dans la bibliothèque puis en les utilisant pendant la création de l’image.

`Start-EvergreenLibraryUpdate` déclenche la mise à jour et le téléchargement des programmes d’installation d’applications dans une bibliothèque Evergreen. Elle lit le manifeste de la bibliothèque (`EvergreenLibrary.json`), qui définit les applications qu’elle contient, et utilise `Get-EvergreenApp` et `Save-EvergreenApp` pour y télécharger les derniers programmes d’installation.

## EXAMPLES

### EXAMPLE 1

```powershell
Start-EvergreenLibraryUpdate -Path "\\server\EvergreenLibrary"
```

Description :
`Start-EvergreenLibraryUpdate` lit le manifeste `EvergreenLibrary.json` situé dans \\server\EvergreenLibrary, qui définit les applications de cette bibliothèque. Elle utilise `Get-EvergreenApp` et `Save-EvergreenApp` pour télécharger les derniers programmes d’installation dans la bibliothèque.

## PARAMETERS

### -Path

Spécifie le chemin d’accès à la bibliothèque Evergreen. Celui-ci doit contenir EvergreenLibrary.json, dans la structure attendue, qui définit les applications à stocker dans la bibliothèque.

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

### -Proxy

Spécifie un serveur proxy pour la requête, au lieu de se connecter directement à la ressource Internet. Entrez l’URI d’un serveur proxy réseau.

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

Spécifie un compte d’utilisateur autorisé à utiliser le serveur proxy indiqué par le paramètre Proxy. Par défaut, l’utilisateur actuel est utilisé.

Saisissez un nom d’utilisateur, par exemple User01, Domain01\User01 ou User@Domain.Com, ou entrez un objet `PSCredential`, tel que celui généré par l’applet de commande `Get-Credential`.

Ce paramètre n’est valide que si le paramètre Proxy est également utilisé dans la commande.

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

### CommonParameters

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

Start-EvergreenLibraryUpdate accepte un paramètre de type chaîne.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Mettre à jour une bibliothèque Evergreen](https://eucpilots.com/evergreen/updatelibrary/)
