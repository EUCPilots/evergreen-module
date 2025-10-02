function Get-HashicorpApp {
    <#
        .SYNOPSIS
            Get the current versions and download URLs for Hashicorp apps.

        .NOTES
            Author: Aaron Parker
            Twitter: @stealthpuppy
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
        Uri               = $res.Get.Update.Uri
        MatchVersion      = $res.Get.Update.MatchVersion
        Filter            = $res.Get.Update.MatchFileTypes
        ReturnVersionOnly = $true
    }
    $object = Get-GitHubRepoRelease @params

    # Build the output object
    if ($null -ne $object) {
        foreach ($Architecture in $res.Get.Download.Uri.GetEnumerator()) {
            $Uri = $res.Get.Download.Uri[$Architecture.Key] -replace $res.Get.Download.ReplaceText, $object.Version
            $PSObject = [PSCustomObject] @{
                Version      = $object.Version
                Type         = Get-FileType -File $Uri
                Architecture = $Architecture.Name
                URI          = $Uri
            }
            Write-Output -InputObject $PSObject
        }
    }
}
