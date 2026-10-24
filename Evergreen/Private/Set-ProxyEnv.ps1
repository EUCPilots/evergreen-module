function Set-ProxyEnv {
    <#
        .SYNOPSIS
            Set proxy server and credentials information into environment variables that other functions can use
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ -not [System.String]::IsNullOrWhiteSpace($_) })]
        [System.String] $Proxy,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $ProxyCredential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        if ($PSBoundParameters.ContainsKey("Proxy")) {
            if ($PSCmdlet.ShouldProcess("Evergreen proxy configuration", "Set proxy configuration")) {
                New-Variable -Name "EvergreenProxy" -Value $Proxy -Scope "Script" -Force

                if ($PSBoundParameters.ContainsKey("ProxyCredential") -and
                    -not [System.String]::IsNullOrEmpty($ProxyCredential.UserName)) {
                    New-Variable -Name "EvergreenProxyCreds" -Value $ProxyCredential -Scope "Script" -Force
                }
                else {
                    Remove-Variable -Name "EvergreenProxyCreds" -Scope "Script" -Force -ErrorAction "SilentlyContinue"
                }
            }
        }
        elseif ($PSBoundParameters.ContainsKey("ProxyCredential")) {
            if ($PSCmdlet.ShouldProcess("Evergreen proxy credentials", "Set proxy credentials")) {
                if (-not [System.String]::IsNullOrEmpty($ProxyCredential.UserName)) {
                    New-Variable -Name "EvergreenProxyCreds" -Value $ProxyCredential -Scope "Script" -Force
                }
                else {
                    Remove-Variable -Name "EvergreenProxyCreds" -Scope "Script" -Force -ErrorAction "SilentlyContinue"
                }
            }
        }
    }
}
