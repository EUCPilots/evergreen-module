function Get-OracleJava {
    <#
        .SYNOPSIS
            Returns details for Oracle Java

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

    # Get the Oracle Java releases JSON
    $params = @{
        Uri       = $res.Get.Update.Uri
        Headers   = $res.Get.Update.Headers
        UserAgent = $res.Get.Update.UserAgent
    }
    $UpdateFeed = Invoke-EvergreenRestMethod @params

    if ($null -eq $UpdateFeed.data.releases) {
        throw "$($MyInvocation.MyCommand): The Oracle Java releases response did not contain a releases collection."
    }

    # Select the latest delivered release for the requested family.
    $Releases = @($UpdateFeed.data.releases | Where-Object {
            $_.family -eq $res.Get.Update.Family -and $_.status -eq "delivered"
        })
    if ($Releases.Count -eq 0) {
        throw "$($MyInvocation.MyCommand): No delivered release found for family [$($res.Get.Update.Family)]."
    }

    $VersionParts = foreach ($Release in $Releases) {
        $VersionText = [System.String]$Release.version
        if ($VersionText -notmatch '^\d+(?:\.\d+)*$') {
            throw "$($MyInvocation.MyCommand): Invalid release version [$($Release.version)] for family [$($res.Get.Update.Family)]."
        }
        if ([System.String]::IsNullOrWhiteSpace($Release.fullversion) -or [System.String]::IsNullOrWhiteSpace($Release.ga)) {
            throw "$($MyInvocation.MyCommand): Release [$($Release.version)] is missing its fullversion or GA date."
        }

        [PSCustomObject]@{
            Release = $Release
            Parts   = @($VersionText.Split('.') | ForEach-Object { $_ -replace '^0+(?=\d)', '' })
        }
    }

    $PartCount = ($VersionParts | ForEach-Object { $_.Parts.Count } | Measure-Object -Maximum).Maximum
    $PartWidths = for ($Index = 0; $Index -lt $PartCount; $Index++) {
        $Width = ($VersionParts | ForEach-Object {
                if ($Index -lt $_.Parts.Count) { $_.Parts[$Index].Length } else { 1 }
            } | Measure-Object -Maximum).Maximum
        [System.Math]::Max(1, $Width)
    }
    $VersionedReleases = foreach ($VersionPart in $VersionParts) {
        $SortKey = for ($Index = 0; $Index -lt $PartCount; $Index++) {
            $Part = if ($Index -lt $VersionPart.Parts.Count) { $VersionPart.Parts[$Index] } else { '0' }
            $Part.PadLeft($PartWidths[$Index], '0')
        }
        [PSCustomObject]@{
            Release = $VersionPart.Release
            SortKey = $SortKey -join ''
        }
    }
    $LatestVersion = $VersionedReleases | Sort-Object -Property SortKey -Descending | Select-Object -First 1
    $LatestVersion = $LatestVersion.Release
    Write-Verbose -Message "$($MyInvocation.MyCommand): Found version: $($LatestVersion.version)"

    # Return an object for each of the download URIs listed in the manifest
    foreach ($Type in $res.Get.Download.Uri.GetEnumerator()) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Build object for $($Type.Name)."

        $Sha256 = $null
        try {
            $ChecksumUri = "$($res.Get.Download.Uri[$Type.Key]).sha256"
            $ChecksumContent = Invoke-EvergreenWebRequest -uri $ChecksumUri -ReturnObject "Content"
            $Checksum = ([System.String]$ChecksumContent).Trim()
            if ($Checksum -match '^(?<Hash>[A-Fa-f0-9]{64})(?:\s+.*)?$') {
                $Sha256 = $Matches.Hash
            }
            else {
                Write-Warning -Message "$($MyInvocation.MyCommand): The SHA256 checksum response from [$ChecksumUri] was empty or invalid."
            }
        }
        catch {
            Write-Warning -Message "$($MyInvocation.MyCommand): Failed to retrieve the SHA256 checksum from [$ChecksumUri]. Error: $($_.Exception.Message)"
        }

        [PSCustomObject] @{
            Version      = $LatestVersion.version
            FullVersion  = $LatestVersion.fullversion
            Date         = ConvertTo-DateTime -DateTime $LatestVersion.ga -Pattern $res.Get.Update.DateFormat
            Sha256       = $Sha256
            Architecture = Get-Architecture -String $res.Get.Download.Uri[$Type.Key]
            Type         = Get-FileType -File $res.Get.Download.Uri[$Type.Key]
            URI          = $res.Get.Download.Uri[$Type.Key]
        } | Write-Output
    }
}
