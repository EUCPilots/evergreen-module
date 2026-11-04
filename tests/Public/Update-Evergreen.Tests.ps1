<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
    # Store original EVERGREEN_APPS_PATH if it exists
    $script:OriginalAppsPath = $env:EVERGREEN_APPS_PATH

    # Create a temporary test directory
    if ($env:Temp) {
        $script:TestPath = Join-Path -Path $env:Temp -ChildPath "EvergreenTests"
    }
    elseif ($env:TMPDIR) {
        $script:TestPath = Join-Path -Path $env:TMPDIR -ChildPath "EvergreenTests"
    }
    elseif ($env:RUNNER_TEMP) {
        $script:TestPath = Join-Path -Path $env:RUNNER_TEMP -ChildPath "EvergreenTests"
    }
}

Describe -Tag "Update" -Name "Update-Evergreen ShouldProcess" {
    It "Leaves cache state unchanged with WhatIf (existing: <CacheExists>, force: <Force>, release: <Release>)" -TestCases @(
        @{ CacheExists = $false; Force = $false; Release = $null }
        @{ CacheExists = $true; Force = $false; Release = $null }
        @{ CacheExists = $false; Force = $true; Release = $null }
        @{ CacheExists = $true; Force = $true; Release = $null }
        @{ CacheExists = $false; Force = $true; Release = "v26.11.04.1" }
        @{ CacheExists = $true; Force = $true; Release = "v26.11.04.1" }
    ) {
        param ($CacheExists, $Force, $Release)

        $CachePath = Join-Path -Path $TestDrive -ChildPath ([System.Guid]::NewGuid().ToString())
        if ($CacheExists) {
            New-Item -Path (Join-Path -Path $CachePath -ChildPath "Apps") -ItemType "Directory" -Force | Out-Null
            Set-Content -Path (Join-Path -Path $CachePath -ChildPath ".evergreen_version") -Value "26.11.03.1"
        }

        InModuleScope -ModuleName "Evergreen" -Parameters @{
            CachePath = $CachePath; CacheExists = $CacheExists; Force = $Force; Release = $Release
        } {
            Mock Get-EvergreenAppsPath { $CachePath }
            Mock Get-GitHubRepoRelease { throw "Unexpected network request." }
            Mock Save-EvergreenApp { throw "Unexpected download." }
            $OriginalAppsPath = $script:AppsPath
            $OriginalVersionFile = $script:VersionFile
            $Options = @{ WhatIf = $true; Force = $Force }
            if ($Release) { $Options.Release = $Release }

            Update-Evergreen @Options

            $script:AppsPath | Should -Be $OriginalAppsPath
            $script:VersionFile | Should -Be $OriginalVersionFile
            Test-Path -Path $CachePath | Should -Be $CacheExists
            if ($CacheExists) {
                @(Get-ChildItem -Path $CachePath -Recurse -Force).Count | Should -Be 2
                (Get-Content -Path (Join-Path -Path $CachePath -ChildPath ".evergreen_version") -Raw).Trim() |
                    Should -Be "26.11.03.1"
            }
            Should -Invoke Get-GitHubRepoRelease -Times 0 -Exactly
            Should -Invoke Save-EvergreenApp -Times 0 -Exactly
        }
    }

    It "Validates the Release and Force requirement even with WhatIf" {
        { Update-Evergreen -Release "v26.11.04.1" -WhatIf } | Should -Throw "*Force parameter required*"
    }

    It "Completes an update using a local release archive (explicit confirmation disabled: <SuppressConfirmation>)" -TestCases @(
        @{ SuppressConfirmation = $false }
        @{ SuppressConfirmation = $true }
    ) {
        param ($SuppressConfirmation)

        $RootPath = Join-Path -Path $TestDrive -ChildPath ([System.Guid]::NewGuid().ToString())
        $SourcePath = Join-Path -Path $RootPath -ChildPath "Source"
        New-Item -Path (Join-Path -Path $SourcePath -ChildPath "Apps") -ItemType "Directory" -Force | Out-Null
        New-Item -Path (Join-Path -Path $SourcePath -ChildPath "Manifests") -ItemType "Directory" -Force | Out-Null
        Set-Content -Path (Join-Path -Path $SourcePath -ChildPath "Apps\Get-TestApp.ps1") -Value "function Get-TestApp {}"
        Set-Content -Path (Join-Path -Path $SourcePath -ChildPath "Manifests\TestApp.json") -Value "{}"
        $ZipPath = Join-Path -Path $RootPath -ChildPath "Release.zip"
        Compress-Archive -Path (Join-Path -Path $SourcePath -ChildPath "*") -DestinationPath $ZipPath
        $CachePath = Join-Path -Path $RootPath -ChildPath "ApprovedCache"

        InModuleScope -ModuleName "Evergreen" -Parameters @{
            CachePath = $CachePath; ZipPath = $ZipPath; SuppressConfirmation = $SuppressConfirmation
        } {
            Mock Get-EvergreenAppsPath { $CachePath }
            Mock Get-GitHubRepoRelease {
                [PSCustomObject]@{
                    Type = "zip"
                    Version = "26.11.04.1"
                    Uri = "https://example.invalid/release.zip"
                    Sha256 = (Get-FileHash -Path $ZipPath -Algorithm "SHA256").Hash
                }
            }
            Mock Save-EvergreenApp { $ZipPath }
            $OriginalAppsPath = $script:AppsPath
            $OriginalVersionFile = $script:VersionFile
            $OriginalProgressPreference = $global:ProgressPreference
            try {
                if ($SuppressConfirmation) {
                    Update-Evergreen -Force -Confirm:$false
                }
                else {
                    Update-Evergreen
                }

                Test-Path -Path (Join-Path -Path $CachePath -ChildPath "Apps\Get-TestApp.ps1") | Should -BeTrue
                Test-Path -Path (Join-Path -Path $CachePath -ChildPath "Manifests\TestApp.json") | Should -BeTrue
                (Get-Content -Path (Join-Path -Path $CachePath -ChildPath ".evergreen_version") -Raw).Trim() |
                    Should -Be "26.11.04.1"
                Should -Invoke Save-EvergreenApp -Times 1 -Exactly
            }
            finally {
                $script:AppsPath = $OriginalAppsPath
                $script:VersionFile = $OriginalVersionFile
                $global:ProgressPreference = $OriginalProgressPreference
            }
        }
    }
}

