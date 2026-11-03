function Get-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    [Alias("gea")]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify an application name. Use Find-EvergreenApp to list supported applications.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($_) -or $_ -match '[\\/]' -or [System.IO.Path]::GetFileName($_) -cne $_ -or $_ -in @(".", "..")) {
                throw "Name must be an application name, not a path or wildcard pattern."
            }
            if ($_ -match '[<>:"|\x00-\x1F]') {
                throw "Name contains characters that are not valid in an application name."
            }
            $true
        })]
        [Alias("ApplicationName")]
        [System.String] $Name = "Microsoft365Apps",

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Specify a hashtable of parameters to pass to the internal application function.")]
        [System.Collections.Hashtable] $AppParams,

        [Parameter(Mandatory = $false, Position = 2)]
        [System.String] $Proxy,

        [Parameter(Mandatory = $false, Position = 3)]
        [System.Management.Automation.PSCredential]
        $ProxyCredential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $SkipCertificateCheck
    )

    begin {
        if ($PSBoundParameters.ContainsKey("ProxyCredential") -and -not($PSBoundParameters.ContainsKey("Proxy"))) {
            throw [System.ArgumentException]::New("ProxyCredential requires Proxy.")
        }

        # 'res' is reserved for the application manifest passed to the application function
        if ($PSBoundParameters.ContainsKey("AppParams") -and $AppParams.ContainsKey("res")) {
            throw [System.ArgumentException]::New("AppParams must not include the reserved key 'res'.")
        }

        # Set the proxy environment once for all pipeline input; removed in the end block or on a terminating error
        if ($PSBoundParameters.ContainsKey("Proxy")) {
            if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                Set-ProxyEnv -Proxy $Proxy -ProxyCredential $ProxyCredential
            }
            else {
                Set-ProxyEnv -Proxy $Proxy
            }
        }

        # Force Invoke-EvergreenRestMethod and Invoke-EvergreenWebRequest to ignore certificate errors
        if ($SkipCertificateCheck.IsPresent) {
            $script:SkipCertificateCheck = $true
        }
    }

    process {
        # Build a path to the application function
        # This will build a path like: %LocalAppData%\Evergreen\Apps\Get-TeamViewer.ps1
        $FunctionPath = [System.IO.Path]::Combine((Get-EvergreenAppsPath), "Apps", "Get-$Name.ps1")
        Write-Verbose -Message "Function path: $FunctionPath"

        $Completed = $false
        try {
            #region Test that the function exists and run it to return output
            if (Test-Path -Path $FunctionPath -PathType "Leaf" -ErrorAction "SilentlyContinue") {
                Write-Verbose -Message "Function exists: $FunctionPath."

                # Dot source the function so that we can use it
                # Import function here rather than at module import to reduce IO and memory footprint as the module grows
                # This also allows us to add an application manifest and function without having to re-load the module
                Write-Verbose -Message "Dot sourcing: $FunctionPath."
                try {
                    . $FunctionPath
                }
                catch {
                    Write-Warning -Message "Failed to dot source application function from: $FunctionPath."
                    Write-ErrorDetail -ErrorRecord $_ -LastFrame "Get-EvergreenApp"
                    $PSCmdlet.ThrowTerminatingError($_)
                }

                try {
                    # Run the function to grab the application details; pass the per-app manifest to the app function
                    # Application manifests are located under Evergreen/Manifests
                    $params = @{
                        res = (Get-FunctionResource -AppName $Name)
                    }
                    if ($PSBoundParameters.ContainsKey("AppParams")) {
                        Write-Verbose -Message "Adding AppParams."
                        $params += $AppParams
                    }
                    # Run the application function and collect the output
                    Write-Verbose -Message "Calling: Get-$Name."

                    # Sort the output
                    $FilterPath = [System.IO.Path]::Combine((Get-EvergreenAppsPath), "Filters", "$Name.json")
                    if (Test-Path -Path $FilterPath -PathType "Leaf") {
                        Write-Verbose -Message "Applying output filter from path: $FilterPath"
                        & Get-$Name @params | ForEach-Object {
                            Get-FilteredData -InputObject $_ -FilterPath $FilterPath
                        }
                    }
                    else {
                        & Get-$Name @params
                    }
                }
                catch {
                    # Display the function name, script file and line number where the error occurred
                    Write-ErrorDetail -ErrorRecord $_ -LastFrame "Get-EvergreenApp"
                    $Msg = "Run 'Get-EvergreenApp -Name `"$Name`" -Verbose' to review additional details for troubleshooting."
                    Write-Warning -Message $Msg

                    # Re-throw the original error record to preserve its origin (InvocationInfo and stack trace)
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
            else {
                Write-AppNotFoundHelp -Name $Name
                $Msg = "Failed to retrieve manifest for application: $Name at '$FunctionPath'."
                throw [System.IO.FileNotFoundException]::New($Msg)
            }
            #endregion
            $Completed = $true
        }
        finally {
            # The end block does not run when a terminating error stops the pipeline, so clean up here on failure
            if (-not $Completed) {
                if ($PSBoundParameters.ContainsKey("Proxy")) {
                    Remove-ProxyEnv
                }
                if ($SkipCertificateCheck.IsPresent) {
                    $script:SkipCertificateCheck = $false
                }
            }
        }
    }

    end {
        if ($PSBoundParameters.ContainsKey("Proxy")) {
            Remove-ProxyEnv
        }
        if ($SkipCertificateCheck.IsPresent) {
            $script:SkipCertificateCheck = $false
        }
    }
}
