function Get-GitLabRepoRelease {
    <#
        .SYNOPSIS
            Calls the GitLab Releases API passed via $Uri, validates the response and returns a formatted object.
            Supported examples:
            - https://gitlab.com/api/v4/projects/:id/releases/latest
            - https://gitlab.com/api/v4/projects/:id/releases
            - https://gitlab.com/api/v4/projects/:id/repository/tags

            TODO: support Basic or OAuth authentication to GitLab
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
                if ($_ -match "^https://gitlab\.com/api/v4/projects/[^/]+/(releases(?:/latest)?|repository/tags)/?$") {
                    $true
                }
                else {
                    throw "'$_' must be in the format 'https://gitlab.com/api/v4/projects/:id/releases/latest', '.../releases', or '.../repository/tags'. Replace ':id' with the project ID."
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
        [System.Array] $VersionReplace,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $ReturnVersionOnly
    )

    process {
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
                Uri                = $Uri
            }

            if (Test-ProxyEnv) {
                $params.Proxy = $script:EvergreenProxy
            }

            if (Test-ProxyEnv -Creds) {
                $params.ProxyCredential = $script:EvergreenProxyCreds
            }

            # GitLab token support (PAT or bearer token)
            if (Test-Path -Path "env:GITLAB_TOKEN") {
                $params.Headers = @{ "PRIVATE-TOKEN" = $env:GITLAB_TOKEN }
            }

            foreach ($item in $params.GetEnumerator()) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Invoke-RestMethod parameter: $($item.Name): $($item.Value)."
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Get GitLab data from: $Uri."
            $apiResponse = Invoke-RestMethod @params
        }
        catch {
            throw $_
        }

        # Normalize to array for consistent handling
        $release = if ($apiResponse -is [System.Array]) { $apiResponse } else { @($apiResponse) }

        if ($null -eq $script:resourceStrings.Properties.GitLab) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Unable to validate release against GitLab releases property object because module resources were not found."
        }
        else {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Validating GitLab release object."
            foreach ($item in $release) {
                $compareParams = @{
                    ReferenceObject  = $script:resourceStrings.Properties.GitLab
                    DifferenceObject = (Get-Member -InputObject $item -MemberType NoteProperty).Name
                    PassThru         = $true
                    ErrorAction      = "Continue"
                }
                $missingProperties = Compare-Object @compareParams | Where-Object { $_.SideIndicator -eq "<=" }

                if ($null -eq $missingProperties) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Validated successfully."
                }
                else {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Validation failed."
                    foreach ($missingProperty in $missingProperties) {
                        throw [System.Management.Automation.ValidationMetadataException]::New("$($MyInvocation.MyCommand): Property '$missingProperty' missing")
                    }
                }
            }
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($release.Count) release/tag item(s)."

        if ($PSBoundParameters.ContainsKey("ReturnVersionOnly")) {
            $firstItem = $release | Select-Object -First 1

            try {
                if ($Uri -match "/repository/tags/?$") {
                    $sourceValue = $firstItem.name
                }
                else {
                    $sourceValue = $firstItem.$VersionTag
                }

                $Version = [System.Text.RegularExpressions.Regex]::Match($sourceValue, $MatchVersion).Groups[1].Value
                if ([System.String]::IsNullOrWhiteSpace($Version)) {
                    $Version = $sourceValue
                }
            }
            catch {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to match version number as-is, returning source value."
                $Version = $sourceValue
            }

            if ($PSBoundParameters.ContainsKey("VersionReplace")) {
                $Version = $Version -replace $VersionReplace[0], $VersionReplace[1]
            }

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

                try {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Matching version number against: $($item.$VersionTag)."
                    $Version = [System.Text.RegularExpressions.Regex]::Match($item.$VersionTag, $MatchVersion).Groups[1].Value
                    if ([System.String]::IsNullOrWhiteSpace($Version)) {
                        $Version = $item.$VersionTag
                    }
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Found version number: $Version."
                }
                catch {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to match version number, returning: $($item.$VersionTag)."
                    $Version = $item.$VersionTag
                }

                if ($PSBoundParameters.ContainsKey("VersionReplace")) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Replace $($VersionReplace[0])."
                    $Version = $Version -replace $VersionReplace[0], $VersionReplace[1]
                }

                $dateValue = if ($null -ne $item.released_at) { $item.released_at } else { $item.created_at }
                $leafName = Split-Path -Path $downloadUri -Leaf
                $typeValue = [System.IO.Path]::GetExtension($leafName).TrimStart(".")

                [PSCustomObject] @{
                    Version       = $Version
                    Date          = ConvertTo-DateTime -DateTime $dateValue -Pattern "MM/dd/yyyy HH:mm:ss"
                    Architecture  = Get-Architecture -String $leafName
                    InstallerType = Get-InstallerType -String $downloadUri
                    Type          = $typeValue
                    URI           = $downloadUri
                } | Write-Output
            }
        }
    }
}
