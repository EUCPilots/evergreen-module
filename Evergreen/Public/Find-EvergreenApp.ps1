function Find-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    [Alias("fea")]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Specify an a string to search from the list of supported applications.")]
        [ValidateNotNull()]
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
        #endregion
    }

    process {
        if ($PSBoundParameters.ContainsKey('Name')) {
            # If the -Name parameter is specified, filter the included manifests for that application
            Write-Verbose -Message "Filter for: $Name."
            $Manifests = $Manifests | Where-Object { $_.Name -match $Name }
            if ($null -eq $Manifests) {
                Write-Warning -Message "Omit the -Name parameter to return the full list of supported applications."
                Write-Warning -Message "Documentation on how to contribute a new application to the Evergreen project can be found at: $($script:resourceStrings.Uri.Docs)."
                throw "Cannot find application: $Name."
            }
        }

        #region Output details from the manifest/s
        foreach ($manifest in $Manifests) {
            # Read the JSON manifest and convert to an object
            $Json = Get-Content -Path $manifest.FullName | ConvertFrom-Json

            # Build an object from the manifest details and file name and output to the pipeline
            if ($null -ne $Json) {
                $PSObject = [PSCustomObject] @{
                    Name        = [System.IO.Path]::GetFileNameWithoutExtension($manifest.Name)
                    Application = $Json.Name
                    Link        = $Json.Source
                }
                Write-Output -InputObject $PSObject
            }
        }
        #endregion
    }

    end {
        # Remove these variables for next run
        Remove-Variable -Name "PSObject", "Json", "Manifests" -ErrorAction "SilentlyContinue"
    }
}
