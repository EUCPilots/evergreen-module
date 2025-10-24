function Get-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias("gea")]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify an application name. Use Find-EvergreenApp to list supported applications.")]
        [ValidateNotNull()]
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
        if ($PSBoundParameters.ContainsKey("Proxy")) {
            Set-ProxyEnv -Proxy $Proxy

            if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                Set-ProxyEnv -ProxyCredential $ProxyCredential
            }
        }

        # Force Invoke-EvergreenRestMethod and Invoke-EvergreenWebRequest to ignore certificate errors
        if ($PSBoundParameters.ContainsKey("SkipCertificateCheck")) {
            $script:SkipCertificateCheck = $true
        }
    }

    process {
        # Build a path to the application function
        # This will build a path like: %LocalAppData%\Evergreen\Apps\Get-TeamViewer.ps1
        $FunctionPath = [System.IO.Path]::Combine((Get-EvergreenAppsPath), "Apps", "Get-$Name.ps1")
        Write-Verbose -Message "Function path: $FunctionPath"

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
                throw $_
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
                $Output = & Get-$Name @params

                # Sort the output
                $FilterPath = [System.IO.Path]::Combine((Get-EvergreenAppsPath), "Filters", "$Name.json")
                if (Test-Path -Path $FilterPath -PathType "Leaf") {
                    $FilteredOutput = Get-FilteredData -InputObject $Output -FilterPath $FilterPath
                    $FilteredOutput | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true }, "Ring", "Channel", "Track" -ErrorAction "SilentlyContinue"
                    Remove-Variable -Name Output -Force -ErrorAction "SilentlyContinue"
                }
                else {
                    $Output | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true }, "Ring", "Channel", "Track" -ErrorAction "SilentlyContinue"
                    Remove-Variable -Name Output -Force -ErrorAction "SilentlyContinue"
                }
            }
            catch {
                $Msg = "Run 'Get-EvergreenApp -Name `"$Name`" -Verbose' to review additional details for troubleshooting."
                Write-Warning -Message $Msg
                throw $_
            }
            finally {
                if ($PSBoundParameters.ContainsKey("Proxy")) {
                    Remove-ProxyEnv
                }
            }
        }
        else {
            Write-Warning -Message "Run 'Update-Evergreen' to update the list of supported applications."
            Write-Information -MessageData "`nPlease list supported application names with Find-EvergreenApp." -InformationAction "Continue"
            Write-Information -MessageData "Find out how to contribute a new application to the Evergreen project at: $($script:resourceStrings.Uri.Docs)." -InformationAction "Continue"
            try {
                $List = Find-EvergreenApp -Name $Name -ErrorAction "SilentlyContinue" -WarningAction "SilentlyContinue"
                $AppList = ($List | Select-Object -ExpandProperty "Name") -join "`n"
            }
            catch {
                $AppList = "No applications match '$Name'"
            }
            Write-Information -MessageData "`n'$Name' not found. Evergreen supports these similar applications:" -InformationAction "Continue"
            Write-Information -MessageData $AppList -InformationAction "Continue"
            Write-Information -MessageData "" -InformationAction "Continue"
            $Msg = "Failed to retrieve manifest for application: $Name at '$FunctionPath'."
            throw [System.IO.FileNotFoundException]::New($Msg)
        }
        #endregion
    }

    end {
        # Remove these variables for next run
        Remove-Variable -Name "Output", "function" -ErrorAction "SilentlyContinue"
        if ($PSBoundParameters.ContainsKey("SkipCertificateCheck")) {
            $script:SkipCertificateCheck = $false
        }
    }
}
