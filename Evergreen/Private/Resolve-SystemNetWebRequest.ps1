function Resolve-SystemNetWebRequest {
    <#
        .SYNOPSIS
            Resolve a URL that returns a 301/302 response and returns the redirected URL
            Uses System.Net.WebRequest to find 301/302 headers and return the ResponseUri
    #>
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Position = 1)]
        [System.String] $UserAgent = $script:UserAgent,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Int32] $MaximumRedirection = 3
    )

    try {
        $httpWebRequest = [System.Net.WebRequest]::Create($Uri)
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
                $httpWebRequest.Credentials = $script:EvergreenProxyCreds
            }
        }
        else {
            $httpWebRequest.UseDefaultCredentials = $true
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand): Attempting to resolve: $Uri."
        $webResponse = $httpWebRequest.GetResponse()
        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolved to: [$($webResponse.ResponseUri.AbsoluteUri)]."

        # Construct the output; Return the custom object to the pipeline
        $PSObject = [PSCustomObject] @{
            LastModified  = $webResponse.LastModified
            ContentLength = $webResponse.ContentLength
            Headers       = $webResponse.Headers
            ResponseUri   = $webResponse.ResponseUri
            StatusCode    = $webResponse.StatusCode
        }
        Write-Output -InputObject $PSObject
    }
    catch {
        Write-Warning -Message "$($MyInvocation.MyCommand): Return code: [$($webResponse.StatusCode)], with: $Uri."
        Write-Warning -Message "$($MyInvocation.MyCommand): For troubleshooting steps see: $($script:resourceStrings.Uri.Info)."
        throw $_
    }
    finally {
        $webResponse.Dispose()
    }
}