Describe -Tag "Update" -Name "Update-Evergreen Parameter Validation" {
    Context "Validate Release parameter format" {
        It "Should throw with invalid Release format - missing 'v' prefix" {
            { Update-Evergreen -Release "24.01.01.12345" -Force } | Should -Throw
        }

        It "Should throw with invalid Release format - invalid month" {
            { Update-Evergreen -Release "v24.13.01.12345" -Force } | Should -Throw
        }

        It "Should throw with invalid Release format - invalid day" {
            { Update-Evergreen -Release "v24.01.32.12345" -Force } | Should -Throw
        }

        It "Should throw with invalid Release format - invalid year" {
            { Update-Evergreen -Release "v2024.01.01.12345" -Force } | Should -Throw
        }

        It "Should throw with invalid Release format - missing build number" {
            { Update-Evergreen -Release "v24.01.01" -Force } | Should -Throw
        }
    }

    Context "Validate Force parameter requirement with Release" {
        It "Should throw when Release is specified without Force" {
            { Update-Evergreen -Release "v24.01.01.12345" } | Should -Throw "*Force parameter required*"
        }

        It "Should not throw parameter validation error when Release is specified with Force" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ CachePath = $TestDrive } {
                param ($CachePath)

                Mock Get-EvergreenAppsPath { $CachePath }
                Mock Get-GitHubRepoRelease { throw "offline test" }

                { Update-Evergreen -Release "v24.01.01.12345" -Force } |
                    Should -Throw "*Could not retrieve remote version*"
            }
        }
    }
}

