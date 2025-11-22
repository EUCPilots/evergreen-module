function Get-AmazonCorretto {
    <#
        .NOTES
            Author: Aaron Parker
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject]
        $res = (Get-FunctionResource -AppName ("$($MyInvocation.MyCommand)".Split("-"))[1])
    )

    # Get the latest download
    foreach ($Url in $res.Get.Download.Uri) {

        # Resolve the URI from the download URL
        $Response = Resolve-SystemNetWebRequest -Uri $Url

        # Replace text to build the checksum URL
        $ChecksumUrl = $Url -replace "latest", "latest_checksum"

        # Construct the output; Return the custom object to the pipeline
        if ($null -ne $Response) {

            $ImageType = if ($Url -match "jre") {
                "JRE"
            }
            elseif ($Url -match "jdk") {
                "JDK"
            }
            else {
                "Unknown"
            }

            $PSObject = [PSCustomObject] @{
                Version      = [RegEx]::Match($Response.ResponseUri.LocalPath, $res.Get.Download.MatchVersion).Captures.Groups[1].Value
                Md5          = (Invoke-EvergreenWebRequest -Uri $ChecksumUrl -Raw -ReturnObject "Content")
                Architecture = Get-Architecture -String $Response.ResponseUri.AbsoluteUri
                ImageType    = $ImageType
                Type         = Get-FileType -File $Response.ResponseUri.AbsoluteUri
                URI          = $Response.ResponseUri.AbsoluteUri
            }
            Write-Output -InputObject $PSObject
        }
    }
}
