Function Invoke-SystemNetRequest {
    <#
        .SYNOPSIS
            Uses System.Net.WebRequest to make a HTTP request and returns the response.
    #>
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $False)]
    param (
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.String] $UserAgent = $script:UserAgent,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Int32] $MaximumRedirection = 3
    )

    try {
        $httpWebRequest = [System.Net.WebRequest]::Create($Uri)
        $httpWebRequest.UserAgent = $UserAgent
        $httpWebRequest.MaximumAutomaticRedirections = $MaximumRedirection
        $httpWebRequest.AllowAutoRedirect = $true

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
        $responseStream = $webResponse.GetResponseStream()

        $streamReader = New-Object -TypeName "System.IO.StreamReader" $responseStream
        $result = $streamReader.ReadToEnd()
        Write-Output -InputObject $result
    }
    catch [System.Exception] {
        Write-Warning -Message "$($MyInvocation.MyCommand): $($_.Exception.Message), with: $Uri."
        Write-Warning -Message "$($MyInvocation.MyCommand): For troubleshooting steps see: $($script:resourceStrings.Uri.Info)."
        throw $_
    }
    finally {
        $webResponse.Dispose()
    }
}
