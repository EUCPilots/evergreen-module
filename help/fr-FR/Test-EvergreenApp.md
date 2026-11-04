---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Save-EvergreenApp/
schema: 2.0.0
---

# Test-EvergreenApp

## SYNOPSIS

Valide les URI cibles transmises à cette fonction par `Get-EvergreenApp`.

## SYNTAX

```
Test-EvergreenApp [-InputObject] <PSObject> [-Proxy <String>] [-ProxyCredential <PSCredential>]
 [-UserAgent <String>] [-ConnectionTimeoutSeconds <Int32>] [-NoProgress] [<CommonParameters>]
```

## DESCRIPTION

Evergreen inclut la fonction `Test-EvergreenApp`, qui valide les URL des programmes d’installation renvoyées par `Get-EvergreenApp`. Elle envoie d’abord une requête HEAD et réessaie les requêtes ayant échoué avec une requête GET par plages. Le résultat comprend l’état, le code d’état HTTP s’il est disponible et l’URI.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenApp -Name "MicrosoftOneDrive" | Test-EvergreenApp
```

Description :
Valide les propriétés URI de chaque objet renvoyé par `Get-EvergreenApp -Name "MicrosoftOneDrive"` et renvoie un résultat, le code d’état s’il est disponible et l’URI.

## PARAMETERS

### -InputObject

`Test-EvergreenApp` accepte les objets d’application renvoyés par `Get-EvergreenApp` et exige une propriété URI non vide. Les objets non valides génèrent un avertissement et un résultat false ; le traitement se poursuit pour les objets suivants.

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

### -Proxy

Spécifie un serveur proxy pour la requête, au lieu de se connecter directement à la ressource Internet. Entrez l’URI d’un serveur proxy réseau. Remarque : la prise en charge des serveurs proxy est expérimentale.

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

Ce paramètre n’est valide que si le paramètre Proxy est également utilisé dans la commande. Remarque : la prise en charge des serveurs proxy est expérimentale et n’a pas fait l’objet de tests approfondis.

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

La progression est masquée par défaut. Lorsque `-Verbose` est utilisé, elle s’affiche, sauf si `-NoProgress` est également spécifié.

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

### -ConnectionTimeoutSeconds

Spécifie le nombre maximal de secondes d’attente pour chaque requête Web. La valeur par défaut est de 30 secondes.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

Cette applet de commande prend en charge les paramètres communs : -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction et -WarningVariable. Pour plus d’informations, consultez [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

Test-EvergreenApp accepte la sortie de Get-EvergreenApp.

## OUTPUTS

### System.Management.Automation.PSObject

Fournit des objets contenant un résultat booléen, un code d’état HTTP s’il est disponible et l’URI.

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Tester les programmes d’installation](https://eucpilots.com/evergreen/test/)
