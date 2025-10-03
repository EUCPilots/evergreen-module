function Get-ElgatoApp {
    <#
        .SYNOPSIS
            Get the current versions and download URLs for Elgato apps.

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

    # Get the update API
    $params = @{
        Uri         = $res.Get.Update.Uri
        ContentType = "application/json"
    }
    $Releases = Invoke-EvergreenRestMethod @params

    # Build the output object for each returned release
    foreach ($Release in $Releases.$($res.Get.Update.Property)) {
        $PSObject = [PSCustomObject]@{
            Version      = $Release.version
            Architecture = Get-Architecture -String $Release.minimumOS
            Type         = Get-FileType -File $Release.downloadUrl
            URI          = $Release.downloadUrl
        }
        Write-Output -InputObject $PSObject
    }
}
