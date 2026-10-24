function Get-EvergreenAppsVersion {
    <#
        .EXTERNALHELP Evergreen-help.xml     
    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    param()

    try {
        # Get the latest version from the remote repository
        Write-Verbose -Message "Checking for latest Evergreen apps release from: $($script:resourceStrings.Repositories.Apps.Repo)"
        $Url = "https://api.github.com/repos/$($script:resourceStrings.Repositories.Apps.Repo)/releases/latest"

        Write-Verbose -Message "Release URL: $Url"
        $EvergreenAppsRelease = Get-GitHubRepoRelease -Uri $Url
        Write-Verbose -Message "Found Evergreen apps release: $($EvergreenAppsRelease.Version)"
    }
    catch {
        throw $_
    }
    return $EvergreenAppsRelease.Version
}
