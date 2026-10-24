function Get-AzulZulu {
    <#
        .SYNOPSIS
            Retrieves Azul Zulu JDK/JRE release information.
        
        .DESCRIPTION
            Queries the Azul API to get the latest Azul Zulu OpenJDK releases.
        
        .PARAMETER res
            Resource object containing API configuration.
        
        .EXAMPLE
            Get-AzulZulu -res $ResourceObject
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    # Constants for property names
    $DISTRO_VERSION = 'distro_version'
    $DOWNLOAD_URL = 'download_url'

    # Pass the releases API URL and return a formatted object
    $params = @{
        Uri         = $res.Get.Update.Uri
        ContentType = $res.Get.Update.ContentType
    }
    $Releases = @(Invoke-EvergreenRestMethod @params)
    $Releases = @($Releases | Where-Object { $null -ne $_ })

    # Check if releases were found
    if ($Releases.Count -eq 0) {
        Write-Warning -Message "$($MyInvocation.MyCommand): No releases found."
        return
    }
    Write-Verbose -Message "$($MyInvocation.MyCommand): found $($Releases.Count) releases."

    # Parse versions before sorting so malformed API values cannot break the whole result.
    $VersionedReleases = foreach ($Release in $Releases) {
        $ReleaseVersion = $Release.$DISTRO_VERSION -join "."
        $ParsedVersion = $null
        if ([System.String]::IsNullOrWhiteSpace([System.String]$ReleaseVersion) -or
            -not [System.Version]::TryParse([System.String]$ReleaseVersion, [ref]$ParsedVersion)) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Skipping release with invalid '$DISTRO_VERSION' value [$ReleaseVersion]."
            continue
        }

        [PSCustomObject]@{
            Release       = $Release
            Version       = $ReleaseVersion
            ParsedVersion = $ParsedVersion
        }
    }

    if ($null -eq $VersionedReleases -or @($VersionedReleases).Count -eq 0) {
        Write-Warning -Message "$($MyInvocation.MyCommand): No releases with a valid '$DISTRO_VERSION' value were found."
        return
    }

    $LatestRelease = $VersionedReleases |
        Sort-Object -Property ParsedVersion -Descending |
        Select-Object -First 1
    $LatestVersion = $LatestRelease.Version
    Write-Verbose -Message "$($MyInvocation.MyCommand): found latest version: $LatestVersion"

    # Filter the releases for the latest version and exclude any gzipped files
    Write-Verbose -Message "$($MyInvocation.MyCommand): Filter for latest releases."
    foreach ($VersionedRelease in $VersionedReleases) {
        if ($VersionedRelease.Version -ne $LatestVersion) {
            continue
        }

        $Release = $VersionedRelease.Release
        $DownloadUrl = [System.String]$Release.$DOWNLOAD_URL
        if ([System.String]::IsNullOrWhiteSpace($DownloadUrl)) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Skipping latest release with an empty '$DOWNLOAD_URL'."
            continue
        }

        $ParsedDownloadUri = $null
        if (-not [System.Uri]::TryCreate($DownloadUrl, [System.UriKind]::Absolute, [ref]$ParsedDownloadUri) -or
            $ParsedDownloadUri.Scheme -notin @("http", "https")) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Skipping latest release with an invalid HTTP or HTTPS '$DOWNLOAD_URL' [$DownloadUrl]."
            continue
        }

        if ($ParsedDownloadUri.AbsolutePath -match '(?i)\.gz$') {
            continue
        }

        # Match the download URL to determine the image type
        $ImageType = if ($DownloadUrl -match "(fx-jre)(?=\d)") {
            "JREFX"
        } elseif ($DownloadUrl -match "(fx-jdk)(?=\d)") {
            "JDKFX"
        } elseif ($DownloadUrl -match "(jre)(?=\d)") {
            "JRE"
        } elseif ($DownloadUrl -match "(jdk)(?=\d)") {
            "JDK"
        } else {
            "Unknown"
        }

        $Architecture = Get-Architecture -String $DownloadUrl
        if ($Architecture -eq "x86" -and $DownloadUrl -notmatch '(?i)(?<![a-z0-9])(?:nt32|32-bit|32bit|x32|w32|x86|win32)(?![a-z0-9])|(?<![a-z0-9])-32(?=(?:\.[a-z]{1,5})*(?:$|[/;?#]))') {
            Write-Warning -Message "$($MyInvocation.MyCommand): Could not determine architecture from latest release URI [$DownloadUrl]."
            $Architecture = "Unknown"
        }

        # Output a custom object with release info
        $PSObject = [PSCustomObject]@{
            Version      = $VersionedRelease.Version
            JavaVersion  = "$($Release.java_version -join ".")$(if ($null -ne $Release.openjdk_build_number) { "+$($Release.openjdk_build_number)" })"
            ImageType    = $ImageType
            Architecture = $Architecture
            Type         = Get-FileType -File $DownloadUrl
            URI          = $DownloadUrl
        }
        Write-Output -InputObject $PSObject
    }
}
