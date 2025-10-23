function Remove-EvergreenLibraryItem {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Pass the output from Get-EvergreenLibrary.")]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $Inventory,

        [Parameter(Mandatory = $false, Position = 1)]
        [System.Int32] $Count = 3
    )

    process {
        # Validate $Inventory has the required properties
        if ([System.Boolean]($Inventory.Inventory)) {
            Write-Verbose -Message "Input object has the required Inventory property."
        }
        else {
            throw [System.Management.Automation.PropertyNotFoundException] "Inventory does not have valid Inventory property."
        }

        # Filter the library inventory and match against $Name
        $Application = $Inventory.Inventory | Where-Object { $_.ApplicationName -eq $Name }
        if ($null -ne $Application) {
            Write-Verbose -Message "Filtering library inventory for '$Name'"
            Write-Output -InputObject ($Application.Versions | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } -ErrorAction "SilentlyContinue")
        }
        else {
            Write-Error -Message "Cannot find an application in the library that matches '$Name'"
        }
    }
}
