function Get-ReleaseVersionData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Version] $Version,

        [Parameter(Mandatory)]
        [System.String] $Changelog,

        [System.String] $Root = (Split-Path $PSScriptRoot -Parent)
    )

    $ErrorActionPreference = "Stop"
    $Tags = @(git -C $Root tag --list)
    if ($LASTEXITCODE -ne 0) { throw "Cannot determine existing release tags." }

    $Sections = [regex]::Matches($Changelog, '(?ms)^## (?<Heading>[^\r\n]+?)[ \t]*\r?\n(?<Notes>.*?)(?=^## |\z)')
    if ($Sections.Count -eq 0) { throw "Missing release notes in changelog." }
    $Section = $Sections[0]
    $Heading = $Section.Groups["Heading"].Value
    $Notes = $Section.Groups["Notes"].Value.Trim()
    if ([System.String]::IsNullOrWhiteSpace($Notes)) { throw "Missing release notes under '## $Heading'." }

    if ($Heading -ceq "VERSION") {
        $NewVersion = [System.Version]::new([int](Get-Date -Format "yyMM"), ($Version.Minor + 3), 0)
    }
    elseif ($Heading -ceq $Version.ToString() -and "v$Version" -cin $Tags) {
        $NewVersion = [System.Version]::new($Version.Major, $Version.Minor, ($Version.Build + 1))
    }
    else {
        throw "Expected '## VERSION', or release notes and an existing tag matching '$Version', to prepare a release."
    }

    while ("v$NewVersion" -cin $Tags) {
        $NewVersion = [System.Version]::new($NewVersion.Major, $NewVersion.Minor, ($NewVersion.Build + 1))
    }

    [PSCustomObject]@{
        Version         = $NewVersion
        PreviousVersion = "v$Version"
        Notes           = $Notes
        Changelog       = $Changelog.Remove($Section.Index, $Section.Length).Insert(
            $Section.Index,
            ($Section.Value -replace "^## $([regex]::Escape($Heading))(?=[ \t]*\r?\n)", "## $NewVersion")
        )
    }
}
