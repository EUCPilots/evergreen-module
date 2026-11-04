<#
    .SYNOPSIS
    Export application details gathered by Get-EvergreenApp to an external JSON file.
    Reads any existing JSON for that application, adds the new version content, sorts for unique versions,
    then outputs the new content back to the target JSON file.
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param (
    [Parameter(
        Mandatory = $false,
        Position = 0,
        ValueFromPipeline,
        HelpMessage = "An application name supported by Evergreen.")]
    [ValidateNotNull()]
    [System.String[]] $Name = "MicrosoftEdge",

    [Parameter(
        Mandatory = $false,
        Position = 1,
        ValueFromPipelineByPropertyName,
        HelpMessage = "Specify a top-level directory path where the application JSON file will be saved into.",
        ParameterSetName = "Path")]
    [System.IO.FileInfo] $Path = $PWD.Path
)

begin {}

process {
    foreach ($Item in $Name) {

        try {
            $params = @{
                Name    = $Item
                Verbose = $VerbosePreference
            }
            Find-EvergreenApp @params | Out-Null
        }
        catch {
            throw $_.Exception.Message
        }

        # Create the export file path
        Write-Verbose -Message "App: $Item."
        $FilePath = Join-Path -Path $Path -ChildPath "$Item.json"
        Write-Verbose -Message "Save to file path: $FilePath."

        # Gather the application version details
        try {
            $params = @{
                Name          = $Item
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
                Verbose       = $VerbosePreference
            }
            $App = Get-EvergreenApp @params
        }
        catch {
            throw $_.Exception.Message
        }

        # If we returned data
        if ($Null -ne $App) {

            # Add the new details to the existing file content
            if (Test-Path -Path $FilePath) {
                $Content = Get-Content -Path $FilePath -Verbose:$VerbosePreference | ConvertFrom-Json
                $App += $Content
            }

            # Sort the content and keep unique versions
            $Properties = $App | Get-Member | `
                Where-Object { $_.MemberType -eq "NoteProperty" } | Select-Object -ExpandProperty "Name" | `
                Sort-Object -Descending
            $App = $App | Select-Object -Unique -Property $Properties

            # Export the data to file
            $App | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $false } | `
                ConvertTo-Json | `
                Out-File -FilePath $FilePath -Encoding "Utf8" -NoNewline -Verbose:$VerbosePreference
        }
    }
}

end {}