Describe -Tag "Update" -Name "Update-Evergreen deterministic cache behavior" {
    BeforeAll {
        $script:CreateFixture = {
            param ($Root)

            $zipPath = Join-Path -Path $Root -ChildPath "release.zip"
            $csvPath = Join-Path -Path $Root -ChildPath "hashes.csv"
            $appSource = Join-Path -Path $Root -ChildPath "Get-TestApp.ps1"
            [System.IO.File]::WriteAllText($appSource, "function Get-TestApp {}")
            $appHash = (Get-FileHash -LiteralPath $appSource -Algorithm SHA256).Hash
            [System.IO.File]::WriteAllText($zipPath, "release archive")
            [System.IO.File]::WriteAllText($csvPath, "file_path,sha256`nApps/Get-TestApp.ps1,$appHash`n")

            [PSCustomObject]@{
                CachePath = Join-Path -Path $Root -ChildPath "cache"
                ZipPath   = $zipPath
                CsvPath   = $csvPath
                Zip       = [PSCustomObject]@{
                    Type    = "zip"
                    Version = "26.11.04.1"
                    Uri     = "https://example.invalid/release.zip"
                    Sha256  = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
                }
                Csv       = [PSCustomObject]@{
                    Type   = "csv"
                    Uri    = "https://example.invalid/hashes.csv"
                    Sha256 = (Get-FileHash -LiteralPath $csvPath -Algorithm SHA256).Hash
                }
            }
        }
    }

    BeforeEach {
        $script:FixtureRoot = Join-Path -Path $TestDrive -ChildPath ([System.Guid]::NewGuid().ToString("N"))
        $null = New-Item -Path $script:FixtureRoot -ItemType Directory -Force
        $script:Fixture = & $script:CreateFixture $script:FixtureRoot
    }

    It "Fails clearly when the GitHub request fails or returns no release" {
        $fixture = $script:Fixture
        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { throw "offline test" }

            { Update-Evergreen } | Should -Throw "*Could not retrieve remote version*"
        }
    }

    It "Stops immediately when the GitHub API reports a rate limit" {
        $fixture = $script:Fixture
        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease {
                [PSCustomObject]@{ Type = "zip"; Version = "RateLimited" }
            }

            { Update-Evergreen } | Should -Throw "*GitHub API rate limit exceeded*"
            Test-Path -LiteralPath $Fixture.CachePath | Should -BeFalse
        }
    }

    It "Uses the specified release URL and synchronizes a verified archive" {
        $fixture = $script:Fixture
        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { @($Fixture.Zip, $Fixture.Csv) }
            Mock Save-EvergreenApp {
                if ($InputObject.Type -eq "csv") {
                    Get-Item -LiteralPath $Fixture.CsvPath
                }
                else {
                    $Fixture.ZipPath
                }
            }
            Mock Expand-Archive {
                $appsPath = Join-Path -Path $DestinationPath -ChildPath "Apps"
                $manifestsPath = Join-Path -Path $DestinationPath -ChildPath "Manifests"
                $null = New-Item -Path $appsPath -ItemType Directory -Force
                $null = New-Item -Path $manifestsPath -ItemType Directory -Force
                [System.IO.File]::WriteAllText((Join-Path $appsPath "Get-TestApp.ps1"), "function Get-TestApp {}")
                [System.IO.File]::WriteAllText((Join-Path $manifestsPath "TestApp.json"), "{}")
            }
            $previousProgressPreference = $global:ProgressPreference
            try {
                Update-Evergreen -Force -Release "v26.11.04.1"

                Test-Path -LiteralPath (Join-Path $Fixture.CachePath "Apps\Get-TestApp.ps1") | Should -BeTrue
                Test-Path -LiteralPath (Join-Path $Fixture.CachePath "Manifests\TestApp.json") | Should -BeTrue
                (Get-Content -LiteralPath (Join-Path $Fixture.CachePath ".evergreen_version") -Raw).Trim() |
                    Should -Be "26.11.04.1"
                Should -Invoke Get-GitHubRepoRelease -Times 1 -Exactly -ParameterFilter {
                    $Uri -like "*/releases/tags/v26.11.04.1"
                }
                Should -Invoke Save-EvergreenApp -Times 1 -Exactly
            }
            finally {
                $global:ProgressPreference = $previousProgressPreference
            }
        }
    }

    It "Skips downloading when cache versions match and every local hash matches" {
        $fixture = $script:Fixture
        New-Item -Path (Join-Path $fixture.CachePath "Apps") -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $fixture.CachePath "Manifests") -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture.CachePath "Apps\Get-TestApp.ps1") -Value "function Get-TestApp {}"
        Set-Content -LiteralPath (Join-Path $fixture.CachePath ".evergreen_version") -Value $fixture.Zip.Version

        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { @($Fixture.Zip, $Fixture.Csv) }
            Mock Save-EvergreenApp { Get-Item -LiteralPath $Fixture.CsvPath }
            Mock Expand-Archive { throw "Unexpected archive extraction." }

            Update-Evergreen

            Should -Invoke Save-EvergreenApp -Times 1 -Exactly
            Should -Invoke Expand-Archive -Times 0 -Exactly
        }
    }

    It "Reports local hash mismatches and leaves the current cache in place" {
        $fixture = $script:Fixture
        New-Item -Path (Join-Path $fixture.CachePath "Apps") -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $fixture.CachePath "Manifests") -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture.CachePath "Apps\Get-TestApp.ps1") -Value "modified"
        Set-Content -LiteralPath (Join-Path $fixture.CachePath ".evergreen_version") -Value $fixture.Zip.Version

        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { @($Fixture.Zip, $Fixture.Csv) }
            Mock Save-EvergreenApp { Get-Item -LiteralPath $Fixture.CsvPath }
            Mock Expand-Archive { throw "Unexpected archive extraction." }

            $messages = @(Update-Evergreen 6>&1)

            Should -Invoke Expand-Archive -Times 0 -Exactly
            ($messages | ForEach-Object MessageData | Out-String) | Should -Match "SHA256 mismatch found"
        }
    }

    It "Rejects a downloaded release zip with an invalid SHA256" {
        $fixture = $script:Fixture
        $fixture.Zip.Sha256 = [System.String]::new("0", 64)
        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { @($Fixture.Zip, $Fixture.Csv) }
            Mock Save-EvergreenApp { $Fixture.ZipPath }
            Mock Expand-Archive {}

            { Update-Evergreen -Force } | Should -Throw "*SHA256 mismatch for downloaded release zip file*"
            Should -Invoke Expand-Archive -Times 0 -Exactly
        }
    }

    It "Does not replace the cache when extracted content fails hash validation" {
        $fixture = $script:Fixture
        New-Item -Path (Join-Path $fixture.CachePath "Apps") -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $fixture.CachePath "Manifests") -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture.CachePath "Apps\Get-TestApp.ps1") -Value "old version"
        Set-Content -LiteralPath (Join-Path $fixture.CachePath ".evergreen_version") -Value "26.11.03.1"

        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { @($Fixture.Zip, $Fixture.Csv) }
            Mock Save-EvergreenApp {
                if ($InputObject.Type -eq "csv") {
                    Get-Item -LiteralPath $Fixture.CsvPath
                }
                else {
                    $Fixture.ZipPath
                }
            }
            Mock Expand-Archive {
                $appsPath = Join-Path -Path $DestinationPath -ChildPath "Apps"
                $manifestsPath = Join-Path -Path $DestinationPath -ChildPath "Manifests"
                $null = New-Item -Path $appsPath -ItemType Directory -Force
                $null = New-Item -Path $manifestsPath -ItemType Directory -Force
                [System.IO.File]::WriteAllText((Join-Path $appsPath "Get-TestApp.ps1"), "bad content")
            }

            Update-Evergreen -Force -WarningAction SilentlyContinue

            (Get-Content -LiteralPath (Join-Path $Fixture.CachePath "Apps\Get-TestApp.ps1") -Raw).Trim() |
                Should -Be "old version"
            (Get-Content -LiteralPath (Join-Path $Fixture.CachePath ".evergreen_version") -Raw).Trim() |
                Should -Be "26.11.03.1"
        }
    }

    It "Leaves the cache unchanged when a listed extracted file is missing" {
        $fixture = $script:Fixture
        $missingHash = [System.String]::new("0", 64)
        [System.IO.File]::WriteAllText($fixture.CsvPath, "file_path,sha256`nApps/Missing.ps1,$missingHash`n")
        $fixture.Csv.Sha256 = (Get-FileHash -LiteralPath $fixture.CsvPath -Algorithm SHA256).Hash
        New-Item -Path (Join-Path $fixture.CachePath "Apps") -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $fixture.CachePath "Manifests") -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture.CachePath "Apps\Get-TestApp.ps1") -Value "old version"
        Set-Content -LiteralPath (Join-Path $fixture.CachePath ".evergreen_version") -Value "26.11.03.1"

        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { @($Fixture.Zip, $Fixture.Csv) }
            Mock Save-EvergreenApp {
                if ($InputObject.Type -eq "csv") {
                    Get-Item -LiteralPath $Fixture.CsvPath
                }
                else {
                    $Fixture.ZipPath
                }
            }
            Mock Expand-Archive {
                $appsPath = Join-Path -Path $DestinationPath -ChildPath "Apps"
                $manifestsPath = Join-Path -Path $DestinationPath -ChildPath "Manifests"
                $null = New-Item -Path $appsPath -ItemType Directory -Force
                $null = New-Item -Path $manifestsPath -ItemType Directory -Force
                [System.IO.File]::WriteAllText((Join-Path $appsPath "Get-TestApp.ps1"), "function Get-TestApp {}")
            }

            Update-Evergreen -Force -WarningAction SilentlyContinue

            (Get-Content -LiteralPath (Join-Path $Fixture.CachePath "Apps\Get-TestApp.ps1") -Raw).Trim() |
                Should -Be "old version"
            (Get-Content -LiteralPath (Join-Path $Fixture.CachePath ".evergreen_version") -Raw).Trim() |
                Should -Be "26.11.03.1"
        }
    }

    It "Continues without hash verification when the downloaded hashes file is invalid" {
        $fixture = $script:Fixture
        $fixture.Csv.Sha256 = [System.String]::new("0", 64)
        New-Item -Path (Join-Path $fixture.CachePath "Apps") -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $fixture.CachePath "Manifests") -ItemType Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture.CachePath ".evergreen_version") -Value $fixture.Zip.Version

        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { @($Fixture.Zip, $Fixture.Csv) }
            Mock Save-EvergreenApp { Get-Item -LiteralPath $Fixture.CsvPath }
            Mock Expand-Archive { throw "Unexpected archive extraction." }

            { Update-Evergreen -WarningAction SilentlyContinue } | Should -Not -Throw
            Should -Invoke Expand-Archive -Times 0 -Exactly
        }
    }

    It "Fails when a requested download does not produce an archive" {
        $fixture = $script:Fixture
        InModuleScope -ModuleName "Evergreen" -Parameters @{ Fixture = $fixture } {
            param ($Fixture)

            Mock Get-EvergreenAppsPath { $Fixture.CachePath }
            Mock Get-GitHubRepoRelease { $Fixture.Zip }
            Mock Save-EvergreenApp { Join-Path $Fixture.CachePath "missing.zip" }

            { Update-Evergreen -Force } | Should -Throw "*Failed to download Evergreen apps release*"
        }
    }
}
