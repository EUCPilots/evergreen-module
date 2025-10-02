function Get-JetBrainsApp {
    <#
        .SYNOPSIS
            Get the current version and download URLs for a JetBrains app
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    foreach ($Edition in $res.Get.Update.Editions.GetEnumerator()) {

        # Build the update uri based on the edition
        Write-Verbose -Message "$($MyInvocation.MyCommand): Get application details for: $($Edition.Key)"
        $uri = $res.Get.Update.Uri -replace $res.Get.Update.ReplaceEdition, $Edition.Value

        # Query the JetBrains URI to get the JSON
        $UpdateFeed = Invoke-EvergreenRestMethod -Uri $uri
        if ([System.String]::IsNullOrWhiteSpace($UpdateFeed.$($Edition.Value).downloads.windows.link)) {
            Write-Warning -Message "$($MyInvocation.MyCommand): 'downloads.windows.link' property is null; from '$uri'."
        }
        else {
            # Construct the output; Return the custom object to the pipeline
            $PSObject = [PSCustomObject] @{
                Version = $UpdateFeed.$($Edition.Value).version
                Build   = $UpdateFeed.$($Edition.Value).build
                Edition = $Edition.Key
                Sha256  = $UpdateFeed.$($Edition.Value).downloads.windows.checksumLink
                Date    = ConvertTo-DateTime -DateTime $UpdateFeed.$($Edition.Value).date -Pattern $res.Get.Update.DatePattern
                Size    = $UpdateFeed.$($Edition.Value).downloads.windows.size
                Type    = Get-FileType -File $UpdateFeed.$($Edition.Value).downloads.windows.link
                URI     = $UpdateFeed.$($Edition.Value).downloads.windows.link
            }
            Write-Output -InputObject $PSObject
        }
    }
}
