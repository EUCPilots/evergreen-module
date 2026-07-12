function Get-VersionItemSortData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSObject] $Item,

        [Parameter(Mandatory = $true)]
        [System.Int32] $Index
    )

    $ParsedVersion = $null
    if (-not [System.String]::IsNullOrEmpty($Item.Version)) {
        try {
            $ParsedVersion = [System.Version]::Parse([System.String] $Item.Version)
        }
        catch {
        }
    }

    [PSCustomObject] @{
        Item             = $Item
        Index            = $Index
        ParsedVersion    = $ParsedVersion
        VersionText      = [System.String] $Item.Version
        HasParsedVersion = [System.Boolean] ($null -ne $ParsedVersion)
    }
}