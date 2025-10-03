function Get-OperaApp {
    <#
        .SYNOPSIS
            Returns the available version and URIs for Opera apps

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

    foreach ($Channel in $res.Get.Update.Channels) {
        $Update = Invoke-EvergreenRestMethod -Uri $res.Get.Update.Uri[$Channel]

        if ($null -ne $Update.($res.Get.Update.Property)) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): checking property: $($res.Get.Update.Property)."
            Write-Verbose -Message "$($MyInvocation.MyCommand): found version: $($Update.($res.Get.Update.Property))"

            # Step through each installer type
            foreach ($Architecture in $res.Get.Download.Architectures) {

                # Create the URL
                $Url = $res.Get.Download.Uri[$Channel] -replace "#version", $Update.($res.Get.Update.Property) `
                    -replace "#architecture", $res.Get.Download.Architecture[$Architecture]

                # Build the output object; Output object to the pipeline
                $PSObject = [PSCustomObject] @{
                    Version      = $Update.($res.Get.Update.Property)
                    Channel      = $Channel
                    Architecture = $Architecture
                    Type         = Get-FileType -File $Url
                    URI          = $Url
                }
                Write-Output -InputObject $PSObject
            }
        }
    }
}
