function Test-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    [Alias("tea")]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Pass an application object from Get-EvergreenApp.")]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject] $InputObject,

        [Parameter(Mandatory = $false, Position = 1)]
        [System.String] $Proxy,

        [Parameter(Mandatory = $false, Position = 2)]
        [System.Management.Automation.PSCredential]
        $ProxyCredential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $UserAgent = (Get-EvergreenUserAgent),

        [Parameter()]
        [ValidateRange(1, 600)]
        [System.Int32] $ConnectionTimeoutSeconds = 30,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $NoProgress
    )

    begin {
        if ($PSBoundParameters.ContainsKey("ProxyCredential") -and -not($PSBoundParameters.ContainsKey("Proxy"))) {
            throw [System.ArgumentException]::New("ProxyCredential requires Proxy.")
        }

        if ($PSBoundParameters.ContainsKey("Verbose") -and -not($NoProgress)) {
            $ProgressPreference = [System.Management.Automation.ActionPreference]::continue
        }
        else {
            $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        }

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    }

    process {
        foreach ($Object in $InputObject) {
            $uriProperty = $Object.PSObject.Properties["URI"]
            if ($null -eq $uriProperty -or [System.String]::IsNullOrWhiteSpace([System.String]$uriProperty.Value)) {
                Write-Warning -Message "InputObject does not have a valid URI property; the object cannot be tested."
                [PSCustomObject]@{
                    Result     = $false
                    StatusCode = $null
                    URI        = $null
                }
                continue
            }

            $uri = [System.String]$uriProperty.Value
            Write-Verbose -Message "Testing URI: $uri."
            $params = @{
                Uri             = $uri
                Method          = "HEAD"
                UseBasicParsing = $true
                UserAgent       = $UserAgent
                TimeoutSec      = $ConnectionTimeoutSeconds
                ErrorAction     = "Stop"
            }
            if ($PSBoundParameters.ContainsKey("Proxy")) {
                $params.Proxy = $Proxy
            }
            if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                $params.ProxyCredential = $ProxyCredential
            }

            $result = $false
            $statusCode = $null
            try {
                $response = Invoke-WebRequest @params
                $result = $true
                if ($null -ne $response.PSObject.Properties["StatusCode"]) {
                    $statusCode = [System.Int32]$response.StatusCode
                }
            }
            catch {
                $headStatusCode = $null
                $errorResponse = $_.Exception.Response
                if ($null -ne $errorResponse -and $null -ne $errorResponse.PSObject.Properties["StatusCode"]) {
                    try {
                        $headStatusCode = [System.Int32]$errorResponse.StatusCode
                    }
                    catch {
                        $headStatusCode = $null
                    }
                }

                $params.Method = "Get"
                $params.Headers = @{ Range = "bytes=0-0" }
                try {
                    $response = Invoke-WebRequest @params
                    $result = $true
                    if ($null -ne $response.PSObject.Properties["StatusCode"]) {
                        $statusCode = [System.Int32]$response.StatusCode
                    }
                }
                catch {
                    $statusCode = $null
                    $errorResponse = $_.Exception.Response
                    if ($null -ne $errorResponse -and $null -ne $errorResponse.PSObject.Properties["StatusCode"]) {
                        try {
                            $statusCode = [System.Int32]$errorResponse.StatusCode
                        }
                        catch {
                            $statusCode = $null
                        }
                    }
                    if ($null -eq $statusCode) {
                        $statusCode = $headStatusCode
                    }
                }
            }

            [PSCustomObject]@{
                Result     = $result
                StatusCode = $statusCode
                URI        = $uri
            }
        }
    }
}
