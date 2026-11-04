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

    It "Uses a reachable release tag when a new release follows an untagged manifest version" {
        $null = New-Item -Path (Join-Path $Root "Evergreen/Public") -ItemType Directory -Force
        Set-Content -LiteralPath (Join-Path $Root "Evergreen/Public/Save-EvergreenApp.ps1") -Value 'function Save-EvergreenApp {}'
        git -C $Root add Evergreen
        git -C $Root -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit --quiet -m "Untagged version"
        git -C $Root -c tag.gpgsign=false tag unrelated-tag
        if ($LASTEXITCODE -ne 0) { throw "Cannot create untagged version fixture." }

        $Result = Get-ReleaseVersionData -Version "2611.2865.1" -Changelog $Changelog.Replace("## 2611.2865.0", "## VERSION") -Root $Root

        $Result.PreviousVersion | Should -Be "v2611.2865.0"
        $Result.Version | Should -Be ([version]::new([int](Get-Date -Format "yyMM"), 2868, 0))
        $ChangedFiles = @(git -C $Root diff --name-only --diff-filter=ACMR $Result.PreviousVersion HEAD -- Evergreen)
        $LASTEXITCODE | Should -Be 0
        $ChangedFiles | Should -Contain "Evergreen/Public/Save-EvergreenApp.ps1"
    }

    It "Rejects a missing baseline when no release tag is reachable" {
        git -C $Root tag -d v2611.2865.0
        if ($LASTEXITCODE -ne 0) { throw "Cannot remove fixture release tag." }

        { Get-ReleaseVersionData -Version "2611.2865.1" -Changelog $Changelog.Replace("## 2611.2865.0", "## VERSION") -Root $Root } |
            Should -Throw "*Cannot determine a reachable release tag*"
    }

    It "Surfaces coverage baseline lookup failures" {
        Mock git { $global:LASTEXITCODE = 128 } -ParameterFilter { $args -contains "describe" }

        { Get-ReleaseVersionData -Version "2611.2865.1" -Changelog $Changelog.Replace("## 2611.2865.0", "## VERSION") -Root $Root } |
            Should -Throw "*Cannot determine a reachable release tag*"
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

    It "Updates the manifest, changelog and job outputs together for <Scenario>" -ForEach @(
        @{ Scenario = "a tagged retry"; ManifestVersion = "2611.2865.0"; NewRelease = $false }
        @{ Scenario = "a new release after an untagged version"; ManifestVersion = "2611.2865.1"; NewRelease = $true }
    ) {
        $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $null = New-Item -Path (Join-Path $Root "ci"), (Join-Path $Root "Evergreen") -ItemType Directory
        Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ci/Get-ReleaseVersionData.ps1"), (Join-Path $RepositoryRoot "ci/ValidationTools.psd1") -Destination (Join-Path $Root "ci")
        Set-Content -LiteralPath (Join-Path $Root "Evergreen/Evergreen.psm1") -Value ""
        New-ModuleManifest -Path (Join-Path $Root "Evergreen/Evergreen.psd1") -RootModule Evergreen.psm1 -ModuleVersion $ManifestVersion
        $null = New-Item -Path (Join-Path $Root "Evergreen/Public") -ItemType Directory
        Set-Content -LiteralPath (Join-Path $Root "Evergreen/Public/Get-Example.ps1") -Value 'function Get-Example { "example" }'
        $ExpectedVersion = "2611.2865.1"
        $ExpectedChangelog = $Changelog.Replace("## 2611.2865.0", "## $ExpectedVersion")
        if ($NewRelease) {
            $ExpectedVersion = [version]::new([int](Get-Date -Format "yyMM"), 2868, 0).ToString()
            $ExpectedChangelog = $Changelog.Replace("## 2611.2865.0", "## $ExpectedVersion")
            $Changelog = $Changelog.Replace("## 2611.2865.0", "## VERSION")
        }
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
            $Manifest.ModuleVersion | Should -Be $ExpectedVersion
            ($Manifest.PrivateData.PSData.ReleaseNotes -replace "`r`n", "`n") | Should -Be "$ExpectedVersion`nCurrent release notes."
            $Manifest.FunctionsToExport | Should -Contain "Get-Example"
            (Get-Content -LiteralPath (Join-Path $Root "CHANGELOG.md") -Raw).TrimEnd() |
                Should -Be $ExpectedChangelog.TrimEnd()
            $Outputs = Get-Content -LiteralPath $OutputFile
            $Outputs | Should -Contain "previousversion=v2611.2865.0"
            $Outputs | Should -Contain "newversion=$ExpectedVersion"
        }
        finally {
            $env:GITHUB_OUTPUT = $OriginalOutput
            Pop-Location
        }
    }
}

