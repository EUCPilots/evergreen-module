function Invoke-EvergreenWebRequest {
    <#
        .SYNOPSIS
            Validates and return responses from Invoke-WebRequest
            Enables normalisation for all public functions and across PowerShell/Windows PowerShell
            Some validation of $Uri is expected before passing to this function
        .DESCRIPTION
            With -Raw, the response is written to a temporary file to avoid response parsing, then returned as UTF-8 text.
            Binary responses are not supported by -Raw.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $ContentType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable] $Headers,

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
        [System.Management.Automation.SwitchParameter] $Raw,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $SkipCertificateCheck,

        [Parameter()]
        [ValidateSet("Content", "RawContent", "Headers", "All")]
        [System.String] $ReturnObject = "Content"
    )

    # Disable the Invoke-WebRequest progress bar for faster downloads
    if ($PSBoundParameters.ContainsKey("Verbose")) {
        $ProgressPreference = [System.Management.Automation.ActionPreference]::Continue
    }
    else {
        $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
    }

    $SkipCertificateCheckEnabled = ($script:SkipCertificateCheck -eq $true -or $SkipCertificateCheck.IsPresent)
    $IsPSCore = Test-PSCore
    $TempFile = $null
    $PreviousCertificatePolicy = $null
    $RestoreCertificatePolicy = $false
    $PreviousSecurityProtocol = $null
    $RestoreSecurityProtocol = $false

    try {
        if ($PSCmdlet.ShouldProcess($Uri, "Invoke-WebRequest")) {
            # Windows PowerShell 5.1 does not support SkipCertificateCheck on Invoke-WebRequest.
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

            # Build the Invoke-WebRequest parameters
            $params = @{
                Uri             = $Uri
                Method          = $Method
                UserAgent       = $UserAgent
                UseBasicParsing = $true
            }

            # Set additional parameters
            if ($PSBoundParameters.ContainsKey("ContentType")) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Adding ContentType."
                $params.ContentType = $ContentType
            }
            if ($PSBoundParameters.ContainsKey("Headers")) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Adding Headers."
                $params.Headers = $Headers
            }
            if ($SkipCertificateCheckEnabled -and $IsPSCore) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Adding SkipCertificateCheck."
                $params.SkipCertificateCheck = $true
            }
            if ($PSBoundParameters.ContainsKey("SslProtocol") -and $IsPSCore) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Adding SslProtocol."
                $params.SslProtocol = $SslProtocol
            }
            if ($PSBoundParameters.ContainsKey("Raw")) {
                $TempFile = New-TemporaryFile
                $params.OutFile = $TempFile.FullName
                $params.PassThru = $true
                Write-Verbose -Message "$($MyInvocation.MyCommand): Using temporary response file."
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
                Write-Verbose -Message "$($MyInvocation.MyCommand): Invoke-WebRequest parameter: $($item.name): $($item.value)."
            }

            # Raw response files are returned as UTF-8 text for existing text-response callers.
            if ($PSBoundParameters.ContainsKey("Raw")) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Raw output is UTF-8 text; binary responses are not supported."
            }
            $Response = Invoke-WebRequest @params

            if ($null -ne $Response) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Response: $($Response.StatusCode)."
                Write-Verbose -Message "$($MyInvocation.MyCommand): Content type: $($Response.Headers.'Content-Type')."

                # Output content from the response
                switch ($ReturnObject) {
                    "All" {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Returning entire response."
                        Write-Output -InputObject $Response
                    }
                    "Headers" {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Returning headers."
                        Write-Output -InputObject $Response.Headers
                    }
                    "RawContent" {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Returning raw content of length: $($Response.RawContent.Length)."
                        Write-Output -InputObject $Response.RawContent
                    }
                    default {
                        if ($PSBoundParameters.ContainsKey("Raw")) {
                            $Content = Get-Content -LiteralPath $TempFile.FullName -Raw -Encoding UTF8
                        }
                        else {
                            $Content = $Response.Content
                        }
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Returning content of length: $($Content.Length)."
                        Write-Output -InputObject $Content
                    }
                }
            }
        }
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
        if ($null -ne $TempFile -and (Test-Path -LiteralPath $TempFile.FullName)) {
            Remove-Item -LiteralPath $TempFile.FullName -Force -ErrorAction Stop
        }
    }
}
