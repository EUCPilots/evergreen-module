function Get-GitLabRepoRelease {
    <#
        .SYNOPSIS
            Calls the GitLab Releases API passed via $Uri, validates the response and returns a formatted object.
            Supported examples:
            - https://gitlab.com/api/v4/projects/:id/releases/permalink/latest
            - https://gitlab.com/api/v4/projects/:id/releases
            - https://gitlab.com/api/v4/projects/:id/repository/tags
            The legacy /releases/latest input is mapped to /releases/permalink/latest.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
                if ($_ -cmatch "^https://gitlab\.com/api/v4/projects/[^/?#]+/(releases(?:/(?:latest|permalink/latest|[^/?#]+))?|repository/tags)/?(?:\?[^#]*)?$") {
                    $true
                }
                else {
                    throw "'$_' must be in the format 'https://gitlab.com/api/v4/projects/:id/releases/permalink/latest', '.../releases', or '.../repository/tags'. Replace ':id' with the project ID or URL-encoded project path."
                }
            })]
        [System.String] $Uri,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.String] $MatchVersion = "(\d+(\.\d+){1,4}).*",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.String] $VersionTag = "tag_name",

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Filter = "\.exe$|\.msi$|\.msp$|\.zip$",

        [Parameter(Mandatory = $false, Position = 4)]
        [ValidateNotNull()]
        [ValidateCount(2, 2)]
        [System.Array] $VersionReplace,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $ReturnVersionOnly
    )

    process {
        $RequestUri = $Uri -creplace "/releases/latest(?=/?(?:\?|$))", "/releases/permalink/latest"
        try {
            # Retrieve releases/tags from GitLab API
            Write-Verbose -Message "$($MyInvocation.MyCommand): Set TLS to 1.2."
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

            $params = @{
                ContentType        = "application/json"
                ErrorAction        = "Stop"
                MaximumRedirection = 0
                DisableKeepAlive   = $true
                UseBasicParsing    = $true
                UserAgent          = (Get-EvergreenUserAgent)
                Uri                = $RequestUri
            }

            if (Test-ProxyEnv) {
                $params.Proxy = $script:EvergreenProxy
            }

            if (Test-ProxyEnv -Creds) {
                $params.ProxyCredential = $script:EvergreenProxyCreds
            }

            # GitLab personal access token support
            if (-not [System.String]::IsNullOrWhiteSpace($env:GITLAB_TOKEN)) {
                $params.Headers = @{ "PRIVATE-TOKEN" = $env:GITLAB_TOKEN }
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Get GitLab data from: $RequestUri."
            $apiResponse = Invoke-RestMethod @params
        }
        catch {
            throw
        }

        $IsTagsEndpoint = ([System.Uri]$Uri).AbsolutePath -match "/repository/tags/?$"
        $SourceProperty = if ($IsTagsEndpoint) { "name" } else { $VersionTag }
        $SchemaName = if ($IsTagsEndpoint) { "GitLabTags" } else { "GitLab" }
        $RequiredProperties = @($script:resourceStrings.Properties.$SchemaName)
        if ($null -eq $script:resourceStrings.Properties.$SchemaName) {
            Write-Warning -Message "$($MyInvocation.MyCommand): $SchemaName schema not found; validating only the properties required for this operation."
        }
        $RequiredProperties = @($RequiredProperties | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) + @($SourceProperty)
        if (-not $ReturnVersionOnly) {
            $RequiredProperties += "assets"
        }
        $release = Get-RepoResponse -Response $apiResponse -RequiredProperties $RequiredProperties
        $VersionParams = @{ MatchVersion = $MatchVersion }
        if ($PSBoundParameters.ContainsKey("VersionReplace")) {
            $VersionParams.VersionReplace = $VersionReplace
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($release.Count) release/tag item(s)."

        if ($ReturnVersionOnly) {
            $Version = Get-RepoReleaseVersion -Source $release[0].$SourceProperty @VersionParams

            [PSCustomObject] @{
                Version = $Version
            } | Write-Output

            return
        }

        foreach ($item in $release) {
            $assetLinks = @()

            if ($null -ne $item.assets -and $null -ne $item.assets.links) {
                $assetLinks += $item.assets.links
            }

            if ($null -ne $item.assets -and $null -ne $item.assets.sources) {
                $assetLinks += $item.assets.sources
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($assetLinks.Count) asset link(s)."

            if ($assetLinks.Count -eq 0) {
                Write-Warning -Message "$($MyInvocation.MyCommand): No assets found for this release."
                continue
            }

            foreach ($asset in $assetLinks) {
                $downloadUri = if ($null -ne $asset.direct_asset_url -and -not [System.String]::IsNullOrWhiteSpace($asset.direct_asset_url)) { $asset.direct_asset_url } else { $asset.url }

                if ([System.String]::IsNullOrWhiteSpace($downloadUri)) {
                    Write-Warning -Message "$($MyInvocation.MyCommand): Skipping an asset with no download URL."
                    continue
                }

                Write-Verbose -Message "$($MyInvocation.MyCommand): Match $Filter to $downloadUri."
                if ($downloadUri -notmatch $Filter) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Skip as asset does not match filter: $downloadUri."
                    continue
                }

                if ((Get-Platform -String $downloadUri) -ne "Windows") {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Skip as asset is not for Windows: $downloadUri."
                    continue
                }

                $Version = Get-RepoReleaseVersion -Source $item.$SourceProperty @VersionParams
                $dateValue = if ($null -ne $item.released_at) { $item.released_at } else { $item.created_at }
                $leafName = Split-Path -Path $downloadUri -Leaf

                [PSCustomObject] @{
                    Version       = $Version
                    Date          = ConvertTo-DateTime -DateTime $dateValue -Pattern "MM/dd/yyyy HH:mm:ss"
                    Architecture  = Get-Architecture -String $leafName
                    InstallerType = Get-InstallerType -String $leafName
                    Type          = Get-FileType -File $leafName
                    URI           = $downloadUri
                } | Write-Output
            }
        }
    }
}
