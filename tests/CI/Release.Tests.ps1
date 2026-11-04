BeforeAll {
    . (Join-Path $PSScriptRoot "..\..\ci\Test-Release.ps1")
    . (Join-Path $PSScriptRoot "..\..\ci\Get-ReleaseVersionData.ps1")
}

Describe "Release version preparation" {
    BeforeEach {
        $Root = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
        $null = New-Item -Path $Root -ItemType Directory
        git -C $Root init --quiet
        git -C $Root -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit --allow-empty --quiet -m "Release fixture" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
        git -C $Root -c tag.gpgsign=false tag v2611.2865.0
        if ($LASTEXITCODE -ne 0) { throw "Cannot initialize release version fixture." }
        $Changelog = "# Change log`n`n## 2611.2865.0`n`nCurrent release notes.`n`n## 2610.2862.0`n`nOlder notes.`n"
    }

    It "Retains the normal version increment for a new release placeholder" {
        $Changelog = $Changelog.Replace("## 2611.2865.0", "## VERSION")
        $Result = Get-ReleaseVersionData -Version "2611.2865.0" -Changelog $Changelog -Root $Root

        $Result.Version | Should -Be ([version]::new([int](Get-Date -Format "yyMM"), 2868, 0))
        $Result.PreviousVersion | Should -Be "v2611.2865.0"
        $Result.Notes | Should -Be "Current release notes."
        $Result.Changelog | Should -Be ($Changelog.Replace("## VERSION", "## $($Result.Version)"))
    }

    It "Increments the third component on repeated release attempts without moving existing tags" {
        $OriginalCommit = git -C $Root rev-parse v2611.2865.0
        $First = Get-ReleaseVersionData -Version "2611.2865.0" -Changelog $Changelog -Root $Root

        $First.Version | Should -Be ([version]"2611.2865.1")
        $First.Notes | Should -Be "Current release notes."
        $First.Changelog | Should -Be ($Changelog.Replace("## 2611.2865.0", "## 2611.2865.1"))
        git -C $Root -c tag.gpgsign=false tag v2611.2865.1
        if ($LASTEXITCODE -ne 0) { throw "Cannot create retry fixture tag." }

        $Second = Get-ReleaseVersionData -Version $First.Version -Changelog $First.Changelog -Root $Root
        $Second.Version | Should -Be ([version]"2611.2865.2")
        $Second.PreviousVersion | Should -Be "v2611.2865.1"
        $Second.Notes | Should -Be $First.Notes
        (git -C $Root rev-parse v2611.2865.0) | Should -Be $OriginalCommit
    }

    It "Skips occupied retry tags" {
        git -C $Root -c tag.gpgsign=false tag v2611.2865.1
        git -C $Root -c tag.gpgsign=false tag v2611.2865.2
        if ($LASTEXITCODE -ne 0) { throw "Cannot create occupied fixture tags." }

        $Result = Get-ReleaseVersionData -Version "2611.2865.0" -Changelog $Changelog -Root $Root

        $Result.Version | Should -Be ([version]"2611.2865.3")
        $Result.Changelog | Should -Match "## 2611.2865.3"
    }

    It "Increments the third component when a normal release candidate tag is occupied" {
        $Candidate = [version]::new([int](Get-Date -Format "yyMM"), 2868, 0)
        git -C $Root -c tag.gpgsign=false tag "v$Candidate"
        if ($LASTEXITCODE -ne 0) { throw "Cannot create occupied candidate tag." }

        $Result = Get-ReleaseVersionData -Version "2611.2865.0" -Changelog $Changelog.Replace("## 2611.2865.0", "## VERSION") -Root $Root

        $Result.Version | Should -Be ([version]::new($Candidate.Major, $Candidate.Minor, 1))
    }

    It "Rejects a retry without the current release tag" {
        { Get-ReleaseVersionData -Version "2611.2865.1" -Changelog $Changelog.Replace("2611.2865.0", "2611.2865.1") -Root $Root } |
            Should -Throw "*existing tag matching*"
    }

    It "Rejects invalid or missing release notes: <Notes>" -ForEach @(
        @{ Notes = "# Change log" }
        @{ Notes = "## VERSION`n`n" }
        @{ Notes = "## 2611.2865.0`n`n" }
        @{ Notes = "## 2610.2862.0`n`nMismatched notes." }
    ) {
        { Get-ReleaseVersionData -Version "2611.2865.0" -Changelog $Notes -Root $Root } | Should -Throw
    }

    It "Preserves CRLF line endings and historical changelog entries" {
        $Changelog = $Changelog.Replace("`n", "`r`n")
        $Result = Get-ReleaseVersionData -Version "2611.2865.0" -Changelog $Changelog -Root $Root

        $Result.Changelog | Should -Be ($Changelog.Replace("## 2611.2865.0", "## 2611.2865.1"))
    }

    It "Surfaces tag lookup failures" {
        Mock git { $global:LASTEXITCODE = 1 }
        { Get-ReleaseVersionData -Version "2611.2865.0" -Changelog $Changelog -Root $Root } |
            Should -Throw "*Cannot determine existing release tags*"
    }

    It "Updates the manifest, changelog and job outputs together in the workflow retry step" {
        $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $null = New-Item -Path (Join-Path $Root "ci"), (Join-Path $Root "Evergreen") -ItemType Directory
        Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ci/Get-ReleaseVersionData.ps1"), (Join-Path $RepositoryRoot "ci/ValidationTools.psd1") -Destination (Join-Path $Root "ci")
        Set-Content -LiteralPath (Join-Path $Root "Evergreen/Evergreen.psm1") -Value ""
        New-ModuleManifest -Path (Join-Path $Root "Evergreen/Evergreen.psd1") -RootModule Evergreen.psm1 -ModuleVersion "2611.2865.0"
        $null = New-Item -Path (Join-Path $Root "Evergreen/Public") -ItemType Directory
        Set-Content -LiteralPath (Join-Path $Root "Evergreen/Public/Get-Example.ps1") -Value 'function Get-Example { "example" }'
        Set-Content -LiteralPath (Join-Path $Root "CHANGELOG.md") -Value $Changelog
        $Workflow = Get-Content -LiteralPath (Join-Path $RepositoryRoot ".github/workflows/update-module.yml") -Raw
        $Step = [regex]::Match($Workflow, '(?ms)      - name: Update module version number\r?\n.*?        run: \|\r?\n(?<Script>.*?)(?=\r?\n      #)')
        $Step.Success | Should -BeTrue
        $Script = $Step.Groups["Script"].Value.Replace('${{ github.workspace }}', $Root)
        Mock Import-Module {} -ParameterFilter { $Name -eq "PowerShellGet" }
        $OriginalOutput = $env:GITHUB_OUTPUT
        $OutputFile = Join-Path $Root "outputs.txt"
        Push-Location $Root
        try {
            $env:GITHUB_OUTPUT = $OutputFile
            & ([scriptblock]::Create($Script))

            $Manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $Root "Evergreen/Evergreen.psd1")
            $Manifest.ModuleVersion | Should -Be "2611.2865.1"
            ($Manifest.PrivateData.PSData.ReleaseNotes -replace "`r`n", "`n") | Should -Be "2611.2865.1`nCurrent release notes."
            $Manifest.FunctionsToExport | Should -Contain "Get-Example"
            (Get-Content -LiteralPath (Join-Path $Root "CHANGELOG.md") -Raw).TrimEnd() |
                Should -Be ($Changelog.Replace("## 2611.2865.0", "## 2611.2865.1").TrimEnd())
            $Outputs = Get-Content -LiteralPath $OutputFile
            $Outputs | Should -Contain "previousversion=v2611.2865.0"
            $Outputs | Should -Contain "newversion=2611.2865.1"
        }
        finally {
            $env:GITHUB_OUTPUT = $OriginalOutput
            Pop-Location
        }
    }
}

