function Write-AppNotFoundHelp {
    <#
        .SYNOPSIS
            Writes guidance to the information stream when an application name cannot be resolved
            to a supported application, including a list of similar application names.
            Shared by Get-EvergreenApp and Export-EvergreenManifest.
    #>
    [OutputType([System.Void])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name
    )

    Write-Warning -Message "Run 'Update-Evergreen' to update the list of supported applications."
    Write-Information -MessageData "`nPlease list supported application names with Find-EvergreenApp." -InformationAction "Continue"
    Write-Information -MessageData "Find out how to contribute a new application to the Evergreen project at: $($script:resourceStrings.Uri.Docs)." -InformationAction "Continue"

    # Find applications with a similar name to suggest to the user
    try {
        $List = Find-EvergreenApp -Name $Name -ErrorAction "SilentlyContinue" -WarningAction "SilentlyContinue"
        $AppList = ($List | Select-Object -ExpandProperty "Name") -join "`n"
    }
    catch {
        $AppList = ""
    }

    if ([System.String]::IsNullOrWhiteSpace($AppList)) {
        Write-Information -MessageData "`n'$Name' not found. No applications match '$Name'." -InformationAction "Continue"
    }
    else {
        Write-Information -MessageData "`n'$Name' not found. Evergreen supports these similar applications:" -InformationAction "Continue"
        Write-Information -MessageData $AppList -InformationAction "Continue"
    }
    Write-Information -MessageData "" -InformationAction "Continue"
}
