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
                if ($_ -match "^(https://api\.github\.com/repos/)([a-zA-Z0-9_.-]+)/([a-zA-Z0-9_.-]+)(/tags|/releases)") {
                    $true
                }
                else {
                    throw "'$_' must be in the format 'https://api.github.com/repos/user/tags'. Replace 'user' with the user or organisation and 'repository' with the target repository name."
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
                if (Test-Path -Path "env:GITHUB_TOKEN") {
                    $params.Headers = @{ Authorization = "token $env:GITHUB_TOKEN" }
                }
                elseif (Test-Path -Path "env:GH_TOKEN") {
                    $params.Headers = @{ Authorization = "token $env:GH_TOKEN" }
                }

                # Output the parameters when using -Verbose
                foreach ($tag in $params.GetEnumerator()) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Invoke-WebRequest parameter: $($tag.name): $($tag.value)."
                }

                Write-Verbose -Message "$($MyInvocation.MyCommand): Get GitHub release from: $Uri."
                $Tags = Invoke-RestMethod @params
            }
            catch {
                throw $_
            }

            if ($null -eq $script:resourceStrings.Properties.GitHubTags) {
                Write-Warning -Message "$($MyInvocation.MyCommand): Unable to validate tag against GitHub tags property object because we can't find the module resource."
            }
            else {
                # Validate that $tags has the expected properties
                Write-Verbose -Message "$($MyInvocation.MyCommand): Validating GitHub tag object."
                foreach ($tag in $Tags) {

                    # Compare the GitHub release object with properties that we expect
                    $params = @{
                        ReferenceObject  = $script:resourceStrings.Properties.GitHubTags
                        DifferenceObject = (Get-Member -InputObject $tag -MemberType NoteProperty)
                        PassThru         = $true
                        ErrorAction      = "Continue"
                    }
                    $missingProperties = Compare-Object @params

                    # throw an error for missing properties
                    if ($null -ne $missingProperties) {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Validated tag object successfully."
                    }
                    else {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Validation failed."
                        $missingProperties | ForEach-Object {
                            throw [System.Management.Automation.ValidationMetadataException]::New("$($MyInvocation.MyCommand): Property: '$_' missing")
                        }
                    }
                }
            }

            # Build and array of the latest release and download URLs
            Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($tags.count) tags."
            foreach ($Tag in $Tags) {

                try {
                    # Uri matches tags for the repo; find the latest tag
                    $Version = [RegEx]::Match($Tag.name, $MatchVersion).Captures.Groups[1].Value
                }
                catch {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to match version number, returning as-is: $($Tag.name)."
                    $Version = $Tag.name
                }

                # Output the tags object
                [PSCustomObject]@{
                    Tag = $Version
                } | Write-Output
            }
        }
    }
}
