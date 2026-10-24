function Get-JetBrainsApp {
    <#
        .SYNOPSIS
            Get the current version and download URLs for a JetBrains app
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    $Update = $res.Get.Update
    if ([System.String]::IsNullOrWhiteSpace($Update.Uri)) {
        throw "$($MyInvocation.MyCommand): Update URI is missing from the resource."
    }
    if ([System.String]::IsNullOrWhiteSpace($Update.ReplaceEdition) -or $Update.Uri.IndexOf($Update.ReplaceEdition, [System.StringComparison]::Ordinal) -lt 0) {
        throw "$($MyInvocation.MyCommand): Update URI is missing the configured edition placeholder."
    }

    $Editions = @($Update.Editions.GetEnumerator())
    if ($Editions.Count -eq 0) {
        throw "$($MyInvocation.MyCommand): No editions are configured in the resource."
    }

    $EditionCodes = @($Editions | ForEach-Object { $_.Value })
    if ($EditionCodes | Where-Object { [System.String]::IsNullOrWhiteSpace($_) }) {
        throw "$($MyInvocation.MyCommand): An edition code is empty in the resource."
    }

    # JetBrains accepts comma-separated product codes, so request the release feed once for all editions.
    $Uri = $Update.Uri.Replace($Update.ReplaceEdition, ($EditionCodes -join ","))
    $UpdateFeed = Invoke-EvergreenRestMethod -Uri $Uri

    foreach ($Edition in $Editions) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Get application details for: $($Edition.Key)"
        $ReleaseProperty = $UpdateFeed.PSObject.Properties[$Edition.Value]
        if ($null -eq $ReleaseProperty) {
            Write-Warning -Message "$($MyInvocation.MyCommand): No release data was returned for edition '$($Edition.Key)' ($($Edition.Value)) from '$Uri'."
            continue
        }
        $Release = $ReleaseProperty.Value
        $WindowsDownload = $Release.downloads.windows
        if ($null -eq $WindowsDownload -or [System.String]::IsNullOrWhiteSpace($WindowsDownload.link)) {
            Write-Warning -Message "$($MyInvocation.MyCommand): No Windows download link was returned for edition '$($Edition.Key)' ($($Edition.Value)) from '$Uri'."
            continue
        }
        if ([System.String]::IsNullOrWhiteSpace($Release.version) -or [System.String]::IsNullOrWhiteSpace($Release.date)) {
            throw "$($MyInvocation.MyCommand): Release data for edition '$($Edition.Key)' ($($Edition.Value)) is missing the version or date."
        }

        $Sha256 = $null
        if (-not [System.String]::IsNullOrWhiteSpace($WindowsDownload.checksumLink)) {
            try {
                $ChecksumResponse = Invoke-EvergreenRestMethod -Uri $WindowsDownload.checksumLink
                $ChecksumParts = @("$ChecksumResponse" -split '\s+' | Where-Object { -not [System.String]::IsNullOrWhiteSpace($_) })
                if ($ChecksumParts.Count -gt 0) {
                    $Sha256 = $ChecksumParts[0]
                }
                else {
                    Write-Warning -Message "$($MyInvocation.MyCommand): The SHA256 checksum response was empty for edition '$($Edition.Key)' from '$($WindowsDownload.checksumLink)'."
                }
            }
            catch {
                Write-Warning -Message "$($MyInvocation.MyCommand): Failed to retrieve the SHA256 checksum for edition '$($Edition.Key)' from '$($WindowsDownload.checksumLink)'. Error: $_"
            }
        }

        $PSObject = [PSCustomObject] @{
            Version = $Release.version
            Build   = $Release.build
            Edition = $Edition.Key
            Date    = ConvertTo-DateTime -DateTime $Release.date -Pattern $Update.DatePattern
            Sha256  = $Sha256
            Size    = $WindowsDownload.size
            Type    = Get-FileType -File $WindowsDownload.link
            URI     = $WindowsDownload.link
        }
        Write-Output -InputObject $PSObject
    }
}
