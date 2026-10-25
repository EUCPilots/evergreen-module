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
    if ($null -eq $BestRelease) {
        throw "$($MyInvocation.MyCommand): SourceForge returned an empty release response."
    }

    $RequiredProperties = @($script:resourceStrings.Properties.SourceForge)
    $MissingProperties = @($RequiredProperties | Where-Object { $_ -notin $BestRelease.PSObject.Properties.Name })
    if ($MissingProperties.Count -gt 0) {
        throw "$($MyInvocation.MyCommand): SourceForge release response is missing required properties: $($MissingProperties -join ', ')."
    }
    if ($null -eq $BestRelease.platform_releases.windows) {
        throw "$($MyInvocation.MyCommand): SourceForge release response is missing platform_releases.windows."
    }
    foreach ($Property in @("filename", "url")) {
        if ([System.String]::IsNullOrWhiteSpace([System.String]$BestRelease.platform_releases.windows.$Property)) {
            throw "$($MyInvocation.MyCommand): SourceForge release response is missing platform_releases.windows.$Property."
        }
    }

    # SourceForge's filename is a path whose final segment is usually "download".
    $ReleasePath = ([System.String]$BestRelease.platform_releases.windows.filename).Split("?")[0]
    $LastSeparator = $ReleasePath.LastIndexOf("/")
    if ($LastSeparator -lt 0 -or $LastSeparator -eq ($ReleasePath.Length - 1)) {
        throw "$($MyInvocation.MyCommand): Invalid SourceForge release filename path: $($BestRelease.platform_releases.windows.filename)."
    }
    $Folder = $ReleasePath.Substring(0, $LastSeparator + 1)
    Write-Verbose -Message "$($MyInvocation.MyCommand): Capture version number from: $Folder."
    $VersionMatch = [RegEx]::Match($Folder, $MatchVersion)
    if (-not $VersionMatch.Success -or -not $VersionMatch.Groups[1].Success -or [System.String]::IsNullOrWhiteSpace($VersionMatch.Groups[1].Value)) {
        throw "$($MyInvocation.MyCommand): Failed to find a version in SourceForge release path: $Folder."
    }
    $Version = $VersionMatch.Groups[1].Value
    Write-Verbose -Message "$($MyInvocation.MyCommand): Found folder: [$Folder]."
    Write-Verbose -Message "$($MyInvocation.MyCommand): Found version: [$Version]."

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
    $FileItems = @($Content | Where-Object {
        $null -ne $_ -and
        -not [System.String]::IsNullOrWhiteSpace([System.String]$_.link) -and
        ($_.link -replace [System.String]$Download.ReplaceText.Link, "") -match [System.String]$Download.MatchFileTypes
    })
    Write-Verbose -Message "$($MyInvocation.MyCommand): found $($FileItems.Count) items."
    if ($FileItems.Count -eq 0) {
        throw "$($MyInvocation.MyCommand): No SourceForge feed items matched the configured file types '$($Download.MatchFileTypes)'."
    }

    # For each filtered file, build a release object
    foreach ($item in $FileItems) {
        $FilePath = [System.String]$item.description.'#cdata-section'
        if ([System.String]::IsNullOrWhiteSpace($FilePath)) {
            throw "$($MyInvocation.MyCommand): SourceForge feed item '$($item.link)' is missing its file path."
        }
        if ($null -eq $item.content -or $null -eq $item.content.PSObject.Properties["filesize"] -or $null -eq $item.content.hash -or $null -eq $item.content.hash.PSObject.Properties["#text"]) {
            throw "$($MyInvocation.MyCommand): SourceForge feed item '$($item.link)' is missing file size or hash metadata."
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand): matched: $($item.link)."
        Write-Verbose -Message "$($MyInvocation.MyCommand): file: $FilePath"

        #region Build the URL to the file using the mirror captured above
        $Segments = $Resolved.ResponseUri.Segments
        $BasePath = if ($Segments.Count -gt 1) {
            $Segments[0..($Segments.Count - 2)] -join ""
        }
        else {
            "/"
        }
        $FileName = ($FilePath -split "[\\/]")[-1]
        $UriBuilder = [System.UriBuilder]::new($Resolved.ResponseUri)
        $UriBuilder.Path = "$BasePath$([System.Uri]::EscapeDataString($FileName))"
        $UriBuilder.Query = "viasf=1"
        $Url = $UriBuilder.Uri.AbsoluteUri
        #endregion

        # Create the output object
        $PSObject = [PSCustomObject] @{
            Version      = $Version
            Architecture = Get-Architecture -String $FileName
            Type         = [System.IO.Path]::GetExtension($FileName).TrimStart(".")
            Size         = $item.content.filesize
            Md5          = $item.content.hash.'#text'
            FileName     = $FileName
            URI          = $Url
        }
        Write-Output -InputObject $PSObject
    }
}
