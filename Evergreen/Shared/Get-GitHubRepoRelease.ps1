function Get-GitHubRepoRelease {
    <#
        .SYNOPSIS
            Calls the GitHub Releases API passed via $Uri, validates the response and returns a formatted object
            Example: https://api.github.com/repos/PowerShell/PowerShell/releases/latest
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( {
                if ($_ -cmatch "^https://api\.github\.com/repos/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/(tags|releases(?:/(?:latest|[0-9]+|tags/[^/?#]+))?)/?(?:\?[^#]*)?$") {
                    $true
                }
                else {
                    throw "'$_' must be in the format 'https://api.github.com/repos/user/repository/releases/latest'. Replace 'user' with the user or organisation and 'repository' with the target repository name."
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

    begin {
        $RateLimit = Get-GitHubRateLimit
    }

    process {
        if ($RateLimit.remaining -eq 0) {
            # We're rate limited, so output a special object
            [PSCustomObject] @{
                Version = "RateLimited"
                URI     = "https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting"
            } | Write-Output
        }
        else {
            try {
                # Retrieve the releases from the GitHub API
                # Use TLS for connections
                Write-Verbose -Message "$($MyInvocation.MyCommand): Set TLS to 1.2."
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

                # Invoke the GitHub releases REST API
                # Note that the API performs rate limiting.
                # https://docs.github.com/en/free-pro-team@latest/rest/reference/repos#get-the-latest-release
                $params = @{
                    ContentType        = "application/vnd.github.v3+json"
                    ErrorAction        = "Stop"
                    MaximumRedirection = 0
                    DisableKeepAlive   = $true
                    UseBasicParsing    = $true
                    UserAgent          = (Get-EvergreenUserAgent)
                    Uri                = $Uri
                }
                if (Test-ProxyEnv) {
                    $params.Proxy = $script:EvergreenProxy
                }
                if (Test-ProxyEnv -Creds) {
                    $params.ProxyCredential = $script:EvergreenProxyCreds
                }
                # If GITHUB_TOKEN or GH_TOKEN exists, let's add that to the API request
                if (-not [System.String]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
                    $params.Headers = @{ Authorization = "token $env:GITHUB_TOKEN" }
                }
                elseif (-not [System.String]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
                    $params.Headers = @{ Authorization = "token $env:GH_TOKEN" }
                }

                Write-Verbose -Message "$($MyInvocation.MyCommand): Get GitHub release from: $Uri."
                $release = Invoke-RestMethod @params
            }
            catch {
                throw
            }

            $IsTagsEndpoint = ([System.Uri]$Uri).AbsolutePath -match "/repos/[^/]+/[^/]+/tags/?$"
            $SourceProperty = if ($IsTagsEndpoint) { "name" } else { $VersionTag }
            $SchemaName = if ($IsTagsEndpoint) { "GitHubTags" } else { "GitHub" }
            $RequiredProperties = @($script:resourceStrings.Properties.$SchemaName)
            if ($null -eq $script:resourceStrings.Properties.$SchemaName) {
                Write-Warning -Message "$($MyInvocation.MyCommand): $SchemaName schema not found; validating only the properties required for this operation."
            }
            $RequiredProperties = @($RequiredProperties | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) + @($SourceProperty)
            if (-not $ReturnVersionOnly) {
                $RequiredProperties += "assets"
            }
            $release = Get-RepoResponse -Response $release -RequiredProperties $RequiredProperties
            $VersionParams = @{ MatchVersion = $MatchVersion }
            if ($PSBoundParameters.ContainsKey("VersionReplace")) {
                $VersionParams.VersionReplace = $VersionReplace
            }

            # Build and array of the latest release and download URLs
            Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($release.count) release/s."
            Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($release.assets.count) asset/s."
            if (-not $ReturnVersionOnly -and $release.assets.count -eq 0) {
                Write-Warning -Message "$($MyInvocation.MyCommand): No assets found for this release."
            }

            if ($ReturnVersionOnly) {
                $Version = Get-RepoReleaseVersion -Source $release[0].$SourceProperty @VersionParams

                # Build the output object
                $PSObject = [PSCustomObject] @{
                    Version = $Version
                }
                Write-Output -InputObject $PSObject
            }
            else {
                foreach ($item in $release) {
                    foreach ($asset in $item.assets) {

                        # Filter downloads by matching the RegEx in the manifest. The the RegEx may perform includes and excludes
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Match $Filter to $($asset.browser_download_url)."
                        if ($asset.browser_download_url -match $Filter) {
                            Write-Verbose -Message "$($MyInvocation.MyCommand): Building Windows release output object with: $($asset.browser_download_url)."

                            $Version = Get-RepoReleaseVersion -Source $item.$SourceProperty @VersionParams

                            # Build the output object
                            if ((Get-Platform -String $asset.browser_download_url) -eq "Windows") {

                                $Object = [PSCustomObject] @{
                                    Version       = $Version
                                    Date          = ConvertTo-DateTime -DateTime $item.created_at -AutoDetect
                                    Size          = $asset.size
                                    Sha256        = if ($null -eq $asset.digest) { $null } else { ($asset.digest -split ":")[-1] }
                                    Architecture  = Get-Architecture -String $(Split-Path -Path $asset.browser_download_url -Leaf)
                                    InstallerType = Get-InstallerType -String $(Split-Path -Path $asset.browser_download_url -Leaf)
                                    Type          = Get-FileType -File $(Split-Path -Path $asset.browser_download_url -Leaf)
                                    URI           = $asset.browser_download_url
                                }

                                # If the asset doesn't have a digest property, remove the Sha256 property from the output object
                                if ($null -eq $asset.digest) {
                                    $Object.PSObject.Properties.Remove('Sha256')
                                }

                                Write-Output -InputObject $Object
                            }
                        }
                        else {
                            Write-Verbose -Message "$($MyInvocation.MyCommand): Skip as asset is not for Windows: $($asset.browser_download_url)."
                        }
                    }
                }
            }
        }
    }
}
