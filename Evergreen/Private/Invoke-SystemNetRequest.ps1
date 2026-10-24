function Invoke-SystemNetRequest {
    <#
        .SYNOPSIS
            Uses System.Net.WebRequest to make a HTTP request and returns the response.

        .DESCRIPTION
            Reads the complete response into memory. Uses the declared response charset,
            or UTF-8 when none is declared, with byte-order mark detection.
            Only absolute HTTP and HTTPS URIs are supported.
            Origin authentication with the current user's credentials is opt-in.
            Proxy authentication remains independent of origin authentication.
            Verbose and warning messages omit URI credentials, queries and fragments.
            The original terminating error is preserved and may contain server details.

        .PARAMETER TimeoutSec
            Timeout for obtaining a response, in seconds. Defaults to 100 seconds.

        .PARAMETER ReadWriteTimeoutSec
            Timeout for individual synchronous stream reads, in seconds. Defaults to
            300 seconds. This is not a limit on the total response download time.

        .PARAMETER UseDefaultCredentials
            Enables the current user's credentials for origin server authentication.
    #>
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Position = 1)]
        [System.String] $UserAgent = (Get-EvergreenUserAgent),

        [Parameter()]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32] $MaximumRedirection = 3,

        [Parameter()]
        [ValidateRange(1, 2147483)]
        [System.Int32] $TimeoutSec = 100,

        [Parameter()]
        [ValidateRange(1, 2147483)]
        [System.Int32] $ReadWriteTimeoutSec = 300,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $UseDefaultCredentials
    )

    $webResponse = $null
    $httpWebRequest = $null
    $responseStream = $null
    $streamReader = $null
    $RequestCompleted = $false
    $SafeUri = "<invalid URI>"

    try {
        $RequestUri = $null
        if (-not [System.Uri]::TryCreate($Uri, [System.UriKind]::Absolute, [ref]$RequestUri) -or
            $RequestUri.Scheme -notin @("http", "https")) {
            throw [System.ArgumentException]::new("Uri must be an absolute HTTP or HTTPS URI.")
        }
        $UriBuilder = [System.UriBuilder]::new($RequestUri)
        $UriBuilder.UserName = ""
        $UriBuilder.Password = ""
        $UriBuilder.Query = ""
        $UriBuilder.Fragment = ""
        $SafeUri = $UriBuilder.Uri.AbsoluteUri

        $httpWebRequest = [System.Net.WebRequest]::Create($RequestUri)
        if (-not [System.String]::IsNullOrEmpty($UserAgent)) {
            $httpWebRequest.UserAgent = $UserAgent
        }
        $httpWebRequest.MaximumAutomaticRedirections = $MaximumRedirection
        $httpWebRequest.AllowAutoRedirect = $true
        $httpWebRequest.Timeout = $TimeoutSec * 1000
        $httpWebRequest.ReadWriteTimeout = $ReadWriteTimeoutSec * 1000
        $httpWebRequest.UseDefaultCredentials = $UseDefaultCredentials.IsPresent

        if (Test-ProxyEnv) {
            $ProxyObj = New-Object -TypeName "System.Net.WebProxy"
            $ProxyObj.Address = $script:EvergreenProxy
            $ProxyObj.UseDefaultCredentials = $true
            $httpWebRequest.Proxy = $ProxyObj

            if (Test-ProxyEnv -Creds) {
                $ProxyObj.UseDefaultCredentials = $false
                $ProxyObj.Credentials = $script:EvergreenProxyCreds
            }
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand): Requesting: $SafeUri."
        $webResponse = $httpWebRequest.GetResponse()
        $responseStream = $webResponse.GetResponseStream()

        $Encoding = [System.Text.Encoding]::UTF8
        if ($webResponse.ContentType -match '(?i)(?:^|;)\s*charset\s*=') {
            $Encoding = [System.Text.Encoding]::GetEncoding($webResponse.CharacterSet.Trim([char[]]@('"', "'")))
        }
        $streamReader = New-Object -TypeName "System.IO.StreamReader" -ArgumentList $responseStream, $Encoding, $true
        $result = $streamReader.ReadToEnd()
        $RequestCompleted = $true
        Write-Output -InputObject $result
    }
    catch {
        $RequestException = $_.Exception
        while ($RequestException -isnot [System.Net.WebException] -and $null -ne $RequestException.InnerException) {
            $RequestException = $RequestException.InnerException
        }
        if ($RequestException -is [System.Net.WebException] -and $null -eq $webResponse) {
            $webResponse = $RequestException.Response
        }
        Write-Warning -Message "$($MyInvocation.MyCommand): Request failed ($($RequestException.GetType().Name)), with: $SafeUri."
        Write-Warning -Message "$($MyInvocation.MyCommand): For troubleshooting steps see: $($script:resourceStrings.Uri.Info)."
        throw
    }
    finally {
        try {
            if (-not $RequestCompleted -and $null -ne $httpWebRequest) {
                $httpWebRequest.Abort()
            }
            if ($null -ne $streamReader) {
                $streamReader.Dispose()
            }
            elseif ($null -ne $responseStream) {
                $responseStream.Dispose()
            }
        }
        finally {
            if ($null -ne $webResponse) {
                $webResponse.Dispose()
            }
        }
    }
}
