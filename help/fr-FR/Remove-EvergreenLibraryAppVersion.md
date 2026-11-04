---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Remove-EvergreenLibraryAppVersion/
schema: 2.0.0
---

# Remove-EvergreenLibraryAppVersion

## SYNOPSIS

Supprime les anciennes versions des programmes d’installation d’applications d’une bibliothèque Evergreen tout en conservant les versions les plus récentes dans chaque manifeste d’application.

## SYNTAX

```powershell
Remove-EvergreenLibraryAppVersion [-Path] <FileInfo> [[-Keep] <Int32>] [[-Name] <String[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

`Remove-EvergreenLibraryAppVersion` élague les versions historiques d’un manifeste d’application d’une bibliothèque Evergreen.

L’applet de commande vérifie que `-Path` pointe vers une bibliothèque Evergreen en recherchant `EvergreenLibrary.json`. Pour chaque application cible, elle lit le manifeste de l’application (`<ApplicationName>.json`), trie les versions de la plus récente à la plus ancienne, conserve le nombre d’entrées défini par `-Keep`, supprime du disque les fichiers d’installation plus anciens et réécrit les versions conservées dans le manifeste de l’application.

Par défaut, toutes les applications de la bibliothèque sont traitées et leurs 3 versions les plus récentes sont conservées.

La limite de conservation compte les entrées individuelles du manifeste, tant dans Windows PowerShell 5.1 que dans PowerShell 7. Le manifeste conservé reste un tableau JSON, même avec `-Keep 1`. Les chemins des programmes d’installation peuvent être absolus, relatifs au répertoire de l’application ou être des tableaux de chemins enregistrés par d’anciennes versions du module. Seuls les fichiers d’installation indiqués dans les entrées élaguées sont supprimés ; les fichiers également référencés par des entrées conservées sont préservés. Les chemins situés en dehors du répertoire de l’application et ceux qui traversent des points d’analyse sont ignorés. Les répertoires de versions vides ne sont pas supprimés.

Les fichiers laissés par un élagage antérieur ne peuvent pas être supprimés en réexécutant cette applet de commande si leurs entrées ne figurent plus dans le manifeste. Cette applet de commande ne recherche pas les fichiers d’installation non répertoriés.

Utilisez `-Verbose` pour diagnostiquer la validation de la bibliothèque, la sélection des applications, la lecture des manifestes, le tri des versions, les entrées conservées ou élaguées, les fichiers d’installation ignorés et les mises à jour des manifestes. Les messages distinguent l’élagage prévu des fichiers réellement supprimés et signalent les actions ignorées à cause de `-WhatIf` ou d’une confirmation refusée. Les messages détaillés ne modifient pas les objets renvoyés.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary"
```

Description :
Traite toutes les applications de la bibliothèque et conserve les 3 versions les plus récentes de chacune. Les anciens fichiers d’installation sont supprimés et chaque manifeste d’application est mis à jour.

### EXAMPLE 2

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 2 -Name "MicrosoftEdge", "Zoom"
```

Description :
Traite uniquement MicrosoftEdge et Zoom, conserve les 2 versions les plus récentes dans chaque manifeste d’application et supprime les anciens fichiers d’installation.

### EXAMPLE 3

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Keep 5 -WhatIf
```

Description :
Affiche les fichiers et manifestes qui seraient modifiés pour conserver les 5 versions les plus récentes, sans apporter de modifications.

### EXAMPLE 4

```powershell
Remove-EvergreenLibraryAppVersion -Path "\\server\EvergreenLibrary" -Name "MicrosoftEdge" -Keep 3 -WhatIf -Verbose
```

Description :
Affiche des messages de diagnostic détaillés et les modifications prévues pour MicrosoftEdge, sans supprimer de programmes d’installation ni mettre à jour son manifeste.

## PARAMETERS

### -Path

Spécifie le chemin d’accès à une bibliothèque Evergreen. Ce chemin doit exister et contenir `EvergreenLibrary.json`.

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

### -Keep

Spécifie le nombre de versions à conserver dans le manifeste de chaque application cible. Les versions plus anciennes sont supprimées.

```yaml
Type: Int32
Parameter Sets: Path
Aliases:

Required: False
Position: 1
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Spécifie un ou plusieurs noms d’applications du manifeste de la bibliothèque à traiter. Si ce paramètre est omis, toutes les applications sont traitées.

```yaml
Type: String[]
Parameter Sets: Path
Aliases:

Required: False
Position: 2
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

### System.IO.FileInfo

`Remove-EvergreenLibraryAppVersion` accepte une entrée par nom de propriété pour `Path`.

## OUTPUTS

### System.Management.Automation.PSCustomObject

Renvoie un objet par application traitée avec les propriétés suivantes :

- `ApplicationName`
- `Keep`
- `KeptCount`
- `PrunedCount` : nombre d’entrées sélectionnées pour l’élagage.
- `RemovedCount` : nombre d’entrées supprimées du manifeste.
- `RemovedFileCount` : nombre de fichiers d’installation effectivement supprimés.
- `RemovedFiles` : chemins d’accès aux fichiers d’installation effectivement supprimés.
- `ManifestPath`

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Mettre à jour une bibliothèque Evergreen](https://eucpilots.com/evergreen/updatelibrary/)
