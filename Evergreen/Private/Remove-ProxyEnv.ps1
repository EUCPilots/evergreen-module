function Remove-ProxyEnv {
    <#
        .SYNOPSIS
            Remove proxy server and credentials information from environment variables
        .DESCRIPTION
            This function removes the Evergreen proxy server and credentials information
            from the script-scoped environment variables.
    #>
    foreach ($VariableName in @("EvergreenProxy", "EvergreenProxyCreds")) {
        if ($null -ne (Get-Variable -Name $VariableName -Scope "Script" -ErrorAction "SilentlyContinue")) {
            Remove-Variable -Name $VariableName -Scope "Script" -Force -ErrorAction "Stop"
        }
    }
}
