function Test-PSCore {
    <#
        .SYNOPSIS
            Returns True if running on PowerShell Core.
    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Version = "6.0.0"
    )

    # Check whether current PowerShell environment matches or is higher than $Version
    if (($PSVersionTable.PSVersion -ge [Version]::Parse($Version)) -and ($PSVersionTable.PSEdition -eq "Core")) {
        Write-Output -InputObject $true
    }
    else {
        Write-Output -InputObject $false
    }
}
