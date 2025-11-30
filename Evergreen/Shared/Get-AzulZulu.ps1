function Get-AzulZulu {
    <#
        .SYNOPSIS
            Retrieves Azul Zulu JDK/JRE release information.
        
        .DESCRIPTION
            Queries the Azul API to get the latest Azul Zulu OpenJDK releases.
        
        .PARAMETER res
            Resource object containing API configuration.
        
        .EXAMPLE
            Get-AzulZulu -res $ResourceObject
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    # Constants for property names
    $DISTRO_VERSION = 'distro_version'
    $DOWNLOAD_URL = 'download_url'

    # Pass the repo releases API URL and return a formatted object
    $params = @{
        Uri         = $res.Get.Update.Uri
        ContentType = $res.Get.Update.ContentType
    }
    $Releases = Invoke-EvergreenRestMethod @params

    if ($null -eq $Releases -or $Releases.Count -eq 0) {
        Write-Warning -Message "$($MyInvocation.MyCommand): No releases found."
        return
    }
    else {
        Write-Verbose -Message "$($MyInvocation.MyCommand): found $($Releases.count) releases."
    }

    # Find the latest version
    $Version = $Releases | `
        Where-Object { $null -ne $_.$DISTRO_VERSION } | `
        Sort-Object { [System.Version]($_.$DISTRO_VERSION -join ".") } -Descending | `
        Select-Object -First 1
    $LatestVersion = $Version.$DISTRO_VERSION -join "."
    Write-Verbose -Message "$($MyInvocation.MyCommand): found latest version: $LatestVersion"

    Write-Verbose -Message "$($MyInvocation.MyCommand): Filter for latest releases."
    foreach ($Release in ($Releases | Where-Object { ($_.$DISTRO_VERSION -join ".") -eq ($Version.$DISTRO_VERSION -join ".") })) {
        $PSObject = [PSCustomObject]@{
            Version      = $Release.$DISTRO_VERSION -join "."
            JavaVersion  = "$($Release.java_version -join ".")+$($Release.openjdk_build_number)"
            ImageType    = if ($Release.$DOWNLOAD_URL -match "[/\\]jre[/\\-]") { "JRE" } else { "JDK" }
            Architecture = Get-Architecture -String $Release.$DOWNLOAD_URL
            Type         = Get-FileType -File $Release.$DOWNLOAD_URL
            URI          = $Release.$DOWNLOAD_URL
        }
        Write-Output -InputObject $PSObject
    }
}
