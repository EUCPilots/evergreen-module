function Get-VMwareApp {
    <#
        .SYNOPSIS
            Returns details for VMware Workstation apps

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

    try {
        # Get the latest version of the app provided in $res
        $UpdateFeed = Invoke-EvergreenRestMethod -Uri $res.Get.Update.Uri
        $Latest = $UpdateFeed.metaList.metadata | `
            Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
            Select-Object -First 1
        Write-Verbose -Message "$($MyInvocation.MyCommand): Found latest version $($Latest.Version)."

        # Get the metadata for the latest version
        $GZipFile = Save-File -Uri "$($res.Get.Update.MetadataUrl)/$($Latest.Url)"
        $ExpandFile = Expand-GzipArchive -Path $GZipFile.FullName

        # Convert the metadata XML to an object
        $MetadataXml = [System.Xml.XmlDocument](Get-Content -Path $ExpandFile -ErrorAction "Stop")
        Write-Verbose -Message "$($MyInvocation.MyCommand): Found installer: $($MetadataXml.metadataResponse.bulletin.componentList.component.relativePath.'#text')"
        $Url = "$(Split-Path $res.Get.Update.MetadataUrl -Parent)$($MetadataXml.metadataResponse.bulletin.componentList.component.relativePath.'#text')"

        # Output the object
        [PSCustomObject]@{
            Version = $Latest.version
            Type    = Get-FileType -File $Url
            URI     = $Url
        } | Write-Output
    }
    catch {
        throw $_
    }
    finally {
        #Remove-Item -Path $GZipFile.FullName -ErrorAction "SilentlyContinue"
        #Remove-Item -Path $ExpandFile -ErrorAction "SilentlyContinue"
    }
}
