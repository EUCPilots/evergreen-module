function Test-Release {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Version] $Version,

        [Parameter(Mandatory)]
        [System.String] $Tag,

        [Parameter(Mandatory)]
        [System.String] $TestedCommit,

        [System.String] $Root = (Split-Path $PSScriptRoot -Parent),

        [Parameter(Mandatory)]
        [System.String] $PackagePath
    )

    $ErrorActionPreference = "Stop"
    Push-Location -LiteralPath $Root
    try {
        $HeadCommit = git rev-parse --verify HEAD
        if ($LASTEXITCODE -ne 0) { throw "Cannot resolve HEAD." }
        $TagCommit = git rev-parse --verify "$Tag^{commit}"
        if ($LASTEXITCODE -ne 0) { throw "Cannot resolve release tag '$Tag'." }
        if ($Tag -cne "v$Version" -or $HeadCommit -cne $TestedCommit -or $TagCommit -cne $TestedCommit) {
            throw "Release tag, candidate version, checkout and tested commit must agree."
        }
        git diff --exit-code HEAD -- Evergreen CHANGELOG.md .rules/PackageInventory.json | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Release inputs differ from the tested commit." }

        $SourcePath = Join-Path $Root "Evergreen"
        $Manifest = Test-ModuleManifest -Path (Join-Path $PackagePath "Evergreen.psd1") -ErrorAction Stop
        if ($Manifest.Version -ne $Version) { throw "Package manifest version does not match '$Version'." }
        $ManifestData = Import-PowerShellDataFile -Path (Join-Path $PackagePath "Evergreen.psd1")
        $ReleaseNotes = [System.String]$ManifestData.PrivateData.PSData.ReleaseNotes
        if ($ReleaseNotes -notmatch [regex]::Escape($Version.ToString()) -or $ReleaseNotes -match '(?i)\b(TODO|TBD|FIXME)\b|<version>|\{\{.*?\}\}|## VERSION') {
            throw "Manifest release notes must identify '$Version' without unresolved placeholders."
        }
        $Published = Find-Module -Name Evergreen -Repository PSGallery -ErrorAction Stop
        if ($null -eq $Published -or $Version -le [System.Version]$Published.Version) {
            throw "Candidate version '$Version' must exceed the current Gallery version '$($Published.Version)'."
        }
        $Changelog = Get-Content -LiteralPath (Join-Path $Root "CHANGELOG.md") -Raw
        $Heading = [regex]::Escape($Version.ToString())
        $Section = [regex]::Match($Changelog, "(?ms)^## $Heading[ \t]*\r?\n(?<Notes>.*?)(?=^## |\z)")
        if (-not $Section.Success -or [System.String]::IsNullOrWhiteSpace($Section.Groups["Notes"].Value) -or
            $Changelog -match '(?im)^## VERSION\s*$' -or
            $Section.Groups["Notes"].Value -match '(?i)\b(TODO|TBD|FIXME)\b|<version>|\{\{.*?\}\}') {
            throw "Release notes must include nonempty notes for '$Version' without unresolved placeholders."
        }
        $Inventory = Get-Content -LiteralPath (Join-Path $Root ".rules\PackageInventory.json") -Raw | ConvertFrom-Json
        $Inventory = @($Inventory)
        if ($Inventory.Count -eq 0 -or @($Inventory | Sort-Object -Unique).Count -ne $Inventory.Count) {
            throw "Package inventory must be nonempty and contain unique paths."
        }
        foreach ($Path in @($SourcePath, $PackagePath)) {
            $Resolved = (Resolve-Path -LiteralPath $Path).Path.TrimEnd([char[]]@("\", "/"))
            if ((Get-Item -LiteralPath $Resolved -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                throw "Package roots must not be links or reparse points."
            }
            $Items = @(Get-ChildItem -LiteralPath $Resolved -Recurse -Force)
            if ($Items | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }) {
                throw "Package paths must not contain links or reparse points."
            }
            $Files = @($Items | Where-Object { -not $_.PSIsContainer } | ForEach-Object { $_.FullName.Substring($Resolved.Length + 1).Replace("\", "/") })
            $Difference = @(Compare-Object -ReferenceObject $Inventory -DifferenceObject $Files -CaseSensitive)
            if ($Difference.Count) {
                throw "Package inventory mismatch: $($Difference | Out-String)"
            }
        }
        foreach ($File in $Inventory) {
            $SourceHash = (Get-FileHash -LiteralPath (Join-Path $SourcePath $File) -Algorithm SHA256).Hash
            $PackageHash = (Get-FileHash -LiteralPath (Join-Path $PackagePath $File) -Algorithm SHA256).Hash
            if ($SourceHash -cne $PackageHash) { throw "Staged package differs from the tested source: '$File'." }
        }
        Write-Information -MessageData "Release $Tag at $TestedCommit passed metadata and package validation." -InformationAction Continue
    }
    finally {
        Pop-Location
    }
}
