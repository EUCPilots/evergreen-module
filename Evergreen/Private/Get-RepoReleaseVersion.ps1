function Get-RepoReleaseVersion {
    [OutputType([System.String])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Source,

        [Parameter(Mandatory = $true)]
        [System.String] $MatchVersion,

        [Parameter()]
        [ValidateNotNull()]
        [ValidateCount(2, 2)]
        [System.Array] $VersionReplace
    )

    if ([System.String]::IsNullOrWhiteSpace($Source)) {
        throw "Get-RepoReleaseVersion: The release or tag version is empty."
    }

    $Match = [RegEx]::Match($Source, $MatchVersion)
    $Version = $Source
    if ($Match.Success -and $Match.Groups[1].Success -and -not [System.String]::IsNullOrWhiteSpace($Match.Groups[1].Value)) {
        $Version = $Match.Groups[1].Value
    }
    else {
        Write-Verbose -Message "$($MyInvocation.MyCommand): No captured version found, returning: $Source."
    }

    if ($PSBoundParameters.ContainsKey("VersionReplace")) {
        $Version = $Version -replace $VersionReplace[0], $VersionReplace[1]
    }
    if ([System.String]::IsNullOrWhiteSpace($Version)) {
        throw "Get-RepoReleaseVersion: Version replacement produced an empty version."
    }
    Write-Output -InputObject $Version
}
