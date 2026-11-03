function Find-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    [Alias("fea")]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Specify a string to search from the list of supported applications.")]
        [ValidateNotNullOrEmpty()]
        [Alias("ApplicationName")]
        [System.String] $Name
    )

    begin {
        #region Get the per-application manifests from the Evergreen/Manifests folder
        $params = @{
            Path        = Join-Path -Path (Get-EvergreenAppsPath) -ChildPath "Manifests"
            Filter      = "*.json"
            ErrorAction = "SilentlyContinue"
        }
        Write-Verbose -Message "Search path for application manifests: $($params.Path)."
        $Manifests = Get-ChildItem @params
        if ($null -eq $Manifests) {
            Write-Warning -Message "No application manifests found at: $($params.Path)."
            Write-Warning -Message "Run 'Update-Evergreen' to update the list of supported applications."
        }
        #endregion
    }

    process {
        # If the -Name parameter is specified, filter the manifests for that application
        # Filter from the original list on each pipeline iteration so that multiple input values work correctly
        if ($PSBoundParameters.ContainsKey('Name')) {
            Write-Verbose -Message "Filter for: $Name."
            $Pattern = [System.Text.RegularExpressions.Regex]::Escape($Name)
            $Filtered = $Manifests | Where-Object { $_.BaseName -match $Pattern }
            if ($null -eq $Filtered) {
                Write-Warning -Message "Omit the -Name parameter to return the full list of supported applications."
                Write-Warning -Message "Documentation on how to contribute a new application to the Evergreen project can be found at: $($script:resourceStrings.Uri.Docs)."
                $ErrorRecord = [System.Management.Automation.ErrorRecord]::New(
                    [System.Management.Automation.ItemNotFoundException]::New("Cannot find application: $Name."),
                    "ApplicationNotFound",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $Name)
                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }
        else {
            $Filtered = $Manifests
        }

        #region Output details from the manifest/s
        foreach ($manifest in $Filtered) {
            try {
                # Read the JSON manifest and convert to an object
                $Json = Get-Content -LiteralPath $manifest.FullName -Raw -Encoding "UTF8" -ErrorAction "Stop" | ConvertFrom-Json -ErrorAction "Stop"

                # Build an object from the manifest details and file name and output to the pipeline
                [PSCustomObject] @{
                    Name        = $manifest.BaseName
                    Application = $Json.Name
                    Link        = $Json.Source
                }
            }
            catch {
                Write-Warning -Message "Failed to read manifest: $($manifest.FullName)."
            }
        }
        #endregion
    }
}
