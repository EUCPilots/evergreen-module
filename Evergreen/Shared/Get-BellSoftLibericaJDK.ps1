function Get-BellSoftLibericaJDK {
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

    # Pass the releases API URL and return a formatted object
    foreach ($Platform in $res.Get.Download.Platforms) {
        foreach ($Version in $res.Get.Download.Versions) {
            foreach ($Architecture in $res.Get.Download.Architectures) {
                foreach ($Bitness in $res.Get.Download.Bitness) {

                    # Build the URL for this query
                    $Url = $res.Get.Download.Uri -replace "#Platform", $Platform `
                        -replace "#Version", $Version `
                        -replace "#Architecture", $Architecture `
                        -replace "#Bitness", $Bitness

                    # Query the download API
                    $params = @{
                        Uri         = $Url
                        ContentType = $res.Get.Download.ContentType
                    }
                    $Releases = Invoke-EvergreenRestMethod @params

                    # Build the output object for each returned release
                    foreach ($Release in $Releases) {
                        $PSObject = [PSCustomObject]@{
                            Version      = $Release.version
                            LTS          = $Release.LTS
                            BundleType   = $Release.bundleType
                            Type         = $Release.packageType
                            Architecture = Get-Architecture -String $Release.downloadUrl
                            Sha1         = $Release.sha1
                            Size         = $Release.size
                            URI          = $Release.downloadUrl
                        }
                        Write-Output -InputObject $PSObject
                    }
                }
            }
        }
    }
}
