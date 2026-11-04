---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenApp/
schema: 2.0.0
---

# Get-EvergreenApp

## SYNOPSIS

Renvoie la dernière version et les URL de téléchargement d’une application prise en charge par le module Evergreen.

## SYNTAX

```
Get-EvergreenApp [-Name] <String> [[-AppParams] <Hashtable>] [-Proxy <String>]
 [-ProxyCredential <PSCredential>] [-SkipCertificateCheck] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Interroge les fonctions d’application et les manifestes internes inclus dans le module afin de trouver la dernière version et les URL de téléchargement de l’application spécifiée.

La sortie de cette fonction peut être transmise à Where-Object afin de filtrer un téléchargement précis selon des propriétés telles que l’architecture du processeur, le type de fichier ou d’autres propriétés.

`Get-EvergreenApp` utilise des sources officielles des éditeurs, notamment des API de mise à jour, des requêtes Web et des dépôts de code, pour renvoyer à l’exécution les détails d’une application cible.

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

Description :
Renvoie la version actuelle et les URL de téléchargement de Microsoft Edge à l’aide de l’API officielle de mise à jour Microsoft Edge à l’adresse [https://edgeupdates.microsoft.com/api/products](https://edgeupdates.microsoft.com/api/products).

### EXAMPLE 2

```powershell
Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" }
```

Description :
Renvoie la version actuelle et l’URL de téléchargement de Microsoft Edge pour le canal Stable et l’anneau Enterprise 64 bits.

### EXAMPLE 3

```powershell
(Get-EvergreenApp -Name "MicrosoftOneDrive" | Where-Object { $_.Type -eq "Exe" -and $_.Ring -eq "Production" }) | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
```

Description :
Renvoie la version actuelle et l’URL de téléchargement de l’anneau Production de Microsoft OneDrive et sélectionne la version la plus récente si plusieurs versions sont renvoyées.

### EXAMPLE 4

```powershell
Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language -eq "English" -and $_.Architecture -eq "x86" }
```

Description :
Renvoie la version actuelle et l’URL de téléchargement correspondant à la version 32 bits en anglais d’Adobe Acrobat Reader DC.

### EXAMPLE 5

```powershell
Find-EvergreenApp -Name "Teams" | Get-EvergreenApp
```

Description :
Répertorie les applications disponibles correspondant à la chaîne « Teams » (par exemple, Microsoft Teams) et transmet le résultat à `Get-EvergreenApp`, qui interroge le nom d’application correspondant. Notez que `Get-EvergreenApp` ne traite que la première application reçue dans le pipeline, et non toutes les applications correspondantes.

### EXAMPLE 6

```powershell
Get-EvergreenApp -Name "MicrosoftTeams" | Save-EvergreenApp -Path "C:\Apps\Teams"
```

Description :
`Get-EvergreenApp` renvoie les détails de la dernière version de Microsoft Teams, qui sont transmis via le pipeline à `Save-EvergreenApp`. Le résultat sert à enregistrer les URL cibles dans C:\Apps\Teams, selon une arborescence basée sur l’objet renvoyé. Dans cet exemple, les propriétés Ring et Architecture de l’objet renvoyé sont utilisées dans l’arborescence.

### EXAMPLE 7

```powershell
Get-EvergreenApp -Name "MozillaFirefox" -AppParams @{ Language = "en-GB", "es-ES" }
```

Description :
Transmet les langues en-GB et es-ES à MozillaFirefox afin de renvoyer les téléchargements dans ces langues plutôt que dans la langue par défaut en-US.

### EXAMPLE 8

```powershell
Get-EvergreenApp -Name "GitHubRelease" -AppParams @{ Uri = "https://api.github.com/repos/atom/atom/releases/latest" }
```

Description :
Transmet un dépôt personnalisé à la fonction d’application interne `GetHubRelease` au lieu d’utiliser le dépôt indiqué dans le manifeste. `Get-EvergreenApp` peut ainsi trouver les versions d’une application hébergée sur GitHub qui n’est pas encore prise en charge par Evergreen.

## PARAMETERS

### -Name

Nom de l’application dont les détails doivent être renvoyés.
La liste des applications prises en charge est disponible avec `Find-EvergreenApp`.

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

Table de hachage contenant les paramètres à transmettre à la fonction d’application interne.
Accepte une table de hachage de clés et de valeurs qui seront transmises à la fonction d’application interne pour activer des fonctionnalités supplémentaires (selon la fonction d’application).

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

### -SkipCertificateCheck

Ignore les vérifications de validation du certificat, notamment celles portant sur l’expiration, la révocation, l’autorité racine de confiance, etc.

Avertissement : l’utilisation de ce paramètre n’est pas sécurisée et n’est pas recommandée. Ce commutateur est uniquement destiné aux tests lorsqu’un éditeur rencontre un problème temporaire de certificat. Utilisez-le à vos risques et périls.

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

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Utiliser Evergreen](https://eucpilots.com/evergreen/use/)
