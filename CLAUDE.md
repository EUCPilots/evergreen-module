# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This repository contains the **Evergreen PowerShell module** — the module framework itself. Application-specific functions (e.g., `Get-MicrosoftEdge.ps1`) and their JSON manifests live in the companion repository [eucpilots/evergreen-apps](https://github.com/EUCPilots/evergreen-apps) and are downloaded locally via `Update-Evergreen`.

## Common Commands

### Linting

Run PSScriptAnalyzer against the module (requires PowerShell):

```powershell
Invoke-ScriptAnalyzer -Path "./Evergreen" -Recurse -Settings "./.rules/PSScriptAnalyzerSettings.psd1"
```

### Running Tests

Tests use [Pester](https://pester.dev/). First, install Pester and load the module, then run:

```powershell
# Install Pester
.\tests\Install-Pester.ps1

# Import module and sync apps cache
Import-Module -Name ".\Evergreen" -Force
Update-Evergreen -Force

# Run all tests
$Config = [PesterConfiguration]::Default
$Config.Run.Path = ".\tests"
$Config.Output.Verbosity = "Detailed"
Invoke-Pester -Configuration $Config
```

Run a single test file:

```powershell
Invoke-Pester -Path ".\tests\Public\Get-EvergreenApp.Tests.ps1"
```

### Loading the Module Locally

```powershell
Import-Module -Name ".\Evergreen" -Force
Update-Evergreen  # downloads latest app functions and manifests from eucpilots/evergreen-apps
```

## Architecture

### Module Layout

```
Evergreen/
├── Evergreen.psd1          # Module manifest (version, exported functions/aliases)
├── Evergreen.psm1          # Module initializer: dot-sources all ps1 files, loads resources
├── Evergreen.json          # Module-wide config: API URIs, user agents, property schemas
├── Public/                 # Exported functions (one function per file, filename == function name)
├── Private/                # Internal helpers (not exported)
└── Shared/                 # Functions shared with eucpilots/evergreen-apps repo
```

### Separation of Module vs. Apps

The module itself contains no application-specific logic. When `Get-EvergreenApp -Name "TeamViewer"` is called:

1. It builds the path `<AppsPath>/Apps/Get-TeamViewer.ps1`
2. Dot-sources that file at runtime (not at module load)
3. Reads the app's JSON manifest from `<AppsPath>/Manifests/TeamViewer.json` via `Get-FunctionResource`
4. Calls the app function, optionally applying output filters from `<AppsPath>/Filters/`

The apps cache path defaults to `%LOCALAPPDATA%\Evergreen` (Windows) or `~/.evergreen` (macOS/Linux) and can be overridden with the `EVERGREEN_APPS_PATH` environment variable.

### Key Private Helpers

- `Get-ModuleResource` — reads `Evergreen.json` into `$script:resourceStrings` at module load
- `Get-FunctionResource` — reads a per-app JSON manifest from the apps cache
- `Invoke-EvergreenRestMethod` / `Invoke-EvergreenWebRequest` — wrapper HTTP helpers with proxy/cert support
- `Write-Message` — consistent console output (replaces `Write-Host`)
- `Get-FilteredData` — applies a JSON filter file to standardize/restrict app output

### Shared Functions

`Evergreen/Shared/` contains functions that are also used by the `eucpilots/evergreen-apps` repo (e.g., `Get-GitHubRepoRelease`, `Get-OmnissaProductDownload`). These are shared utilities for querying vendor APIs.

### Versioning

Module version follows `YYmm.Build` (e.g., `2511.2826.0`). The `update-module.yml` workflow bumps this automatically and publishes to the PowerShell Gallery.

## Code Conventions

- **One function per file**, filename must exactly match the function name (enforced by `Main.Tests.ps1`).
- Supports Windows PowerShell 5.1 and PowerShell 7.0+. Avoid PS6-only APIs.
- PSScriptAnalyzer is run at `Error` and `Warning` severity. `PSAvoidUsingWriteHost` is excluded (use `Write-Message` instead).
- GitHub API calls check for `GITHUB_TOKEN` or `GH_TOKEN` environment variables to avoid rate limits.
- App functions are dot-sourced lazily (at invocation time, not module import) to reduce memory footprint.

## CI Workflows

- **validate-module.yml** — runs PSScriptAnalyzer and Pester on PRs/pushes to non-main branches
- **update-module.yml** — manually triggered; bumps version, updates CHANGELOG and apps.md, commits and tags
- **publish-module.yml** — triggers after `update-module.yml` completes; publishes to PowerShell Gallery
