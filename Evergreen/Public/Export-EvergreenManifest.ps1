function Export-EvergreenManifest {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Collections.IDictionary])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify an application name. Use Find-EvergreenApp to list supported applications.")]
        [ValidateNotNullOrEmpty()]
        [Alias("ApplicationName")]
        [System.String] $Name
    )

    process {
        try {
            Get-FunctionResource -AppName $Name
        }
        catch [System.IO.FileNotFoundException] {
            # The manifest does not exist - help the user find a supported application name
            Write-AppNotFoundHelp -Name $Name
            $PSCmdlet.ThrowTerminatingError($_)
        }
        catch {
            # Any other failure (e.g. a corrupt manifest) - re-throw to preserve the original error record
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
