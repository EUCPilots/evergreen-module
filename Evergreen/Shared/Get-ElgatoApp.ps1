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

        # Process each property in the update metadata
        foreach ($Item in $res.Get.Update.Property) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Processing item: $Item"

            # Build the output object for each returned release
            foreach ($Release in $Releases.$Item) {
                if ($Release.fileURLs -is [System.Object]) {

                    # Get the list of properties for the file URLs
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Processing file URLs for release: $($Release.version)"
                    $Properties = $Release.fileURLs | Get-Member -MemberType "NoteProperty" | Select-Object -ExpandProperty "Name"

                    # Process each file URL for the current release
                    foreach ($Property in $Properties) {
                        $ResolvedUrl = (Resolve-SystemNetWebRequest -Uri $Release.fileURLs.$Property).ResponseUri.AbsoluteUri
                        [PSCustomObject]@{
                            Version      = $Release.version
                            Release      = if ($Item -match "beta") { "Beta" } else { "Stable" }
                            Architecture = Get-Architecture -String $ResolvedUrl
                            Type         = Get-FileType -File $ResolvedUrl
                            URI          = $ResolvedUrl
                        }
                    }
                }
                else {
                    # Process the single download URL for the current release
                    [PSCustomObject]@{
                        Version      = $Release.version
                        Release      = if ($Item -match "beta") { "Beta" } else { "Stable" }
                        Architecture = Get-Architecture -String $Release.downloadUrl
                        Type         = Get-FileType -File $Release.downloadUrl
                        URI          = $Release.downloadUrl
                    }
                }
            }
        }
    }
}
