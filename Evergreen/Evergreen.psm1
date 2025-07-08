<#
    .SYNOPSIS
        Evergreen script to initiate the module
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "Required for argument completion.")]
[CmdletBinding(SupportsShouldProcess = $false)]
param ()

# Get public and private function definition files
$PublicRoot = Join-Path -Path $PSScriptRoot -ChildPath "Public"
$PrivateRoot = Join-Path -Path $PSScriptRoot -ChildPath "Private"
$SharedRoot = Join-Path -Path $PSScriptRoot -ChildPath "Shared"
$Public = @( Get-ChildItem -Path (Join-Path -Path $PublicRoot -ChildPath "*.ps1") -ErrorAction "Stop" )
$Private = @( Get-ChildItem -Path (Join-Path -Path $PrivateRoot -ChildPath "*.ps1") -ErrorAction "Stop" )
$Shared = @( Get-ChildItem -Path (Join-Path -Path $SharedRoot -ChildPath "*.ps1") -ErrorAction "Stop" )

# Dot source the files
foreach ($Import in @($Public + $Private + $Shared)) {
    try {
        . $Import.FullName
    }
    catch {
        throw $_
    }
}

# Get module strings
$script:resourceStrings = Get-ModuleResource

# Register the argument completer for the Get-EvergreenApp and Find-EvergreenApp cmdlets
$Commands = "Get-EvergreenApp", "Find-EvergreenApp", "Get-EvergreenAppFromApi", "Export-EvergreenManifest", "Get-EvergreenLibraryApp", "Get-EvergreenEndpointFromApi"
Register-ArgumentCompleter -CommandName $Commands -ParameterName "Name" -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    (Get-ChildItem -Path "$PSScriptRoot\Manifests\$wordToComplete*.json" -ErrorAction "Ignore").BaseName
}

# Export the public modules and aliases
Export-ModuleMember -Function $public.Basename -Alias *

# Verifies whether the required 'Apps' and 'Manifests' directories exist in the specified path.
# If either directory is missing, it warns the user to download the Evergreen app functions.
# If both directories exist, it checks if the local version file exists and compares its version to the latest release version from GitHub.
# Appropriate warnings are displayed if the remote or local version cannot be retrieved, or if the local version is outdated.
$script:AppsPath = Get-EvergreenAppsPath
$script:VersionFile = Join-Path -Path $script:AppsPath -ChildPath ".evergreen_version"

if (-not (Test-Path (Join-Path -Path $script:AppsPath -ChildPath 'Apps')) -or -not (Test-Path (Join-Path -Path $script:AppsPath -ChildPath 'Manifests'))) {
    # Warn if Apps/Manifests have not been downloaded from GitHub
    Write-Message -Message "Evergreen app functions have not been downloaded. Please run 'Update-Evergreen'."
}
elseif (Test-Path -Path $script:VersionFile -PathType "Leaf") {
    # Check if the locally stored version matches the remote version
    try {
        $Url = "https://api.github.com/repos/$($script:resourceStrings.Repositories.Apps.Repo)/releases/latest"
        $RemoteVersion = (Get-GitHubRepoRelease -Uri $Url).Version
        Write-Message -Message "Remote Evergreen apps version: $RemoteVersion"
    }
    catch {
        $RemoteVersion = $null
    }

    try {
        $LocalVersion = (Get-Content -Path $script:VersionFile -ErrorAction "Stop").Trim()
        Write-Message -Message "Local Evergreen apps version: $LocalVersion"
    }
    catch {
        $LocalVersion = $null
    }

    if ($null -eq $RemoteVersion) {
        Write-Warning -Message "Could not retrieve remote version information. Please check your internet connection or the repository URL."
    }
    elseif ($null -eq $LocalVersion) {
        Write-Message -Message "Could not retrieve local version information. Please run 'Update-Evergreen -Force'."
    }
    elseif ([System.Version]$RemoteVersion -gt [System.Version]$LocalVersion) {
        Write-Message -Message "Evergreen app functions are out of date. Please run 'Update-Evergreen'."
    }
}
else {
    # If the version file does not exist, prompt to run Update-Evergreen
    Write-Message -Message "Cannot determine local Evergreen app functions version. Please run 'Update-Evergreen'."
}
