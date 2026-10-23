---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppsVersion/
schema: 2.0.0
---

# Get-EvergreenAppsVersion

## SYNOPSIS

Returns the latest release version of the Evergreen apps repository.

## SYNTAX

```
Get-EvergreenAppsVersion [<CommonParameters>]
```

## DESCRIPTION

Queries the GitHub Releases API for the latest release of the Evergreen apps repository and returns its version.

GitHub API rate limits apply. Set the `GITHUB_TOKEN` or `GH_TOKEN` environment variable to use an authenticated request.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenAppsVersion
```

Description:
Returns the latest available release version of the Evergreen apps repository.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.String

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker

## RELATED LINKS

[Evergreen apps repository](https://github.com/EUCPilots/evergreen-apps)
