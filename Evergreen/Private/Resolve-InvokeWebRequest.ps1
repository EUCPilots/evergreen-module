function Resolve-InvokeWebRequest {
    <#
        .SYNOPSIS
            Resolve a URL without reading the response body.

        .DESCRIPTION
            Returns the next redirect URL when MaximumRedirection is exhausted, or
            the final response URL when no redirects remain. The default of zero
            returns the first redirect target without requesting it.
            Retries HTTP 405 responses with GET using headers-only completion.
            Some body bytes may arrive in network buffers, but the body is not read.
            Verbose output includes request settings, response status and elapsed time.
    #>
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Position = 1)]
        [System.String] $UserAgent = (Get-EvergreenUserAgent),

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.Int32] $MaximumRedirection = 0,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable] $Headers
    )

    # Keep progress output local to this function.
    if ($PSBoundParameters.ContainsKey("Verbose")) {
        $ProgressPreference = "Continue"
    }
    else {
        $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
    }

    $params = @{
        MaximumRedirection = $MaximumRedirection
        Uri                = $Uri
        Method             = "Head"
        UseBasicParsing    = $true
        ErrorAction        = "Stop"
        Verbose            = $false
    }
    if ([System.String]::IsNullOrEmpty($UserAgent)) {}
    else {
        $params.UserAgent = $UserAgent
    }
    $HeaderCount = 0
    if ($PSBoundParameters.ContainsKey("Headers")) {
        $params.Headers = $Headers
        $HeaderCount = $Headers.Count
    }

    if (Test-ProxyEnv) {
        $params.Proxy = $script:EvergreenProxy
    }
    if (Test-ProxyEnv -Creds) {
        $params.ProxyCredential = $script:EvergreenProxyCreds
    }
    Write-Verbose -Message "$($MyInvocation.MyCommand): Request: HEAD [$Uri]; response body will not be downloaded."
    Write-Verbose -Message "$($MyInvocation.MyCommand): Maximum automatic redirects: [$MaximumRedirection]; returns the next Location when the limit is reached."
    Write-Verbose -Message "$($MyInvocation.MyCommand): User agent supplied: [$($params.ContainsKey('UserAgent'))]; custom headers: [$HeaderCount]; proxy configured: [$($params.ContainsKey('Proxy'))]; proxy credentials supplied: [$($params.ContainsKey('ProxyCredential'))]."
    if ($MaximumRedirection -eq 0) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Redirect targets will not be requested."
    }

    $response = $null
    $Client = $null
    $Handler = $null
    $GetRequest = $null
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        try {
            $result = Invoke-WebRequest @params
            $response = $result.BaseResponse
        }
        catch {
            $response = $_.Exception.Response
            if ($null -eq $response -or [int]$response.StatusCode -notin @(301, 302, 303, 307, 308, 405)) {
                throw
            }
        }

        $GetFallback = [int]$response.StatusCode -eq 405
        if ($GetFallback) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): HEAD rejected with HTTP [405]; retrying with GET using headers-only completion."
            $response.Dispose()
            $response = $null
            Add-Type -AssemblyName "System.Net.Http"
            $Handler = [System.Net.Http.HttpClientHandler]::new()
            $Handler.AllowAutoRedirect = $false
            if ($params.ContainsKey("Proxy")) {
                $Proxy = [System.Net.WebProxy]::new($params.Proxy)
                if ($params.ContainsKey("ProxyCredential")) {
                    $Proxy.Credentials = $params.ProxyCredential.GetNetworkCredential()
                }
                $Handler.Proxy = $Proxy
            }
            $Client = [System.Net.Http.HttpClient]::new($Handler)
            $GetUri = [System.Uri]$Uri
            $RedirectCount = 0
            $IncludeAuthorization = $true
            do {
                $GetRequest = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $GetUri)
                if ($params.ContainsKey("UserAgent")) {
                    $null = $GetRequest.Headers.TryAddWithoutValidation("User-Agent", $UserAgent)
                }
                if ($params.ContainsKey("Headers")) {
                    foreach ($Header in $Headers.GetEnumerator() | Where-Object { $IncludeAuthorization -or $_.Key -ne "Authorization" }) {
                        if (-not $GetRequest.Headers.TryAddWithoutValidation($Header.Key, [System.String[]]$Header.Value)) {
                            throw "Cannot add request header '$($Header.Key)' to the GET fallback."
                        }
                    }
                }
                Write-Verbose -Message "$($MyInvocation.MyCommand): Request: GET [$($GetUri.AbsoluteUri)]; response body will not be read."
                $response = $Client.SendAsync($GetRequest, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
                if ([int]$response.StatusCode -notin @(301, 302, 303, 307, 308) -or $RedirectCount -ge $MaximumRedirection) {
                    break
                }
                if ($null -eq $response.Headers.Location) {
                    throw "Redirect response from '$GetUri' did not include a Location header."
                }
                $NextUri = [System.Uri]::new($GetUri, [System.String]$response.Headers.Location)
                if ($NextUri.Authority -ne $GetUri.Authority -or $NextUri.Scheme -ne $GetUri.Scheme) {
                    $IncludeAuthorization = $false
                }
                $GetUri = $NextUri
                $RedirectCount++
                $response.Dispose()
                $response = $null
                $GetRequest.Dispose()
                $GetRequest = $null
            } while ($true)
            if ([int]$response.StatusCode -notin @(301, 302, 303, 307, 308)) {
                $null = $response.EnsureSuccessStatusCode()
            }
        }

        if ($GetFallback -or (Test-PSCore)) {
            $ResponseUri = $response.RequestMessage.RequestUri
            $Location = [System.String]$response.Headers.Location
        }
        else {
            $ResponseUri = $response.ResponseUri
            $Location = $response.Headers["Location"]
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand): Response: HTTP [$([int]$response.StatusCode)] from [$($ResponseUri.AbsoluteUri)]."

        if ([int]$response.StatusCode -in @(301, 302, 303, 307, 308)) {
            if ([System.String]::IsNullOrWhiteSpace($Location)) {
                throw "Redirect response from '$ResponseUri' did not include a Location header."
            }
            $ResponseUri = [System.Uri]::new($ResponseUri, $Location)
            Write-Verbose -Message "$($MyInvocation.MyCommand): Returning redirect target without requesting it: [$($ResponseUri.AbsoluteUri)]."
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolved to: [$($ResponseUri.AbsoluteUri)]."
        Write-Output -InputObject $ResponseUri.AbsoluteUri
    }
    catch {
        if ($null -ne $response) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Resolution failed: HTTP [$([int]$response.StatusCode)]."
        }
        else {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Resolution failed before an HTTP response was received."
        }
        Write-Warning -Message "$($MyInvocation.MyCommand): Failed to resolve: '$Uri'."
        Write-Warning -Message "$($MyInvocation.MyCommand): For troubleshooting steps see: $($script:resourceStrings.Uri.Info)."
        Write-Error -ErrorRecord $_
    }
    finally {
        $Timer.Stop()
        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolution finished in [$($Timer.ElapsedMilliseconds)] ms."
        if ($null -ne $response) {
            $response.Dispose()
        }
        if ($null -ne $GetRequest) {
            $GetRequest.Dispose()
        }
        if ($null -ne $Client) {
            $Client.Dispose()
        }
        elseif ($null -ne $Handler) {
            $Handler.Dispose()
        }
    }
}
