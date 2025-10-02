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

    begin {}
    process {
        if ($PSBoundParameters.ContainsKey("Creds")) {
            Test-Path -Path "Variable:EvergreenProxyCreds"
        }
        else {
            Test-Path -Path "Variable:EvergreenProxy"
        }
    }
}
