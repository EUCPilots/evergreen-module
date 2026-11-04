function Get-EvergreenAppFromLibrary {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [Alias("Get-EvergreenLibraryApp")]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Pass the output from Get-EvergreenLibrary.")]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $Inventory,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify an application name. Use Find-EvergreenApp to list supported applications.")]
        [ValidateNotNullOrEmpty()]
        [Alias("ApplicationName")]
        [System.String] $Name
    )

    process {
        # Validate $Inventory has the required properties
        if ($null -eq $Inventory.PSObject.Properties["Inventory"]) {
            throw [System.Management.Automation.PropertyNotFoundException] "Inventory does not have valid Inventory property."
        }
        Write-Verbose -Message "Input object has the required Inventory property."

        # Filter the library inventory and match against $Name
        $Application = $Inventory.Inventory | Where-Object { $_.ApplicationName -eq $Name }
        if ($null -ne $Application) {
            Write-Verbose -Message "Filtering library inventory for '$Name'"
            $Versions = @($Application | ForEach-Object {
                    if ($null -ne $_.Versions) {
                        $_.Versions
                    }
                })
            $ItemsWithSortData = for ($Index = 0; $Index -lt $Versions.Count; $Index++) {
                Get-VersionItemSortData -Item $Versions[$Index] -Index $Index
            }
            $SortedVersions = $ItemsWithSortData | Sort-Object -Property `
                @{ Expression = { $_.HasParsedVersion }; Descending = $true }, `
                @{ Expression = { $_.ParsedVersion }; Descending = $true }, `
                @{ Expression = { $_.VersionText }; Descending = $true }, `
                @{ Expression = { $_.Index }; Descending = $true }
            Write-Output -InputObject ($SortedVersions | Select-Object -ExpandProperty "Item")
        }
        else {
            Write-Error -Message "Cannot find an application in the library that matches '$Name'"
        }
    }
}
