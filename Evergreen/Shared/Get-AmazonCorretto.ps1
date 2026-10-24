function Get-AmazonCorretto {
    <#
        .NOTES
            Author: Aaron Parker
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    if ($null -eq $res.Get -or $null -eq $res.Get.Download) {
        throw "Get-AmazonCorretto: The resource is missing the Get.Download configuration."
    }

    $DownloadConfig = $res.Get.Download
    if ([System.String]::IsNullOrWhiteSpace($DownloadConfig.MatchVersion)) {
        throw "Get-AmazonCorretto: The resource is missing Get.Download.MatchVersion."
    }

    try {
        $VersionRegex = [System.Text.RegularExpressions.Regex]::new($DownloadConfig.MatchVersion)
    }
    catch {
        throw "Get-AmazonCorretto: Get.Download.MatchVersion is not a valid regular expression: $($_.Exception.Message)"
    }
    if ($VersionRegex.GetGroupNumbers() -notcontains 1) {
        throw "Get-AmazonCorretto: Get.Download.MatchVersion must define a capture group for the version."
    }

    $DownloadUris = @($DownloadConfig.Uri)
    if ($DownloadUris.Count -eq 0 -or $DownloadUris -contains $null) {
        throw "Get-AmazonCorretto: The resource must contain one or more download URIs."
    }

    foreach ($Url in $DownloadUris) {
        if ([System.String]::IsNullOrWhiteSpace($Url)) {
            throw "Get-AmazonCorretto: A download URI cannot be empty."
        }

        # Resolve the URI from the download URL
        $Response = Resolve-SystemNetWebRequest -Uri $Url
        if ($null -eq $Response -or $null -eq $Response.ResponseUri) {
            throw "Get-AmazonCorretto: Could not resolve download URI [$Url]."
        }

        # Replace only the latest path segment when building the checksum URL.
        $ChecksumUriBuilder = [System.UriBuilder]::new($Url)
        $PathSegments = $ChecksumUriBuilder.Path.Split("/")
        $LatestSegmentIndex = [System.Array]::IndexOf($PathSegments, "latest")
        if ($LatestSegmentIndex -lt 0) {
            throw "Get-AmazonCorretto: Download URI [$Url] does not contain the expected latest path segment."
        }
        $PathSegments[$LatestSegmentIndex] = "latest_checksum"
        $ChecksumUriBuilder.Path = [System.String]::Join("/", $PathSegments)
        $ChecksumUrl = $ChecksumUriBuilder.Uri.AbsoluteUri

        $VersionMatch = $VersionRegex.Match($Response.ResponseUri.LocalPath)
        if (-not $VersionMatch.Success -or -not $VersionMatch.Groups[1].Success) {
            throw "Get-AmazonCorretto: Could not extract a version from resolved URI [$($Response.ResponseUri.AbsoluteUri)]."
        }

        $Checksum = [string](Invoke-EvergreenWebRequest -Uri $ChecksumUrl -Raw -ReturnObject "Content")
        $Checksum = $Checksum.Trim()
        if ($Checksum -notmatch "^[a-fA-F0-9]{32}$") {
            throw "Get-AmazonCorretto: Checksum response from [$ChecksumUrl] is not a valid MD5 checksum."
        }

        $ResolvedUri = $Response.ResponseUri.AbsoluteUri
        if ($Response.ResponseUri.AbsolutePath -notmatch "(?i)(?<![a-z0-9])(?:x64|amd64|x86_64|x86|i[3-6]86|aarch64|arm64|win64|win32|nt64|nt32)(?![a-z0-9])") {
            throw "Get-AmazonCorretto: Could not determine the architecture from resolved URI [$ResolvedUri]."
        }

        $ImageType = if ($Url -match "(?i)(?:^|[-/])jre(?=[-.]|$)") {
            "JRE"
        }
        elseif ($Url -match "(?i)(?:^|[-/])jdk(?=[-.]|$)") {
            "JDK"
        }
        else {
            "Unknown"
        }

        $PSObject = [PSCustomObject] @{
            Version      = $VersionMatch.Groups[1].Value
            Md5          = $Checksum
            Architecture = Get-Architecture -String $ResolvedUri
            ImageType    = $ImageType
            Type         = Get-FileType -File $ResolvedUri
            URI          = $ResolvedUri
        }
        Write-Output -InputObject $PSObject
    }
}
