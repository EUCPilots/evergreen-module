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

    # Get details of the updates metadata
    $params = @{
        Uri         = $res.Get.Update.Uri
        ContentType = "application/json"
    }
    $Releases = Invoke-EvergreenRestMethod @params
    if ($null -ne $Releases) {
        foreach ($Item in $res.Get.Update.Property) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Processing item: $Item"

            # Build the output object for each returned release
            foreach ($Release in $Releases.$Item) {
                $PSObject = [PSCustomObject]@{
                    Version      = $Release.version
                    Release      = if ($Item -match "beta") { "Beta" } else { "Stable" }
                    Architecture = Get-Architecture -String $Release.minimumOS
                    Type         = Get-FileType -File $Release.downloadUrl
                    URI          = $Release.downloadUrl
                }
                Write-Output -InputObject $PSObject
            }
        }
    }
}
