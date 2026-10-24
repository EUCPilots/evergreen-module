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
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    if ($null -eq $res.Get.Update.Channels -or $res.Get.Update.Channels.Count -eq 0) {
        throw "Opera manifest is missing Get.Update.Channels."
    }
    if ([System.String]::IsNullOrWhiteSpace([System.String]$res.Get.Update.Property)) {
        throw "Opera manifest is missing Get.Update.Property."
    }
    if ($null -eq $res.Get.Download.Architectures -or $res.Get.Download.Architectures.Count -eq 0) {
        throw "Opera manifest is missing Get.Download.Architectures."
    }

    foreach ($Channel in $res.Get.Update.Channels) {
        $UpdateUri = $res.Get.Update.Uri[$Channel]
        if ([System.String]::IsNullOrWhiteSpace([System.String]$UpdateUri)) {
            throw "Opera manifest is missing the update URI for channel '$Channel'."
        }
        $DownloadUri = $res.Get.Download.Uri[$Channel]
        if ([System.String]::IsNullOrWhiteSpace([System.String]$DownloadUri)) {
            throw "Opera manifest is missing the download URI for channel '$Channel'."
        }
        if (-not $DownloadUri.Contains("#version")) {
            throw "Opera download URI for channel '$Channel' is missing the #version placeholder."
        }
        if (-not $DownloadUri.Contains("#architecture")) {
            throw "Opera download URI for channel '$Channel' is missing the #architecture placeholder."
        }

        $Update = Invoke-EvergreenRestMethod -Uri $UpdateUri
        if ($null -eq $Update) {
            throw "Opera update response for channel '$Channel' is empty."
        }
        $VersionProperty = $Update.PSObject.Properties[$res.Get.Update.Property]
        if ($null -eq $VersionProperty -or [System.String]::IsNullOrWhiteSpace([System.String]$VersionProperty.Value)) {
            throw "Opera update response for channel '$Channel' is missing a non-empty '$($res.Get.Update.Property)' property."
        }
        $Version = [System.String]$VersionProperty.Value

        Write-Verbose -Message "$($MyInvocation.MyCommand): checking property: $($res.Get.Update.Property)."
        Write-Verbose -Message "$($MyInvocation.MyCommand): found version: $Version"

        # Step through each installer type
        foreach ($Architecture in $res.Get.Download.Architectures) {
            $ArchitectureSuffix = $res.Get.Download.Architecture[$Architecture]
            if ($null -eq $ArchitectureSuffix) {
                throw "Opera manifest is missing the download architecture mapping for '$Architecture'."
            }

            # Create the URL using literal placeholder replacement.
            $Url = $DownloadUri.Replace("#version", $Version).Replace("#architecture", [System.String]$ArchitectureSuffix)

            # Build the output object; Output object to the pipeline
            $PSObject = [PSCustomObject] @{
                Version      = $Version
                Channel      = $Channel
                Architecture = $Architecture
                Type         = Get-FileType -File $Url
                URI          = $Url
            }
            Write-Output -InputObject $PSObject
        }
    }
}
