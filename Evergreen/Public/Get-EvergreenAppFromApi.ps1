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
                    Write-Verbose -Message "Applying output filter from path: $FilterPath"
                    $Output | ForEach-Object {
                        Get-FilteredData -InputObject $_ -FilterPath $FilterPath
                    }
                    Remove-Variable -Name Output -Force -ErrorAction "SilentlyContinue"
                }
                else {
                    $Output
                }
        }
        catch {
            throw $_
        }
    }
}
