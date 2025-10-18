function Get-EvergreenEndpointFromApi {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    [Alias("Get-EvergreenEndpoint")]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("ApplicationName")]
        [System.String[]] $Name
    )

    begin {
        # Get the endpoints for updates/versions source URLs
        $params = @{
            Uri         = "https://evergreen-api.stealthpuppy.com/endpoints/versions"
            ErrorAction = "Stop"
        }
        $Versions = Invoke-EvergreenRestMethod @params

        # Get the endpoints from the download URLs
        $params = @{
            Uri         = "https://evergreen-api.stealthpuppy.com/endpoints/downloads"
            ErrorAction = "Stop"
        }
        $Downloads = Invoke-EvergreenRestMethod @params
    }
    process {
        # Output the endpoints by joining the two queries
        $Endpoints = $Versions | ForEach-Object {
            $Application = $_.Application
            [PSCustomObject]@{
                Application = $Application
                Endpoints   = @(($_.Endpoints + ($Downloads | Where-Object { $_.Application -eq $Application }).Endpoints) | Select-Object -Unique)
                Ports       = @(($_.Ports + ($Downloads | Where-Object { $_.Application -eq $Application }).Ports) | Select-Object -Unique)
            }
        }

        # Filter output if the Name parameter was specified
        if ($PSBoundParameters.ContainsKey("Name")) {
            $FilteredEndpoints = $Endpoints | Where-Object { $_.Application -in $Name }
            if ($FilteredEndpoints) {
                Write-Output -InputObject $FilteredEndpoints
            }
            else {
                throw "No endpoints found for application(s): $($Name -join ', ')."
            }
        }
        else {
            Write-Output -InputObject $Endpoints
        }
    }
}
