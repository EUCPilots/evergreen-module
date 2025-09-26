function Get-VideoLanVlcPlayer {
    <#
        .SYNOPSIS
            Get the current version and download URL for VideoLAN VLC Media Player.

        .NOTES
            Site: https://stealthpuppy.com
            Author: Aaron Parker
            Twitter: @stealthpuppy
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject]
        $res = (Get-FunctionResource -AppName ("$($MyInvocation.MyCommand)".Split("-"))[1])
    )

    begin {
        Write-Warning -Message "$($MyInvocation.MyCommand): This function returns the version returned by 'Help > Check for Updates' in VLC Player. https://get.videolan.org/ may show a later available version for download."
    }
    process {
        #region Get current version for Windows
        foreach ($Url in $res.Get.Update.Uri) {
            $params = @{
                Uri         = $Url
                UserAgent   = $res.Get.Update.UserAgent
                ContentType = $res.Get.Update.ContentType
            }
            $Content = Invoke-EvergreenRestMethod @params

            if ($null -ne $Content) {
                # Follow the download link which will return a 301
                $params = @{
                    Uri       = ($Content -split "\n")[$res.Get.Download.UrlLine]
                    UserAgent = $res.Get.Update.UserAgent
                }
                $redirectUrl = Resolve-InvokeWebRequest @params

                # Construct the output; Return the custom object to the pipeline
                foreach ($extension in $res.Get.Download.Extensions.Windows) {

                    $Version = ($Content -split "\n")[$res.Get.Download.VersionLine]
                    $Uri = $redirectUrl -replace ".exe$", (".$extension").ToLower()

                    $PSObject = [PSCustomObject] @{
                        Version      = $Version
                        Architecture = Get-Architecture -String $Uri
                        Type         = Get-FileType -File $Uri
                        URI          = $Uri
                    }
                    Write-Output -InputObject $PSObject
                }
            }
        }
        #endregion
    }
}
