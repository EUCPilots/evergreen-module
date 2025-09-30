function Get-SourceForgeRepoRelease {
    <#
        .SYNOPSIS
            Validates a JSON string returned from a SourceForge releases API and returns a formatted object
            Example: https://sourceforge.net/projects/sevenzip/best_release.json
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable] $Download,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.String] $MatchVersion
    )

    # Retrieve best release json
    $params = @{
        Uri       = $Uri
        UserAgent = (Get-EvergreenUserAgent)
    }
    $BestRelease = Invoke-EvergreenRestMethod @params

    # Validate that $BestRelease has the expected properties
    Write-Verbose -Message "$($MyInvocation.MyCommand): Validating SourceForge release object."
    $params = @{
        ReferenceObject  = $script:resourceStrings.Properties.SourceForge
        DifferenceObject = (Get-Member -InputObject $BestRelease -MemberType NoteProperty)
        PassThru         = $true
        ErrorAction      = "SilentlyContinue"
    }
    $missingProperties = Compare-Object @params
    if ($null -ne $missingProperties) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Property validation succeeded."
    }
    else {
        Write-Warning -Message "$($MyInvocation.MyCommand): Property validation failed."
        $missingProperties | ForEach-Object {
            throw [System.Management.Automation.ValidationMetadataException]::New("$($MyInvocation.MyCommand): Property: '$_' missing")
        }
    }

    # Find version number and the releases folder
    try {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Capture version number from: $($BestRelease.platform_releases.windows.filename)."
        $Filename = Split-Path -Path $BestRelease.platform_releases.windows.filename -Leaf
        $Folder = ($BestRelease.platform_releases.windows.filename -split $Filename)[0]
        $Version = [RegEx]::Match($Folder, $MatchVersion).Captures.Groups[1].Value
        Write-Verbose -Message "$($MyInvocation.MyCommand): Found filename: [$Filename]."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Found folder:   [$Folder]."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Found version:  [$Version]."
    }
    catch {
        throw "$($MyInvocation.MyCommand): Failed to find filename, folder, version number from: $($BestRelease.platform_releases.windows.filename)."
    }

    # Find the mirror for the download
    $params = @{
        Uri       = $BestRelease.platform_releases.windows.url
        UserAgent = (Get-EvergreenUserAgent)
    }
    $Resolved = Resolve-SystemNetWebRequest @params
    Write-Verbose -Message "$($MyInvocation.MyCommand): Resolve mirror to: $($Resolved.ResponseUri.Host)."

    # Get the downloads XML feed and select the latest item via the $Version value
    $params = @{
        Uri         = "$($Download.Feed)$Folder"
        ContentType = $Download.ContentType
        UserAgent   = (Get-EvergreenUserAgent)
    }
    $Content = Invoke-EvergreenRestMethod @params

    # Filter items for file types that we've included in the manifest
    $FileItems = $Content | Where-Object { ($_.link -replace $Download.ReplaceText.Link, "") -match $Download.MatchFileTypes }
    Write-Verbose -Message "$($MyInvocation.MyCommand): found $($fileItems.Count) items."

    # For each filtered file, build a release object
    foreach ($item in $FileItems) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): matched: $($item.link)."
        Write-Verbose -Message "$($MyInvocation.MyCommand): file: $($item.description.'#cdata-section')"

        #region Build the URL to the file using the mirror captured above
        # Remove the file name from the path segments; # Build the URL path using the mirror and the file name for that specific item
        $Segments = $Resolved.ResponseUri.Segments | Where-Object { $_ -ne $Resolved.ResponseUri.Segments[-1] }
        $Url = @(
            "https://",
            $Resolved.ResponseUri.Host,
            ($Segments -join ""),
            $(Split-Path -Path $item.description.'#cdata-section' -Leaf) -replace " ", "%20"
        ) -join ""
        #endregion

        # Create the output object
        $PSObject = [PSCustomObject] @{
            Version      = $Version
            Architecture = Get-Architecture -String $Url
            Type         = [System.IO.Path]::GetExtension($Url).Split(".")[-1]
            Size         = $item.content.filesize
            Md5          = $item.content.hash.'#text'
            FileName     = Split-Path -Path $Url -Leaf
            URI          = "$($Url)?viasf=1"
        }
        Write-Output -InputObject $PSObject
    }
}
