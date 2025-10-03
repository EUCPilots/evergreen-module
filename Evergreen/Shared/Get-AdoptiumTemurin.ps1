function Get-AdoptiumTemurin {
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

    # Build the output object for each returned release
    foreach ($Release in ($Releases | Where-Object { $_.binary.image_type -match $res.Get.Update.MatchImage -and $null -ne $_.binary.installer.link})) {

        if ($res.Get.Update.ResolveUri -eq $true) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Resolving $($Release.binary.installer.link)."
            $Uri = Resolve-InvokeWebRequest -Uri $Release.binary.installer.link
        }
        else {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Keep $($Release.binary.installer.link)."
            $Uri = $Release.binary.installer.link
        }

        if ([System.String]::IsNullOrWhiteSpace($Release.binary.updated_at)) {
            $PSObject = [PSCustomObject]@{
                Version      = $Release.version.openjdk_version -replace "jdk-", ""
                Date         = $Release.binary.timestamp
                ImageType    = $Release.binary.image_type
                Architecture = Get-Architecture -String $Release.binary.architecture
                Type         = Get-FileType -File $Uri
                URI          = $Uri
            }
            Write-Output -InputObject $PSObject
        }
        else {
            $PSObject = [PSCustomObject]@{
                Version      = $Release.version.openjdk_version -replace "jdk-", ""
                Date         = $Release.binary.updated_at
                ImageType    = $Release.binary.image_type
                Checksum     = $Release.binary.installer.checksum
                Size         = $Release.binary.installer.size
                Architecture = Get-Architecture -String $Release.binary.architecture
                Type         = Get-FileType -File $Uri
                URI          = $Uri
            }
            Write-Output -InputObject $PSObject
        }
    }
}
