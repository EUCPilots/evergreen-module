---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Export-EvergreenApp/
schema: 2.0.0
---

# Export-EvergreenApp

## SYNOPSIS

Exporte vers un fichier JSON externe les détails de l’application obtenus par `Get-EvergreenApp`. Cette fonction lit tout fichier JSON existant pour cette application, y ajoute les informations de la nouvelle version, trie les versions pour éliminer les doublons, puis écrit le contenu mis à jour dans le fichier JSON cible.

## SYNTAX

```
Export-EvergreenApp [-InputObject] <Array> -Path <FileInfo> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Exporte vers un fichier JSON externe les détails de l’application obtenus par `Get-EvergreenApp`. Cette fonction lit tout fichier JSON existant pour cette application, y ajoute les informations de la nouvelle version, trie les versions pour éliminer les doublons, puis écrit le contenu mis à jour dans le fichier JSON cible.

## EXAMPLES

### EXAMPLE 1

```powershell
$OneDrive = Get-EvergreenApp -Name "MicrosoftOneDrive"
Save-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive"
Export-EvergreenApp -InputObject $OneDrive -Path "C:\Evergreen\OneDrive\MicrosoftOneDrive.json"
```

Description :
`Get-EvergreenApp` renvoie les informations de version de `MicrosoftOneDrive`. `Save-EvergreenApp` sert ensuite à enregistrer les programmes d’installation renvoyés dans `C:\Evergreen\OneDrive`. Les informations de version sont alors enregistrées dans `C:\Evergreen\OneDrive\MicrosoftOneDrive.json` avec `Export-EvergreenApp`. Si des informations de version figurent déjà dans le fichier cible, les informations supplémentaires y sont ajoutées.

## PARAMETERS

### -InputObject

`Export-EvergreenApp` accepte l’objet PSObject renvoyé par `Get-EvergreenApp`.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

Spécifie le chemin d’accès au fichier JSON dans lequel les informations de version seront stockées. Si le fichier n’existe pas, le répertoire parent doit déjà exister.

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### -WhatIf

Affiche ce qui se passerait si l’applet de commande était exécutée. L’applet de commande n’est pas exécutée.

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

### CommonParameters

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Export-EvergreenApp accepte la sortie de Get-EvergreenApp.

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Exporter les informations de version d’une application](https://eucpilots.com/evergreen/export/)
