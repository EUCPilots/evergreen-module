function Resolve-SystemNetWebRequest {
    <#
        .SYNOPSIS
            Resolve a URL and return response metadata without reading the response body.

        .DESCRIPTION
            Follows redirects and returns response metadata, including ResponseUri.
            Uses HEAD first and retries with GET only for HTTP 405 responses.
            The GET request is aborted after receiving headers, without reading the body.
            Some body bytes may still arrive in network buffers during a GET request.
            Verbose output includes request settings, response status and elapsed time.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Position = 1)]
        [System.String] $UserAgent = (Get-EvergreenUserAgent),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Int32] $MaximumRedirection = 3
    )

    $webResponse = $null
    $httpWebRequest = $null
    $ProxyObj = $null
    $Method = "HEAD"
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        do {
            $httpWebRequest = [System.Net.WebRequest]::Create($Uri)
            $httpWebRequest.Method = $Method
            $httpWebRequest.MaximumAutomaticRedirections = $MaximumRedirection
            $httpWebRequest.AllowAutoRedirect = $true

            # Don't add a UserAgent if it's not provided
            if ([System.String]::IsNullOrEmpty($UserAgent)) {}
            else {
                $httpWebRequest.UserAgent = $UserAgent
            }

            if (Test-ProxyEnv) {
                $ProxyObj = New-Object -TypeName "System.Net.WebProxy"
                $ProxyObj.Address = $script:EvergreenProxy
                $ProxyObj.UseDefaultCredentials = $true
                $httpWebRequest.Proxy = $ProxyObj

                if (Test-ProxyEnv -Creds) {
                    $ProxyObj.UseDefaultCredentials = $false
                    $ProxyObj.Credentials = $script:EvergreenProxyCreds
                    $httpWebRequest.UseDefaultCredentials = $false
                    $httpWebRequest.Proxy = $ProxyObj
                }
            }
            else {
                $httpWebRequest.UseDefaultCredentials = $true
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Request: $Method [$Uri]; response body will not be read."
            Write-Verbose -Message "$($MyInvocation.MyCommand): Maximum automatic redirects: [$MaximumRedirection]; follows redirects to the final response."
            Write-Verbose -Message "$($MyInvocation.MyCommand): User agent supplied: [$(-not [System.String]::IsNullOrEmpty($UserAgent))]; proxy configured: [$($null -ne $ProxyObj)]."
            Write-Verbose -Message "$($MyInvocation.MyCommand): Waiting for response headers; request timeout: [$($httpWebRequest.Timeout)] ms."
            try {
                $webResponse = $httpWebRequest.GetResponse()
            }
            catch {
                $RequestException = $_.Exception
                while ($RequestException -isnot [System.Net.WebException] -and $null -ne $RequestException.InnerException) {
                    $RequestException = $RequestException.InnerException
                }
                if ($RequestException -is [System.Net.WebException]) {
                    $webResponse = $RequestException.Response
                }
                if ($Method -ne "HEAD" -or $null -eq $webResponse -or [int]$webResponse.StatusCode -ne 405) {
                    throw
                }
                Write-Verbose -Message "$($MyInvocation.MyCommand): HEAD rejected with HTTP [405]; retrying with GET and aborting after response headers."
                $httpWebRequest.Abort()
                $webResponse.Dispose()
                $webResponse = $null
                $Method = "GET"
            }
        } while ($null -eq $webResponse)
        Write-Verbose -Message "$($MyInvocation.MyCommand): Response: HTTP [$([int]$webResponse.StatusCode)] from [$($webResponse.ResponseUri.AbsoluteUri)]."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Advertised Content-Length: [$($webResponse.ContentLength)] bytes (-1 means unknown); this is not bytes downloaded."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolved to: [$($webResponse.ResponseUri.AbsoluteUri)]."

        # Construct the output; Return the custom object to the pipeline
        $PSObject = [PSCustomObject] @{
            LastModified  = $webResponse.LastModified
            ContentLength = $webResponse.ContentLength
            Headers       = $webResponse.Headers
            ResponseUri   = $webResponse.ResponseUri
            StatusCode    = $webResponse.StatusCode
        }
        if ($Method -eq "GET") {
            # Abort before disposal to avoid draining the unread response body.
            $httpWebRequest.Abort()
            Write-Verbose -Message "$($MyInvocation.MyCommand): GET aborted after headers; response body was not read."
        }
        Write-Output -InputObject $PSObject
    }
    catch {
        $ErrorResponse = $webResponse
        if ($null -ne $ErrorResponse) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Resolution failed: HTTP [$([int]$ErrorResponse.StatusCode)]."
        }
        else {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Resolution failed before an HTTP response was received."
        }
        Write-Warning -Message "$($MyInvocation.MyCommand): Return code: [$($webResponse.StatusCode)], with: $Uri."
        Write-Warning -Message "$($MyInvocation.MyCommand): For troubleshooting steps see: $($script:resourceStrings.Uri.Info)."
        throw $_
    }
    finally {
        $Timer.Stop()
        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolution finished in [$($Timer.ElapsedMilliseconds)] ms."
        if ($null -ne $httpWebRequest) {
            $httpWebRequest.Abort()
        }
        if ($null -ne $webResponse) {
            $webResponse.Dispose()
        }
    }
}
