function Save-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Path")]
    [Alias("sea")]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Pass an application object from Get-EvergreenApp.")]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject] $InputObject,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify a top-level directory path where the application installers will be saved into.",
            ParameterSetName = "Path")]
        [System.IO.FileInfo] $Path,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify a single directory path where all application installers will be saved into.",
            ParameterSetName = "CustomPath")]
        [Alias("LiteralPath")]
        [System.IO.FileInfo] $CustomPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [System.String] $Proxy,

        [Parameter(Mandatory = $false, Position = 3)]
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

        # Path variable from parameters set via -Path or -CustomPath
        switch ($PSCmdlet.ParameterSetName) {
            "Path" {
                if ([System.String]::IsNullOrEmpty($Path)) { throw "Cannot bind argument to parameter 'Path' because it is null." }
                $NewPath = $Path
            }
            "CustomPath" {
                if ([System.String]::IsNullOrEmpty($CustomPath)) { throw "Cannot bind argument to parameter 'CustomPath' because it is null." }
                $NewPath = $CustomPath
            }
        }

        #region Test $Path and attempt to create it if it doesn't exist
        if (Test-Path -Path $NewPath -PathType "Container") {
            Write-Verbose -Message "Path exists: $NewPath."
        }
        else {
            Write-Verbose -Message "Path does not exist: $NewPath."
            Write-Verbose -Message "Create: $NewPath."
            $params = @{
                Path        = $NewPath
                ItemType    = "Container"
                ErrorAction = "Stop"
            }
            New-Item @params | Out-Null
        }
        #endregion

        # Enable TLS 1.2
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    }

    process {
        # Loop through each object and download to the target path
        foreach ($Object in $InputObject) {

            #region Validate the URI property and find the output filename
            if ([System.Boolean]($Object.URI)) {
                Write-Verbose -Message "URL: $($Object.URI)."
                if ([System.Boolean]($Object.FileName)) {
                    $OutFile = $Object.FileName
                }
                elseif ([System.Boolean]($Object.URI)) {
                    $OutFile = Split-Path -Path $Object.URI -Leaf
                }
            }
            else {
                throw [System.Management.Automation.PropertyNotFoundException] "InputObject does not have valid URI property."
            }
            #endregion

            # Handle the output path depending on whether -Path or -CustomPath are used
            switch ($PSCmdlet.ParameterSetName) {
                "Path" {
                    # Resolve $Path to build the initial value of $OutPath
                    $OutPath = Resolve-Path -Path $Path -ErrorAction "SilentlyContinue"
                    if ($null -ne $OutPath) {

                        #region Validate the Version property
                        if ([System.Boolean]($Object.Version)) {

                            # Build $OutPath with the "Channel", "Release", "Language", "Architecture" properties
                            $OutPath = New-EvergreenPath -InputObject $Object -Path $OutPath
                        }
                        else {
                            throw [System.Management.Automation.PropertyNotFoundException] "InputObject does not have valid Version property."
                        }
                        #endregion
                    }
                    else {
                        throw [System.IO.DirectoryNotFoundException] "Failed validating $OutPath."
                    }
                }
                "CustomPath" {
                    $OutPath = Resolve-Path -Path $CustomPath -ErrorAction "Stop"
                }
            }

            $DownloadFile = $(Join-Path -Path $OutPath -ChildPath $OutFile)
            if ($PSBoundParameters.ContainsKey("Force") -or !(Test-Path -Path $DownloadFile -PathType "Leaf")) {
                #region Download the file
                # If URL in the catch list, customise the user agent
                # if ($Object.URI -match $script:resourceStrings.UserAgent.CatchList -and -not($PSBoundParameters.ContainsKey("UserAgent"))) {
                #     Write-Verbose -Message "URL matches catch list for custom user agent: $($Object.URI)."
                #     $UserAgent = $script:UserAgent
                # }

                # Invoke-WebRequest parameters
                $params = @{
                    Uri             = $Object.URI
                    OutFile         = $DownloadFile
                    UseBasicParsing = $true
                    UserAgent       = $script:UserAgent
                    ErrorAction     = "Continue"
                }
                if ($PSBoundParameters.ContainsKey("Proxy")) {
                    $params.Proxy = $Proxy
                }
                if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                    $params.ProxyCredential = $ProxyCredential
                }
                # Output the parameters when using -Verbose
                foreach ($item in $params.GetEnumerator()) {
                    Write-Verbose -Message "Invoke-WebRequest parameter: $($item.name): $($item.value)."
                }
                # Download the file
                if ($PSCmdlet.ShouldProcess($Object.URI, "Download")) {
                    Invoke-WebRequest @params
                }
                #endregion
                # Write the downloaded file path to the pipeline
                if (Test-Path -Path $DownloadFile) {
                    Write-Verbose -Message "Successfully downloaded: $DownloadFile."
                    Write-Output -InputObject $(Get-ChildItem -Path $DownloadFile)
                }
            }
            else {
                #region Write the downloaded file path to the pipeline
                if (Test-Path -Path $DownloadFile) {
                    Write-Verbose -Message "File exists: $DownloadFile."
                    Write-Output -InputObject $(Get-ChildItem -Path $DownloadFile)
                }
                #endregion
            }
        }
    }

    end {
        Write-Verbose -Message "Complete."
        if ($PSCmdlet.ShouldProcess("Remove variables")) {
            if (Test-Path -Path Variable:params) { Remove-Variable -Name "params" -ErrorAction "SilentlyContinue" }
            Remove-Variable -Name "OutPath", "OutFile" -ErrorAction "SilentlyContinue"
        }
    }
}
