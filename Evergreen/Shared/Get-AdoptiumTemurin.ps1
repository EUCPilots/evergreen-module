function Get-AdoptiumTemurin {
    <#
        .NOTES
            Author: Aaron Parker
            Releases without an installer are skipped.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    $GetValue = {
        param (
            [System.Object] $InputObject,
            [System.String] $Name
        )
        if ($null -eq $InputObject) {
            return $null
        }
        if ($InputObject -is [System.Collections.IDictionary]) {
            return $InputObject[$Name]
        }
        $Property = $InputObject.PSObject.Properties[$Name]
        if ($null -ne $Property) {
            return $Property.Value
        }
        return $null
    }
    $HasProperty = {
        param (
            [System.Object] $InputObject,
            [System.String] $Name
        )
        if ($null -eq $InputObject) {
            return $false
        }
        if ($InputObject -is [System.Collections.IDictionary]) {
            return $InputObject.Contains($Name)
        }
        return $null -ne $InputObject.PSObject.Properties[$Name]
    }

    $Get = & $GetValue $res "Get"
    if ($null -eq $Get) {
        throw "The resource configuration is missing the 'Get' section."
    }
    $Update = & $GetValue $Get "Update"
    if ($null -eq $Update) {
        throw "The resource configuration is missing the 'Get.Update' section."
    }

    $ApiUri = & $GetValue $Update "Uri"
    if ([System.String]::IsNullOrWhiteSpace([System.String]$ApiUri)) {
        throw "The resource configuration is missing a valid 'Get.Update.Uri'."
    }
    $ApiUri = [System.String]$ApiUri
    $ParsedApiUri = $null
    if (-not [System.Uri]::TryCreate($ApiUri, [System.UriKind]::Absolute, [ref]$ParsedApiUri) -or $ParsedApiUri.Scheme -notin @("http", "https")) {
        throw "The configured 'Get.Update.Uri' must be an absolute HTTP or HTTPS URI."
    }

    $MatchImage = & $GetValue $Update "MatchImage"
    if ([System.String]::IsNullOrWhiteSpace([System.String]$MatchImage)) {
        throw "The resource configuration is missing a valid 'Get.Update.MatchImage' regular expression."
    }
    $MatchImage = [System.String]$MatchImage
    try {
        $null = [System.Text.RegularExpressions.Regex]::new($MatchImage)
    }
    catch {
        throw "The configured 'Get.Update.MatchImage' regular expression is invalid: $($_.Exception.Message)"
    }

    $Params = @{
        Uri = $ApiUri
    }
    $ContentType = & $GetValue $Update "ContentType"
    if (-not [System.String]::IsNullOrWhiteSpace([System.String]$ContentType)) {
        $Params.ContentType = [System.String]$ContentType
    }
    $Releases = @(Invoke-EvergreenRestMethod @Params -ErrorAction Stop)
    Write-Verbose -Message "$($MyInvocation.MyCommand): found $($Releases.Count) releases."
    $ResolveUri = & $GetValue $Update "ResolveUri"

    $ReleaseIndex = 0
    $MatchedReleaseCount = 0
    foreach ($Release in $Releases) {
        if ($null -eq $Release) {
            throw "The Adoptium API response contains a null release at index $ReleaseIndex."
        }
        $Binary = & $GetValue $Release "binary"
        if ($null -eq $Binary) {
            throw "The Adoptium API response is missing 'binary' for release at index $ReleaseIndex."
        }
        $ImageType = & $GetValue $Binary "image_type"
        if ([System.String]::IsNullOrWhiteSpace([System.String]$ImageType)) {
            throw "The Adoptium API response is missing 'binary.image_type' for release at index $ReleaseIndex."
        }

        if ([System.String]$ImageType -notmatch $MatchImage) {
            $ReleaseIndex++
            continue
        }

        $Version = & $GetValue $Release "version"
        if ($null -eq $Version) {
            throw "The Adoptium API response is missing 'version' for matching release at index $ReleaseIndex."
        }
        $OpenJdkVersion = & $GetValue $Version "openjdk_version"
        if ([System.String]::IsNullOrWhiteSpace([System.String]$OpenJdkVersion)) {
            throw "The Adoptium API response is missing 'version.openjdk_version' for matching release at index $ReleaseIndex."
        }

        if (-not (& $HasProperty $Binary "installer")) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping release at index $ReleaseIndex without an installer."
            $ReleaseIndex++
            continue
        }
        $Installer = & $GetValue $Binary "installer"
        if ($null -eq $Installer) {
            $ReleaseIndex++
            continue
        }

        $InstallerLink = & $GetValue $Installer "link"
        if ([System.String]::IsNullOrWhiteSpace([System.String]$InstallerLink)) {
            throw "The Adoptium API response is missing 'binary.installer.link' for matching release at index $ReleaseIndex."
        }
        $Architecture = & $GetValue $Binary "architecture"
        if ([System.String]::IsNullOrWhiteSpace([System.String]$Architecture)) {
            throw "The Adoptium API response is missing 'binary.architecture' for matching release at index $ReleaseIndex."
        }
        $InstallerUri = [System.String]$InstallerLink
        $ParsedInstallerUri = $null
        if (-not [System.Uri]::TryCreate($InstallerUri, [System.UriKind]::Absolute, [ref]$ParsedInstallerUri) -or $ParsedInstallerUri.Scheme -notin @("http", "https")) {
            throw "The Adoptium API response contains an invalid installer URI for matching release at index $ReleaseIndex."
        }

        if ($ResolveUri -eq $true) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Resolving $InstallerUri."
            $Uri = Resolve-InvokeWebRequest -Uri $InstallerUri -ErrorAction Stop
            if ([System.String]::IsNullOrWhiteSpace($Uri)) {
                throw "URI resolution returned an empty result for '$InstallerUri'."
            }
            $ParsedResolvedUri = $null
            if (-not [System.Uri]::TryCreate($Uri, [System.UriKind]::Absolute, [ref]$ParsedResolvedUri) -or $ParsedResolvedUri.Scheme -notin @("http", "https")) {
                throw "URI resolution returned an invalid HTTP or HTTPS URI for '$InstallerUri'."
            }
        }
        else {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Keep $InstallerUri."
            $Uri = $InstallerUri
        }

        $UpdatedAt = & $GetValue $Binary "updated_at"
        $Timestamp = & $GetValue $Binary "timestamp"
        $Date = if (-not [System.String]::IsNullOrWhiteSpace([System.String]$UpdatedAt)) {
            $UpdatedAt
        }
        else {
            $Timestamp
        }
        if ([System.String]::IsNullOrWhiteSpace([System.String]$Date)) {
            throw "The Adoptium API response is missing both 'binary.updated_at' and 'binary.timestamp' for matching release at index $ReleaseIndex."
        }
        $Checksum = & $GetValue $Installer "checksum"
        $Size = & $GetValue $Installer "size"
        $OutputObject = [PSCustomObject]@{
            Version      = [System.String]$OpenJdkVersion -replace "^jdk-", ""
            Date         = ConvertTo-DateTime -DateTime $Date -AutoDetect
            ImageType    = $ImageType
            Checksum     = $Checksum
            Size         = $Size
            Architecture = Get-Architecture -String $Architecture
            Type         = Get-FileType -File $Uri
            URI          = $Uri
        }
        Write-Output -InputObject $OutputObject
        $MatchedReleaseCount++
        $ReleaseIndex++
    }

    Write-Verbose -Message "$($MyInvocation.MyCommand): matched $MatchedReleaseCount releases with installer links."
}
