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
                if ($_ -match "^(https://codeberg.org/api/v1/repos/)([a-zA-Z0-9_-]+)/([a-zA-Z0-9_-]+)(/tags|/releases)") {
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
        [System.Array] $VersionReplace,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $ReturnVersionOnly
    )

    begin {
    }

    process {
        try {
            # Retrieve the releases from the Codeberg API
            # Use TLS for connections
            Write-Verbose -Message "$($MyInvocation.MyCommand): Set TLS to 1.2."
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

            # Invoke the Codeberg releases REST API
            # Note that the API performs rate limiting.
            # https://docs.Codeberg.com/en/free-pro-team@latest/rest/reference/repos#get-the-latest-release
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
            # # If Codeberg_TOKEN or GH_TOKEN exists, let's add that to the API request
            # if (Test-Path -Path "env:Codeberg_TOKEN") {
            #     $params.Headers = @{ Authorization = "token $env:Codeberg_TOKEN" }
            # }
            # elseif (Test-Path -Path "env:GH_TOKEN") {
            #     $params.Headers = @{ Authorization = "token $env:GH_TOKEN" }
            # }

            # Output the parameters when using -Verbose
            foreach ($item in $params.GetEnumerator()) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Invoke-WebRequest parameter: $($item.name): $($item.value)."
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Get Codeberg release from: $Uri."
            $release = Invoke-RestMethod @params
        }
        catch {
            throw $_
        }

        if ($null -eq $script:resourceStrings.Properties.Codeberg) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Unable to validate release against Codeberg releases property object because we can't find the module resource."
        }
        else {
            # Validate that $release has the expected properties
            Write-Verbose -Message "$($MyInvocation.MyCommand): Validating Codeberg release object."
            foreach ($item in $release) {

                # Compare the Codeberg release object with properties that we expect
                $params = @{
                    ReferenceObject  = $script:resourceStrings.Properties.Codeberg
                    DifferenceObject = (Get-Member -InputObject $item -MemberType NoteProperty)
                    PassThru         = $true
                    ErrorAction      = "Continue"
                }
                $missingProperties = Compare-Object @params

                # Throw an error for missing properties
                if ($null -ne $missingProperties) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Validated successfully."
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
        Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($release.count) release/s."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($release.assets.count) asset/s."

        if ($PSBoundParameters.ContainsKey("ReturnVersionOnly")) {
            if ($Uri -match "^*tags$") {
                try {
                    # Uri matches tags fo the repo; find the latest tag
                    $Version = [RegEx]::Match($release[0].name, $MatchVersion).Captures.Groups[1].Value
                }
                catch {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to match version number as-is, returning: $($release[0].$VersionTag)."
                    $Version = $release[0].name
                }
            }
            else {
                try {
                    # Uri matches releases for the repo; return just the version string
                    $Version = [RegEx]::Match($release[0].$VersionTag, $MatchVersion).Captures.Groups[1].Value
                }
                catch {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to match version number as-is, returning: $($release[0].$VersionTag)."
                    $Version = $item.$VersionTag
                }
            }

            if ($PSBoundParameters.ContainsKey("VersionReplace")) {
                # Replace string in version
                $Version = $Version -replace $res.Get.VersionReplace[0], $res.Get.VersionReplace[1]
            }

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

                        # Capture the version string from the specified release tag
                        try {
                            Write-Verbose -Message "$($MyInvocation.MyCommand): Matching version number against: $($item.$VersionTag)."
                            $Version = [RegEx]::Match($item.$VersionTag, $MatchVersion).Captures.Groups[1].Value
                            Write-Verbose -Message "$($MyInvocation.MyCommand): Found version number: $Version."
                        }
                        catch {
                            Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to match version number, returning: $($item.$VersionTag)."
                            $Version = $item.$VersionTag
                        }

                        if ($PSBoundParameters.ContainsKey("VersionReplace")) {
                            # Replace string in version
                            Write-Verbose -Message "$($MyInvocation.MyCommand): Replace $($res.Get.VersionReplace[0])."
                            $Version = $Version -replace $res.Get.VersionReplace[0], $res.Get.VersionReplace[1]
                        }

                        # Build the output object
                        if ((Get-Platform -String $asset.browser_download_url) -eq "Windows") {
                            $PSObject = [PSCustomObject] @{
                                Version       = $Version
                                Date          = ConvertTo-DateTime -DateTime $item.created_at -Pattern "MM/dd/yyyy HH:mm:ss"
                                Size          = $asset.size
                                Architecture  = Get-Architecture -String $(Split-Path -Path $asset.browser_download_url -Leaf)
                                InstallerType = Get-InstallerType -String $asset.browser_download_url
                                Type          = [System.IO.Path]::GetExtension($asset.browser_download_url).Split(".")[-1]
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
