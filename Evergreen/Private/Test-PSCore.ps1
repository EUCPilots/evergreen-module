function Test-PSCore {
    <#
        .SYNOPSIS
            Returns True if running on PowerShell Core.
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [ValidateNotNullOrEmpty()]
        [System.Version] $Version = [System.Version]"6.0.0"
    )

    if (($PSVersionTable.PSVersion -ge $Version) -and ($PSVersionTable.PSEdition -eq "Core")) {
        Write-Output -InputObject $true
    }
    else {
        Write-Output -InputObject $false
    }
}
