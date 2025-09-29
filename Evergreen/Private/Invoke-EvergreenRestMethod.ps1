function Invoke-EvergreenRestMethod {
    <#
        .SYNOPSIS
            Validate and return content from Invoke-RestMethod for reading update APIs (typically JSON)
            Enables normalisation for all public functions and across PowerShell/Windows PowerShell
            Some validation of $Uri is expected before passing to this function
            Does not support redirection, as this should be handled before sending to this function
    #>
    [OutputType([Microsoft.PowerShell.Commands.WebResponseObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $ContentType = "application/json; charset=utf-8",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable] $Headers,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        #[System.Collections.Hashtable] $Body,
        [System.Object] $Body,

        [Parameter()]
        [ValidateSet("Default", "Get", "Head", "Post")]
        [System.String] $Method = "Default",

        [Parameter()]
        [ValidateSet("Default", "Tls", "Tls11", "Tls12", "Tls13")]
        [System.String] $SslProtocol = "Tls12",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $UserAgent = $script:resourceStrings.UserAgent.Base,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $SkipCertificateCheck,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $AllowInsecureRedirect
    )

    # Set ErrorAction value
    if ($PSBoundParameters.ContainsKey("ErrorAction")) {
        $ErrorActionPreference = $ErrorAction
    }
    else {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }

    # PowerShell 5.1: Trust certificate used by the remote server (typically self-sign certs)
    # PowerShell Core will use -SkipCertificateCheck
    if (($script:SkipCertificateCheck -eq $true -or $PSBoundParameters.ContainsKey("SkipCertificateCheck")) -and -not(Test-PSCore)) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Creating class TrustAllCertsPolicy."
        Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
        Write-Verbose -Message "$($MyInvocation.MyCommand): Trust all certificates."
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName "TrustAllCertsPolicy"
    }

    # Use TLS for connections
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    #region Build the Invoke-RestMethod parameters
    $params = @{
        Uri                = $Uri
        ContentType        = $ContentType
        DisableKeepAlive   = $true
        MaximumRedirection = 2
        Method             = $Method
        UseBasicParsing    = $true
        UserAgent          = $UserAgent
    }
    if ($PSBoundParameters.ContainsKey("Headers")) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Adding Headers."
        $params.Headers = $Headers
    }
    if ($PSBoundParameters.ContainsKey("Body")) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Adding Body."
        $params.Body = $Body
    }
    if (($script:SkipCertificateCheck -eq $true -or $PSBoundParameters.ContainsKey("SkipCertificateCheck")) -and (Test-PSCore)) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Adding SkipCertificateCheck."
        $params.SkipCertificateCheck = $true
    }
    if ($PSBoundParameters.ContainsKey("SslProtocol") -and (Test-PSCore)) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Adding SslProtocol."
        $params.SslProtocol = $SslProtocol
    }
    if ($PSBoundParameters.ContainsKey("AllowInsecureRedirect")) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Adding Body."
        $params.AllowInsecureRedirect = $true
    }
    if (Test-ProxyEnv) {
        $params.Proxy = $script:EvergreenProxy
    }
    if (Test-ProxyEnv -Creds) {
        $params.ProxyCredential = $script:EvergreenProxyCreds
    }
    #endregion

    # Output the parameters when using -Verbose
    foreach ($item in $params.GetEnumerator()) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Invoke-RestMethod parameter: $($item.name): $($item.value)."
    }

    # Call Invoke-RestMethod
    try {
        $Response = Invoke-RestMethod @params
        Write-Output -InputObject $Response
    }
    catch {
        Write-Warning -Message "$($MyInvocation.MyCommand): $($_.Exception.Message), with: $Uri."
        Write-Warning -Message "$($MyInvocation.MyCommand): For troubleshooting steps see: $($script:resourceStrings.Uri.Info)."
        throw $_
    }
}
