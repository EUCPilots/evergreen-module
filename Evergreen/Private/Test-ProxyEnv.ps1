function Test-ProxyEnv {
    <#
        .SYNOPSIS
            Return true if the EvergreenProxy variable is set
    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $Creds
    )

    process {
        if ($Creds) {
            return (Test-Path -Path "Variable:EvergreenProxyCreds") -and
                ($null -ne $script:EvergreenProxyCreds) -and
                ($script:EvergreenProxyCreds -is [System.Management.Automation.PSCredential]) -and
                -not [System.String]::IsNullOrEmpty($script:EvergreenProxyCreds.UserName)
        }

        return (Test-Path -Path "Variable:EvergreenProxy") -and
            (-not [System.String]::IsNullOrWhiteSpace($script:EvergreenProxy))
    }
}
