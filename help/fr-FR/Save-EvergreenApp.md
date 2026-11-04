---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Save-EvergreenApp

## SYNOPSIS

Télécharge les URI cibles transmises à cette fonction par `Get-EvergreenApp` dans une arborescence de répertoires.

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

Enregistre les URL cibles issues de la sortie de `Get-EvergreenApp` dans une arborescence sous -Path, à l’aide des propriétés de l’objet transmis à la fonction.

`Get-EvergreenApp` renvoie un objet pouvant inclure des propriétés de l’application, dans l’ordre suivant : Product, Track, Channel, Release, Ring, Version, Language et Architecture (du processeur). Seules les propriétés présentes dans l’objet cible sont utilisées.

Cela simplifie l’enregistrement des programmes d’installation ou de mise à jour de l’application cible dans une arborescence cohérente, sans avoir à créer soi-même cette arborescence ni à utiliser d’autres fonctions pour télécharger le fichier.

Pour remplacer le comportement par défaut, qui crée l’arborescence à partir des propriétés de l’objet transmis à la fonction, utilisez le paramètre `-CustomPath` pour spécifier le chemin exact où enregistrer les fichiers. Notez que cette méthode télécharge le premier fichier, puis ignore les fichiers de l’objet transmis par `Get-EvergreenApp` qui portent le même nom.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -Path "C:\Temp\Adobe"
```

Description :
Télécharge chaque fichier indiqué par les URI renvoyées par `Get-EvergreenApp -Name "AdobeAcrobat"` dans une arborescence sous C:\Temp\Adobe, créant pour chaque fichier une structure semblable à : C:\Temp\Adobe\<Product>\<Track>\<Version>\<Language>\<Architecture>.

### EXAMPLE 2

```powershell
Get-EvergreenApp -Name "AdobeAcrobat" | Save-EvergreenApp -CustomPath "C:\Temp\Adobe"
```

Description :
Télécharge toutes les URI renvoyées par `Get-EvergreenApp -Name "AdobeAcrobat"` dans le répertoire C:\Temp\Adobe. Tous les fichiers indiqués dans la propriété URI sont enregistrés dans ce répertoire.

## PARAMETERS

### -InputObject

`Save-EvergreenApp` accepte l’objet PSObject renvoyé par `Get-EvergreenApp`. `Save-EvergreenApp` vérifie la présence d’au moins ces propriétés : Version et URI.

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

Répertoire cible sous lequel une arborescence sera créée et où les programmes d’installation des applications seront enregistrés. En général, le chemin cible correspond à un chemin par application.

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

Spécifie le chemin d’un répertoire unique où seront enregistrés tous les programmes d’installation des applications. Aucun sous-répertoire ne sera créé.

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
Default value: [System.Management.Automation.PSCredential]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProgress

`Save-EvergreenApp` utilise `Invoke-WebRequest` pour télécharger les programmes d’installation des applications cibles. La progression du téléchargement est masquée par défaut afin d’accélérer les téléchargements ; toutefois, elle s’affiche lorsque `-Verbose` est utilisé. Utilisez `-NoProgress` avec `-Verbose` pour masquer la progression tout en affichant la sortie détaillée.

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

Affiche ce qui se passerait si l’applet de commande était exécutée.
L’applet de commande n’est pas exécutée.

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

### -Force

Force cette fonction à télécharger les programmes d’installation des applications cibles depuis la propriété URI, même s’ils existent déjà dans le répertoire cible.

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

Spécifie une chaîne d’agent utilisateur pour la requête Web.

L’agent utilisateur par défaut est similaire à celui présenté ci-dessous, avec de légères variations selon le système d’exploitation et la plateforme.

Mozilla/5.0 (Macintosh; Darwin 22.2.0 Darwin Kernel Version 22.2.0: Fri Nov 11 02:04:44 PST 2022; root:xnu-8792.61.2~4/RELEASE_ARM64_T8103; en-AU) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6

Pour tester un site Web avec la chaîne d’agent utilisateur standard utilisée par la plupart des navigateurs Internet, utilisez les propriétés de la classe PSUserAgent, telles que Chrome, FireFox, InternetExplorer, Opera et Safari.

Par exemple, la commande suivante utilise la chaîne d’agent utilisateur d’Internet Explorer : Save-EvergreenApp -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)

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

### System.Management.Automation.PSObject

Save-EvergreenApp accepte la sortie de Get-EvergreenApp.

## OUTPUTS

### System.Management.Automation.PSObject

Fournit une liste des chemins d’accès aux fichiers cibles téléchargés.

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Télécharger les programmes d’installation d’applications :](https://eucpilots.com/evergreen/save)
