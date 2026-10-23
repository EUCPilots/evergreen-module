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
        [ValidateRange(0, [System.Int32]::MaxValue)]
        [System.Int32] $MaximumRedirection = 0,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable] $Headers
    )

    if ($PSBoundParameters.ContainsKey("Verbose")) {
        $ProgressPreference = "Continue"
    }
    else {
        $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
    }

    $HeaderCount = 0
    if ($PSBoundParameters.ContainsKey("Headers")) {
        $HeaderCount = $Headers.Count
    }
    $ProxyConfigured = Test-ProxyEnv
    $ProxyCredentialsSupplied = $ProxyConfigured -and (Test-ProxyEnv -Creds)

    Write-Verbose -Message "$($MyInvocation.MyCommand): Request: HEAD [$Uri]; response body will not be downloaded."
    Write-Verbose -Message "$($MyInvocation.MyCommand): Maximum redirects to follow: [$MaximumRedirection]; returns the next Location when the limit is reached."
    Write-Verbose -Message "$($MyInvocation.MyCommand): User agent supplied: [$(-not [System.String]::IsNullOrEmpty($UserAgent))]; custom headers: [$HeaderCount]; proxy configured: [$ProxyConfigured]; proxy credentials supplied: [$ProxyCredentialsSupplied]."
    if ($MaximumRedirection -eq 0) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Redirect targets will not be requested."
    }

    $Response = $null
    $Request = $null
    $Client = $null
    $Handler = $null
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Add-Type -AssemblyName "System.Net.Http"
        $Handler = [System.Net.Http.HttpClientHandler]::new()
        $Handler.AllowAutoRedirect = $false
        if ($ProxyConfigured) {
            $Handler.Proxy = [System.Net.WebProxy]::new([System.Uri]$script:EvergreenProxy)
            if ($ProxyCredentialsSupplied) {
                $Handler.Proxy.Credentials = $script:EvergreenProxyCreds.GetNetworkCredential()
            }
        }
        $Client = [System.Net.Http.HttpClient]::new($Handler)

        $CurrentUri = [System.Uri]$Uri
        $Method = [System.Net.Http.HttpMethod]::Head
        $RedirectCount = 0
        $IncludeAuthorization = $true
        $ResolvedUri = $null

        while ($null -eq $ResolvedUri) {
            $Request = [System.Net.Http.HttpRequestMessage]::new($Method, $CurrentUri)
            if (-not [System.String]::IsNullOrEmpty($UserAgent)) {
                $null = $Request.Headers.TryAddWithoutValidation("User-Agent", $UserAgent)
            }
            if ($PSBoundParameters.ContainsKey("Headers")) {
                foreach ($Header in $Headers.GetEnumerator()) {
                    if (-not $IncludeAuthorization -and $Header.Key -eq "Authorization") {
                        continue
                    }
                    if ($Header.Key -ieq "User-Agent" -and -not [System.String]::IsNullOrEmpty($UserAgent)) {
                        continue
                    }
                    if (-not $Request.Headers.TryAddWithoutValidation($Header.Key, [System.String[]]$Header.Value)) {
                        throw "Cannot add request header '$($Header.Key)'."
                    }
                }
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Request: $($Method.Method.ToUpperInvariant()) [$($CurrentUri.AbsoluteUri)]; response body will not be read."
            $Response = $Client.SendAsync($Request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()

            if ($Method -eq [System.Net.Http.HttpMethod]::Head -and [int]$Response.StatusCode -eq 405) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): HEAD rejected with HTTP [405]; retrying with GET using headers-only completion."
                $Response.Dispose()
                $Response = $null
                $Request.Dispose()
                $Request = $null
                $Method = [System.Net.Http.HttpMethod]::Get
                continue
            }

            if ([int]$Response.StatusCode -in @(301, 302, 303, 307, 308)) {
                if ($null -eq $Response.Headers.Location) {
                    throw "Redirect response from '$CurrentUri' did not include a Location header."
                }

                $NextUri = [System.Uri]::new($CurrentUri, [System.String]$Response.Headers.Location)
                Write-Verbose -Message "$($MyInvocation.MyCommand): Response: HTTP [$([int]$Response.StatusCode)] from [$($CurrentUri.AbsoluteUri)]."
                if ($RedirectCount -ge $MaximumRedirection) {
                    $ResolvedUri = $NextUri
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Returning redirect target without requesting it: [$($ResolvedUri.AbsoluteUri)]."
                }
                else {
                    if ($NextUri.Authority -ne $CurrentUri.Authority -or $NextUri.Scheme -ne $CurrentUri.Scheme) {
                        $IncludeAuthorization = $false
                    }
                    $RedirectCount++
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Following redirect [$RedirectCount/$MaximumRedirection] to [$($NextUri.AbsoluteUri)]."
                    $CurrentUri = $NextUri
                }

                $Response.Dispose()
                $Response = $null
                $Request.Dispose()
                $Request = $null
                continue
            }

            $null = $Response.EnsureSuccessStatusCode()
            Write-Verbose -Message "$($MyInvocation.MyCommand): Response: HTTP [$([int]$Response.StatusCode)] from [$($CurrentUri.AbsoluteUri)]."
            $ResolvedUri = $CurrentUri
            $Response.Dispose()
            $Response = $null
            $Request.Dispose()
            $Request = $null
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolved to: [$($ResolvedUri.AbsoluteUri)]."
        Write-Output -InputObject $ResolvedUri.AbsoluteUri
    }
    catch {
        if ($null -ne $Response) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Resolution failed: HTTP [$([int]$Response.StatusCode)]."
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
        if ($null -ne $Response) {
            $Response.Dispose()
        }
        if ($null -ne $Request) {
            $Request.Dispose()
        }
        if ($null -ne $Client) {
            $Client.Dispose()
        }
        elseif ($null -ne $Handler) {
            $Handler.Dispose()
        }
    }
}
