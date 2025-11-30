function Get-AzulZulu {
    <#
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

    # Pass the repo releases API URL and return a formatted object
    $params = @{
        Uri         = $res.Get.Update.Uri
        ContentType = $res.Get.Update.ContentType
    }
    $Releases = Invoke-EvergreenRestMethod @params
    Write-Verbose -Message "$($MyInvocation.MyCommand): found $($Releases.count) releases."

    $Version = $Releases | Sort-Object { [System.Version]($_.distro_version -join ".") } -Descending | Select-Object -First 1
    $LatestVersion = $Version.distro_version -join "."
    Write-Verbose -Message "$($MyInvocation.MyCommand): found latest version: $LatestVersion"

    Write-Verbose -Message "$($MyInvocation.MyCommand): Filter for latest releases."
    foreach ($Release in ($Releases | Where-Object { ($_.distro_version -join ".") -eq ($Version.distro_version -join ".") })) {
        $PSObject = [PSCustomObject]@{
            Version      = $Release.distro_version -join "."
            JavaVersion  = "$($Release.java_version -join ".")+$($Release.openjdk_build_number)"
            ImageType    = $(if ($Release.download_url -match "jre") { "JRE" } else { "JDK" })
            Architecture = Get-Architecture -String $Release.download_url
            Type         = Get-FileType -File $Release.download_url
            URI          = $Release.download_url
        }
        Write-Output -InputObject $PSObject
    }
}
