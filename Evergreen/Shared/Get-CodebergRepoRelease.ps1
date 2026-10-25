function Get-CodebergRepoRelease {
    <#
        .SYNOPSIS
            Calls the Codeberg Releases API passed via $Uri, validates the response and returns a formatted object
            Docs: https://codeberg.org/api/swagger
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( {
                if ($_ -cmatch "^https://codeberg\.org/api/v1/repos/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/(tags|releases(?:/(?:latest|[0-9]+|tags/[^/?#]+))?)/?(?:\?[^#]*)?$") {
                    $true
                }
                else {
                    throw "'$_' must be in the format 'https://codeberg.org/api/v1/repos/user/repository/releases'. Replace 'user' with the user or organisation and 'repository' with the target repository name."
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
        try {
            # Retrieve the releases from the Codeberg API
            # Use TLS for connections
            Write-Verbose -Message "$($MyInvocation.MyCommand): Set TLS to 1.2."
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

            # Invoke the Codeberg releases REST API
            # Note that the API performs rate limiting.
            # https://codeberg.org/api/swagger
            $params = @{
                ContentType        = "application/json"
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

            Write-Verbose -Message "$($MyInvocation.MyCommand): Get Codeberg release from: $Uri."
            $release = Invoke-RestMethod @params
        }
        catch {
            throw
        }

        $IsTagsEndpoint = ([System.Uri]$Uri).AbsolutePath -match "/repos/[^/]+/[^/]+/tags/?$"
        $SourceProperty = if ($IsTagsEndpoint) { "name" } else { $VersionTag }
        $RequiredProperties = if ($IsTagsEndpoint) { @("name") } else { @($script:resourceStrings.Properties.Codeberg) }
        if (-not $IsTagsEndpoint -and $null -eq $script:resourceStrings.Properties.Codeberg) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Codeberg schema not found; validating only the properties required for this operation."
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
                            $PSObject = [PSCustomObject] @{
                                Version       = $Version
                                Date          = ConvertTo-DateTime -DateTime $item.created_at -Pattern "MM/dd/yyyy HH:mm:ss"
                                Size          = $asset.size
                                Architecture  = Get-Architecture -String $(Split-Path -Path $asset.browser_download_url -Leaf)
                                InstallerType = Get-InstallerType -String $(Split-Path -Path $asset.browser_download_url -Leaf)
                                Type          = Get-FileType -File $(Split-Path -Path $asset.browser_download_url -Leaf)
                                URI           = $asset.browser_download_url
                            }
                            Write-Output -InputObject $PSObject
                        }
                    }
                    else {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Skip: $($asset.browser_download_url)."
                    }
                }
            }
        }
    }
}
