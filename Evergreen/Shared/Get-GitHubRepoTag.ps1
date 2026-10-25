function Get-GitHubRepoTag {
    <#
        .SYNOPSIS
            Calls the GitHub Tags API passed via $Uri and returns the tags for the repository
            Example: https://api.github.com/repos/PowerShell/PowerShell/tags
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( {
                if ($_ -cmatch "^https://api\.github\.com/repos/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/tags/?(?:\?[^#]*)?$") {
                    $true
                }
                else {
                    throw "'$_' must be in the format 'https://api.github.com/repos/user/repository/tags'. Replace 'user' with the user or organisation and 'repository' with the target repository name."
                }
            })]
        [System.String] $Uri,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.String] $MatchVersion = "(\d+(\.\d+){1,4}).*"
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
                $Tags = Invoke-RestMethod @params
            }
            catch {
                throw
            }

            if ($null -eq $script:resourceStrings.Properties.GitHubTags) {
                Write-Warning -Message "$($MyInvocation.MyCommand): GitHubTags schema not found; validating only the properties required for this operation."
            }
            $RequiredProperties = @($script:resourceStrings.Properties.GitHubTags | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) + @("name")
            $Tags = Get-RepoResponse -Response $Tags -RequiredProperties $RequiredProperties

            # Build and array of the latest release and download URLs
            Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($tags.count) tags."
            foreach ($Tag in $Tags) {

                $Version = Get-RepoReleaseVersion -Source $Tag.name -MatchVersion $MatchVersion

                # Output the tags object
                [PSCustomObject]@{
                    Tag = $Version
                } | Write-Output
            }
        }
    }
}