Describe "Release workflow tag creation" {
    BeforeAll {
        $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $Workflow = Get-Content -LiteralPath (Join-Path $RepositoryRoot ".github/workflows/update-module.yml") -Raw
        $Step = [regex]::Match($Workflow, '(?ms)      - name: Create and Push Tag\r?\n.*?        run: \|\r?\n(?<Script>.*?)(?=\r?\n      - name:)')
        if (-not $Step.Success) { throw "Cannot find workflow tag step." }
        $TagScript = [scriptblock]::Create($Step.Groups["Script"].Value)
    }

    BeforeEach {
        $Root = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
        $Remote = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
        $null = New-Item -Path (Join-Path $Root "Evergreen") -ItemType Directory -Force
        New-ModuleManifest -Path (Join-Path $Root "Evergreen/Evergreen.psd1") -ModuleVersion "2611.2865.1"
        git init --bare --quiet $Remote
        git -C $Root init --quiet
        git -C $Root config tag.gpgsign false
        git -C $Root add .
        git -C $Root -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit --quiet -m "Tag fixture" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
        git -C $Root config user.name Test
        git -C $Root config user.email test@example.test
        git -C $Root remote add origin $Remote
        if ($LASTEXITCODE -ne 0) { throw "Cannot initialize tag fixture." }
        $Commit = git -C $Root rev-parse HEAD
        $OriginalWorkspace = $env:GITHUB_WORKSPACE
        $OriginalOutput = $env:GITHUB_OUTPUT
        $env:GITHUB_WORKSPACE = $Root
        $env:GITHUB_OUTPUT = Join-Path $Root "outputs.txt"
        Push-Location $Root
    }

    AfterEach {
        Pop-Location
        $env:GITHUB_WORKSPACE = $OriginalWorkspace
        $env:GITHUB_OUTPUT = $OriginalOutput
    }

    It "Creates or reuses a tag with state <State>" -ForEach @(
        @{ State = "absent" }
        @{ State = "local" }
        @{ State = "remote" }
        @{ State = "local-and-remote" }
    ) {
        if ($State -ne "absent") {
            git tag -a v2611.2865.1 -m "Existing release tag"
            if ($LASTEXITCODE -ne 0) { throw "Cannot create fixture tag." }
            $OriginalTag = git rev-parse refs/tags/v2611.2865.1
            if ($State -in @("remote", "local-and-remote")) {
                git push origin refs/tags/v2611.2865.1
                if ($LASTEXITCODE -ne 0) { throw "Cannot push fixture tag." }
            }
            if ($State -eq "remote") {
                git tag -d v2611.2865.1
                if ($LASTEXITCODE -ne 0) { throw "Cannot remove local fixture tag." }
            }
        }

        & $TagScript

        (git rev-parse "refs/tags/v2611.2865.1^{commit}") | Should -Be $Commit
        (git --git-dir=$Remote rev-parse "refs/tags/v2611.2865.1^{commit}") | Should -Be $Commit
        if ($State -ne "absent") {
            (git rev-parse refs/tags/v2611.2865.1) | Should -Be $OriginalTag
        }
        Get-Content -LiteralPath $env:GITHUB_OUTPUT | Should -Contain "tested_commit=$Commit"
    }

    It "Rejects an existing remote tag on a different commit without overwriting it" {
        git tag -a v2611.2865.1 -m "Original release"
        git push origin refs/tags/v2611.2865.1
        if ($LASTEXITCODE -ne 0) { throw "Cannot push original fixture tag." }
        git -c commit.gpgsign=false commit --allow-empty --quiet -m "Different release commit" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
        if ($LASTEXITCODE -ne 0) { throw "Cannot create different release commit." }

        { & $TagScript } | Should -Throw "*points to a different commit*"

        (git --git-dir=$Remote rev-parse "refs/tags/v2611.2865.1^{commit}") | Should -Be $Commit
        Test-Path -LiteralPath $env:GITHUB_OUTPUT | Should -BeFalse
    }

    It "Stops when remote tags cannot be fetched" {
        git remote set-url origin (Join-Path $TestDrive "MissingRemote")
        { & $TagScript } | Should -Throw "*Cannot fetch existing release tags*"
        @(git tag --list v2611.2865.1).Count | Should -Be 0
        Test-Path -LiteralPath $env:GITHUB_OUTPUT | Should -BeFalse
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
