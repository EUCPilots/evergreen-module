function Get-BellSoftLibericaJDK {
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
        throw "Get-BellSoftLibericaJDK: The resource is missing the Get.Download configuration."
    }

    $DownloadConfig = $res.Get.Download
    $ApiUriTemplate = [string]$DownloadConfig.Uri
    if ([string]::IsNullOrWhiteSpace($ApiUriTemplate)) {
        throw "Get-BellSoftLibericaJDK: The resource is missing Get.Download.Uri."
    }

    $ParsedApiUri = $null
    $UriTemplateForValidation = $ApiUriTemplate -replace "#(?:Platform|Version|Architecture|Bitness)", "value"
    if (-not [System.Uri]::TryCreate($UriTemplateForValidation, [System.UriKind]::Absolute, [ref]$ParsedApiUri) -or $ParsedApiUri.Scheme -notin @("http", "https")) {
        throw "Get-BellSoftLibericaJDK: Get.Download.Uri must be an absolute HTTP or HTTPS URI template."
    }

    $Platforms = @($DownloadConfig.Platforms)
    $Versions = @($DownloadConfig.Versions)
    $Architectures = @($DownloadConfig.Architectures)
    $Bitnesses = @($DownloadConfig.Bitness)
    $ConfiguredValues = @{
        Platforms     = $Platforms
        Versions      = $Versions
        Architectures = $Architectures
        Bitness       = $Bitnesses
    }
    foreach ($Name in $ConfiguredValues.Keys) {
        $Values = $ConfiguredValues[$Name]
        if ($Values.Count -eq 0 -or @($Values | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
            throw "Get-BellSoftLibericaJDK: Get.Download.$Name must contain one or more non-empty values."
        }
    }

    foreach ($Placeholder in @("#Platform", "#Version", "#Architecture", "#Bitness")) {
        if (-not $ApiUriTemplate.Contains($Placeholder)) {
            throw "Get-BellSoftLibericaJDK: Get.Download.Uri is missing the $Placeholder placeholder."
        }
    }

    $ContentType = [string]$DownloadConfig.ContentType
    $RequestCount = [long]$Platforms.Count * $Versions.Count * $Architectures.Count * $Bitnesses.Count
    Write-Verbose -Message "$($MyInvocation.MyCommand): making $RequestCount API requests."

    foreach ($Platform in $Platforms) {
        foreach ($Version in $Versions) {
            foreach ($Architecture in $Architectures) {
                foreach ($Bitness in $Bitnesses) {
                    $Url = [string]$ApiUriTemplate
                    $Url = $Url.Replace("#Platform", [System.Uri]::EscapeDataString([string]$Platform))
                    $Url = $Url.Replace("#Version", [System.Uri]::EscapeDataString([string]$Version))
                    $Url = $Url.Replace("#Architecture", [System.Uri]::EscapeDataString([string]$Architecture))
                    $Url = $Url.Replace("#Bitness", [System.Uri]::EscapeDataString([string]$Bitness))

                    $ParsedUri = $null
                    if (-not [System.Uri]::TryCreate($Url, [System.UriKind]::Absolute, [ref]$ParsedUri) -or $ParsedUri.Scheme -notin @("http", "https")) {
                        throw "Get-BellSoftLibericaJDK: The configured URI template produced an invalid HTTP or HTTPS URI."
                    }

                    $params = @{
                        Uri = $Url
                    }
                    if (-not [string]::IsNullOrWhiteSpace($ContentType)) {
                        $params.ContentType = $ContentType
                    }

                    $Releases = @(Invoke-EvergreenRestMethod @Params -ErrorAction Stop)
                    $ReleaseIndex = 0
                    foreach ($Release in $Releases) {
                        if ($null -eq $Release) {
                            throw "Get-BellSoftLibericaJDK: The API response contains a null release at index $ReleaseIndex."
                        }
                        if ([string]::IsNullOrWhiteSpace([string]$Release.version)) {
                            throw "Get-BellSoftLibericaJDK: The API response is missing version for release at index $ReleaseIndex."
                        }
                        if ([string]::IsNullOrWhiteSpace([string]$Release.downloadUrl)) {
                            throw "Get-BellSoftLibericaJDK: The API response is missing downloadUrl for release at index $ReleaseIndex."
                        }

                        $DownloadUri = [string]$Release.downloadUrl
                        $ParsedDownloadUri = $null
                        if (-not [System.Uri]::TryCreate($DownloadUri, [System.UriKind]::Absolute, [ref]$ParsedDownloadUri) -or $ParsedDownloadUri.Scheme -notin @("http", "https")) {
                            throw "Get-BellSoftLibericaJDK: The API response contains an invalid downloadUrl for release at index $ReleaseIndex."
                        }

                        $OutputObject = [PSCustomObject]@{
                            Version      = $Release.version
                            LTS          = $Release.LTS
                            BundleType   = $Release.bundleType
                            Sha1         = $Release.sha1
                            Size         = $Release.size
                            Architecture = Get-Architecture -String $DownloadUri
                            Type         = $Release.packageType
                            URI          = $DownloadUri
                        }
                        Write-Output -InputObject $OutputObject
                        $ReleaseIndex++
                    }
                }
            }
        }
    }
}
