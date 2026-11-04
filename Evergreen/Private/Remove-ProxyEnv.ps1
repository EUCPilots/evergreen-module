function Remove-ProxyEnv {
    <#
        .SYNOPSIS
            Remove proxy server and credentials information from environment variables
        .DESCRIPTION
            This function removes the Evergreen proxy server and credentials information
            from the script-scoped environment variables.
            Supports WhatIf and Confirm when removing each variable.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()

    foreach ($VariableName in @("EvergreenProxy", "EvergreenProxyCreds")) {
        if ($null -ne (Get-Variable -Name $VariableName -Scope "Script" -ErrorAction "SilentlyContinue")) {
            if ($PSCmdlet.ShouldProcess("Script-scoped variable '$VariableName'", "Remove proxy configuration")) {
                Remove-Variable -Name $VariableName -Scope "Script" -Force -Confirm:$false -ErrorAction "Stop"
            }
        }
    }
}
