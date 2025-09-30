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
            Invoke-EvergreenRestMethod @params
        }
        catch {
            throw $_
        }
    }
}
