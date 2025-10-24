function Get-EvergreenAppFromApi {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    [Alias("iea", "Invoke-EvergreenApp")]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify an application name. Use Find-EvergreenApp to list supported applications.")]
        [ValidateNotNullOrEmpty()]
        [Alias("ApplicationName")]
        [System.String] $Name = "Microsoft365Apps"
    )

    process {
        try {
            $params = @{
                Uri         = "https://evergreen-api.stealthpuppy.com/app/$Name"
                UserAgent   = $script:UserAgent
                ErrorAction = "Stop"
            }
            $Output = Invoke-EvergreenRestMethod @params

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
            throw $_
        }
    }
}
