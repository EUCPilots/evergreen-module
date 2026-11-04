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
        [System.String] $Name = "Microsoft365Apps"
    )

    process {
        $params = @{
            Uri         = "$($script:resourceStrings.Uri.Api)/app/$([System.Uri]::EscapeDataString($Name))"
            ErrorAction = "Stop"
        }
        try {
            # Query the API and standardise the output via the app's filter, if one exists
            Invoke-EvergreenRestMethod @params | Invoke-OutputFilter -Name $Name
        }
        catch {
            # Re-throw the original error record to preserve its origin (InvocationInfo and stack trace)
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
