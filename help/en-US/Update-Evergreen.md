---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen-docs/help/en-US/Update-Evergreen/
schema: 2.0.0
---

# Update-Evergreen

## SYNOPSIS

Downloads and synchronizes the Evergreen Apps functions and Manifests from the eucpilots/evergreen-apps GitHub repository.

## SYNTAX

```
Update-Evergreen [-Force] [-Release <String>] [<CommonParameters>]
```

## DESCRIPTION

Enables separation of the core Evergreen module from app-specific code and manifests. Downloads the latest versions of /Apps and /Manifests from a specified GitHub repository to a user-writable location (no admin required). By default, the local cache is downloaded to %LocalAppData%\Evergreen on Windows, and ~/.evergreen on macOS and Linux.

## EXAMPLES

### EXAMPLE 1

```powershell
Update-Evergreen
```

Description:
Downloads and synchronizes the Evergreen Apps functions and Manifests from the eucpilots/evergreen-apps GitHub repository. If updates are required, an update of the local cache is performed. If no update is required, no update is performed.

### EXAMPLE 2

```powershell
Update-Evergreen -Force
```

Description:
Forces a full download and synchronization of the Evergreen Apps functions and Manifests from the eucpilots/evergreen-apps GitHub repository, regardless of the state of the local cache.

### EXAMPLE 2

```powershell
Update-Evergreen -Release "v25.09.27.16" -Force
```

Description:
Downloads and synchronizes the v25.09.27.16 release of the Evergreen Apps functions and Manifests from the eucpilots/evergreen-apps GitHub repository.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Site: https://eucpilots.com/evergreen-docs

Author: Aaron Parker

## RELATED LINKS
