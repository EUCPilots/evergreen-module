---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Update-Evergreen/
schema: 2.0.0
---

# Update-Evergreen

## SYNOPSIS

Télécharge et synchronise les fonctions et manifestes des applications Evergreen depuis le dépôt GitHub eucpilots/evergreen-apps.

## SYNTAX

```
Update-Evergreen [-Force] [-Release <String>] [<CommonParameters>]
```

## DESCRIPTION

Permet de séparer le module Evergreen principal du code et des manifestes propres aux applications. Télécharge les dernières versions de /Apps et /Manifests depuis un dépôt GitHub spécifié vers un emplacement accessible en écriture par l’utilisateur (aucun droit d’administrateur n’est requis). Par défaut, le cache local est téléchargé dans %LocalAppData%\Evergreen sous Windows et dans ~/.evergreen sous macOS et Linux.

## EXAMPLES

### EXAMPLE 1

```powershell
Update-Evergreen
```

Description :
Télécharge et synchronise les fonctions et manifestes des applications Evergreen depuis le dépôt GitHub eucpilots/evergreen-apps. Si des mises à jour sont nécessaires, le cache local est mis à jour. Dans le cas contraire, aucune mise à jour n’est effectuée.

### EXAMPLE 2

```powershell
Update-Evergreen -Force
```

Description :
Force le téléchargement complet et la synchronisation des fonctions et manifestes des applications Evergreen depuis le dépôt GitHub eucpilots/evergreen-apps, quel que soit l’état du cache local.

### EXAMPLE 2

```powershell
Update-Evergreen -Release "v25.09.27.16" -Force
```

Description :
Télécharge et synchronise la version v25.09.27.16 des fonctions et manifestes des applications Evergreen depuis le dépôt GitHub eucpilots/evergreen-apps.

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

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS
