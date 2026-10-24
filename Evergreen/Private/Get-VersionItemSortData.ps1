function Get-VersionItemSortData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSObject] $Item,

        [Parameter(Mandatory = $true)]
        [System.Int32] $Index
    )

    $VersionText = [System.String] $Item.Version
    $ParsedVersion = $null
    if (-not [System.String]::IsNullOrEmpty($VersionText)) {
        $Version = [System.Version]::MinValue
        if ([System.Version]::TryParse($VersionText, [ref] $Version)) {
            $ParsedVersion = $Version
        }
    }

    [PSCustomObject] @{
        Item             = $Item
        Index            = $Index
        ParsedVersion    = $ParsedVersion
        VersionText      = $VersionText
        HasParsedVersion = [System.Boolean] ($null -ne $ParsedVersion)
    }
}