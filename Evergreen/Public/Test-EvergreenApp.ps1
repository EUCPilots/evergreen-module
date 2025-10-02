function Test-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Path")]
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
        [System.String] $UserAgent = $script:UserAgent,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $Force,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $NoProgress
    )

    begin {
        # Disable the Invoke-WebRequest progress bar for faster downloads
        if ($PSBoundParameters.ContainsKey("Verbose") -and !($PSBoundParameters.ContainsKey("NoProgress"))) {
            $ProgressPreference = [System.Management.Automation.ActionPreference]::Continue
        }
        else {
            $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        }

        # Enable TLS 1.2
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    }

    process {
        # Loop through each object and download to the target path
        foreach ($Object in $InputObject) {

            #region Validate the URI property and find the output filename
            if ([System.Boolean]($Object.URI)) {
            }
            else {
                throw "Object does not have valid URI property."
            }
            #endregion

            try {
                $params = @{
                    Uri             = $Object.URI
                    Method          = "HEAD"
                    UseBasicParsing = $true
                    UserAgent       = $UserAgent
                    ErrorAction     = "SilentlyContinue"
                }
                if ($PSBoundParameters.ContainsKey("Proxy")) {
                    $params.Proxy = $Proxy
                }
                if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                    $params.ProxyCredential = $ProxyCredential
                }
                $Result = $true
                Invoke-WebRequest @params | Out-Null
            }
            catch [System.Exception] {
                $Result = $false
            }
            $PSObject = [PSCustomObject] @{
                Result = $Result
                URI    = $Object.URI
            }
            Write-Output -InputObject $PSObject
        }
    }

    end {
        if ($PSCmdlet.ShouldProcess("Remove variables")) {
            if (Test-Path -Path Variable:params) { Remove-Variable -Name "params" -ErrorAction "SilentlyContinue" }
            Remove-Variable -Name "OutPath", "OutFile" -ErrorAction "SilentlyContinue"
        }
    }
}
