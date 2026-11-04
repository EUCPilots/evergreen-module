BeforeAll {
    . (Join-Path $PSScriptRoot "..\..\ci\Test-Release.ps1")
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