Describe "Release metadata and package gate" {
    BeforeEach {
        $Root = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
        $Source = Join-Path $Root "Evergreen"
        $Package = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
        $null = New-Item -Path $Source, (Join-Path $Root ".rules") -ItemType Directory -Force
        Set-Content -LiteralPath (Join-Path $Source "Evergreen.psm1") -Value 'function Get-Example { "example" }'
        New-ModuleManifest -Path (Join-Path $Source "Evergreen.psd1") -RootModule Evergreen.psm1 -ModuleVersion "2.0.0" -ReleaseNotes "2.0.0 release notes" -FunctionsToExport Get-Example
        Set-Content -LiteralPath (Join-Path $Root "CHANGELOG.md") -Value "## 2.0.0`n`nRelease notes."
        Set-Content -LiteralPath (Join-Path $Root ".rules\PackageInventory.json") -Value '["Evergreen.psm1","Evergreen.psd1"]'
        Push-Location $Root
        try {
            git init --quiet
            git config core.autocrlf false
            git -c user.name=Test -c user.email=test@example.test add .
            git -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit --quiet -m "Fixture" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
            git -c tag.gpgsign=false tag v2.0.0
            $Commit = git rev-parse HEAD
            if ($LASTEXITCODE -ne 0) { throw "Cannot initialize release fixture." }
        }
        finally {
            Pop-Location
        }
        Copy-Item -LiteralPath $Source -Destination $Package -Recurse
        Mock Find-Module { [PSCustomObject]@{ Version = "1.0.0" } }
    }

    It "Accepts a newer version and an exact staged package" {
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Not -Throw
        Should -Invoke Find-Module -Times 1 -Exactly -ParameterFilter { $Name -eq "Evergreen" -and $Repository -eq "PSGallery" }
    }

    It "Rejects equal or older candidate versions: <PublishedVersion>" -ForEach @(
        @{ PublishedVersion = "2.0.0" }
        @{ PublishedVersion = "3.0.0" }
    ) {
        Mock Find-Module { [PSCustomObject]@{ Version = $PublishedVersion } }
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*must exceed*"
    }

    It "Propagates Gallery failures" {
        Mock Find-Module { throw "Gallery unavailable" }
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*Gallery unavailable*"
    }

    It "Rejects a tested commit mismatch" {
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit ("0" * 40) -Root $Root -PackagePath $Package } |
            Should -Throw "*must agree*"
    }

    It "Rejects a tag that points at a different commit" {
        Push-Location $Root
        try {
            git -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit --allow-empty --quiet -m "Different fixture commit" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
            $NewCommit = git rev-parse HEAD
        }
        finally { Pop-Location }
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $NewCommit -Root $Root -PackagePath $Package } |
            Should -Throw "*must agree*"
    }

    It "Rejects source changes after testing" {
        Add-Content -LiteralPath (Join-Path $Source "Evergreen.psm1") -Value "# untested change"
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*Release inputs differ*"
    }

    It "Rejects a tag/version mismatch" {
        { Test-Release -Version "2.1.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*must agree*"
    }

    It "Rejects a package version mismatch" {
        Update-ModuleManifest -Path (Join-Path $Package "Evergreen.psd1") -ModuleVersion "1.0.0"
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*manifest version*"
    }

    It "Rejects unversioned manifest release notes" {
        Update-ModuleManifest -Path (Join-Path $Package "Evergreen.psd1") -ReleaseNotes "Release notes"
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*Manifest release notes*"
    }

    It "Rejects a missing or unexpected package file: <Mutation>" -ForEach @(
        @{ Mutation = "missing" }
        @{ Mutation = "extra" }
    ) {
        if ($Mutation -eq "missing") { Remove-Item -LiteralPath (Join-Path $Package "Evergreen.psm1") }
        else { Set-Content -LiteralPath (Join-Path $Package "extra.txt") -Value "unexpected" }
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw
    }

    It "Rejects altered staged content" {
        Add-Content -LiteralPath (Join-Path $Package "Evergreen.psm1") -Value "# tampered"
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*differs from the tested source*"
    }

    It "Rejects placeholder or absent release sections: <Notes>" -ForEach @(
        @{ Notes = "## VERSION`n`nNotes" }
        @{ Notes = "## 2.0.0`n`nTBD" }
        @{ Notes = "## 2.0.0`n`n" }
        @{ Notes = "## 1.0.0`n`nOlder notes" }
    ) {
        Set-Content -LiteralPath (Join-Path $Root "CHANGELOG.md") -Value $Notes
        Push-Location $Root
        try {
            git add CHANGELOG.md
            git -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit --quiet -m "Notes fixture" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
            git -c tag.gpgsign=false tag -f v2.0.0
            $Commit = git rev-parse HEAD
        }
        finally { Pop-Location }
        { Test-Release -Version "2.0.0" -Tag "v2.0.0" -TestedCommit $Commit -Root $Root -PackagePath $Package } |
            Should -Throw "*Release notes must include*"
    }
}
