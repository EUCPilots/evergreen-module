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
        [Parameter(Mandatory = $false, Position = 0)]
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

    # Sort the data for the latest version
    $LatestVersion = $UpdateFeed.data.releases | `
        Where-Object { $_.family -eq $res.Get.Update.Family -and $_.status -eq "delivered" } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.version }; Descending = $true } -ErrorAction "SilentlyContinue" | `
        Select-Object -First 1
    Write-Verbose -Message "$($MyInvocation.MyCommand): Found version: $($LatestVersion.version)"

    # Return an object for each of the download URIs listed in the manifest
    foreach ($Type in $res.Get.Download.Uri.GetEnumerator()) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Build object for $($Type.Name)."

        try {
            $Sha256 = Invoke-EvergreenWebRequest -uri "$($res.Get.Download.Uri[$Type.Key]).sha256" -ReturnObject "Content"
        }
        catch {
            $Sha256 = "$($res.Get.Download.Uri[$Type.Key]).sha256"
        }

        [PSCustomObject] @{
            Version     = $LatestVersion.version
            FullVersion = $LatestVersion.fullversion
            Date        = ConvertTo-DateTime -DateTime $LatestVersion.ga -Pattern $res.Get.Update.DateFormat
            Sha256      = $Sha256
            Type        = Get-FileType -File $res.Get.Download.Uri[$Type.Key]
            URI         = $res.Get.Download.Uri[$Type.Key]
        } | Write-Output
    }
}
