function Get-RepoResponse {
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Object[]] $Response,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $RequiredProperties
    )

    if ($null -eq $Response -or $Response.Count -eq 0) {
        throw "Get-RepoResponse: The repository API returned no releases or tags."
    }
    foreach ($Item in $Response) {
        if ($null -eq $Item) {
            throw "Get-RepoResponse: The repository API returned a null release or tag."
        }
        $MissingProperties = @($RequiredProperties | Where-Object { $_ -notin $Item.PSObject.Properties.Name })
        if ($MissingProperties.Count -gt 0) {
            throw [System.Management.Automation.ValidationMetadataException]::New("Get-RepoResponse: Required properties missing: $($MissingProperties -join ', ').")
        }
    }
    Write-Output -InputObject $Response -NoEnumerate
}
