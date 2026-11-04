---
external help file: Evergreen-help.xml
Module Name: Evergreen
online version: https://eucpilots.com/evergreen/help/en-US/Get-EvergreenAppsPath/
schema: 2.0.0
---

# Get-EvergreenAppsPath

## SYNOPSIS

Returns the local cache path for the Evergreen apps functions and manifests, honoring the `EVERGREEN_APPS_PATH` environment variable when set.

## SYNTAX

```
Get-EvergreenAppsPath
```

## DESCRIPTION

Returns the path specified by `EVERGREEN_APPS_PATH` when it is set. Otherwise, returns `%LOCALAPPDATA%\Evergreen` on Windows or `~/.evergreen` on macOS and Linux. If the environment variable points to a path that does not exist, the function warns and returns its value.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-EvergreenAppsPath
```

Description:
Returns the configured Evergreen apps cache path.

## OUTPUTS

### System.String

## NOTES

Site: https://eucpilots.com/evergreen

Author: Aaron Parker
