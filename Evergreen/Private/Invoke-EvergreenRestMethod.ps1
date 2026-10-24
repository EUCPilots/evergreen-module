function Invoke-EvergreenRestMethod {
    <#
        .SYNOPSIS
            Validate and return content from Invoke-RestMethod for reading update APIs (typically JSON)
            Enables normalisation for all public functions and across PowerShell/Windows PowerShell
            Some validation of $Uri is expected before passing to this function
            Does not support redirection, as this should be handled before sending to this function
    #>
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
        [System.String] $UserAgent = (Get-EvergreenUserAgent),

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

    $SkipCertificateCheckEnabled = ($script:SkipCertificateCheck -eq $true -or $SkipCertificateCheck.IsPresent)
    $IsPSCore = Test-PSCore
    if ($AllowInsecureRedirect.IsPresent) {
        $RestMethodCommand = Get-Command -Name Invoke-RestMethod -ErrorAction Stop
        if (-not $RestMethodCommand.Parameters.ContainsKey("AllowInsecureRedirect")) {
            throw [System.NotSupportedException]::New("AllowInsecureRedirect is not supported by this PowerShell version.")
        }
    }

    $PreviousCertificatePolicy = $null
    $RestoreCertificatePolicy = $false
    $PreviousSecurityProtocol = $null
    $RestoreSecurityProtocol = $false

    try {
        # Windows PowerShell 5.1 does not support SkipCertificateCheck on Invoke-RestMethod.
        # Its ServicePointManager fallback is process-wide, so restore the previous policy below.
        if ($SkipCertificateCheckEnabled -and -not $IsPSCore) {
            if (-not ("TrustAllCertsPolicy" -as [type])) {
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
            }
            $PreviousCertificatePolicy = [System.Net.ServicePointManager]::CertificatePolicy
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName "TrustAllCertsPolicy"
            $RestoreCertificatePolicy = $true
            Write-Verbose -Message "$($MyInvocation.MyCommand): Trusting certificates for this request."
        }

        if (-not $IsPSCore) {
            $PreviousSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol
            $RestoreSecurityProtocol = $true
            if ($SslProtocol -eq "Tls13") {
                throw [System.NotSupportedException]::New("TLS 1.3 is not supported by Windows PowerShell 5.1.")
            }
            $RequestedProtocol = if ($PSBoundParameters.ContainsKey("SslProtocol") -and $SslProtocol -ne "Default") {
                [System.Enum]::Parse([System.Net.SecurityProtocolType], $SslProtocol, $true)
            }
            else {
                [System.Net.SecurityProtocolType]::Tls12
            }
            [System.Net.ServicePointManager]::SecurityProtocol = $PreviousSecurityProtocol -bor $RequestedProtocol
        }

        #region Build the Invoke-RestMethod parameters
        $params = @{
            Uri                = $Uri
            ContentType        = $ContentType
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
        if ($SkipCertificateCheckEnabled -and $IsPSCore) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Adding SkipCertificateCheck."
            $params.SkipCertificateCheck = $true
        }
        if ($PSBoundParameters.ContainsKey("SslProtocol") -and $IsPSCore) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Adding SslProtocol."
            $params.SslProtocol = $SslProtocol
        }
        if ($AllowInsecureRedirect.IsPresent) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Adding AllowInsecureRedirect."
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
        $Response = Invoke-RestMethod @params
        Write-Output -InputObject $Response
    }
    catch {
        Write-Warning -Message "$($MyInvocation.MyCommand): $($_.Exception.Message), with: $Uri."
        Write-Warning -Message "$($MyInvocation.MyCommand): For troubleshooting steps see: $($script:resourceStrings.Uri.Info)."
        throw
    }
    finally {
        if ($RestoreCertificatePolicy) {
            [System.Net.ServicePointManager]::CertificatePolicy = $PreviousCertificatePolicy
        }
        if ($RestoreSecurityProtocol) {
            [System.Net.ServicePointManager]::SecurityProtocol = $PreviousSecurityProtocol
        }
    }
}
