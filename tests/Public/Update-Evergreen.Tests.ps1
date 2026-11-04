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
            # Note: This may throw other errors related to network/file operations, 
            # but should not throw the Force parameter validation error
            try {
                Update-Evergreen -Release "v24.01.01.12345" -Force -ErrorAction Stop
            }
            catch {
                $_.Exception.Message | Should -Not -Match "Force parameter required"
            }
        }
    }
}

Describe -Tag "Update" -Name "Update-Evergreen Function Behavior" {
    BeforeAll {
        # Set custom test path for this test suite
        $env:EVERGREEN_APPS_PATH = $script:TestPath
        New-Item -Path $script:TestPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
    }

    AfterAll {
        # Clean up test directory
        if (Test-Path -Path $script:TestPath) {
            Remove-Item -Path $script:TestPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }
        # Restore original EVERGREEN_APPS_PATH
        if ($script:OriginalAppsPath) {
            $env:EVERGREEN_APPS_PATH = $script:OriginalAppsPath
        }
        else {
            Remove-Item Env:\EVERGREEN_APPS_PATH -ErrorAction "SilentlyContinue"
        }
    }

    Context "Validate Update-Evergreen basic execution" {
        It "Should not throw when called without parameters" {
            { Update-Evergreen -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should not throw when called with -Force parameter" {
            { Update-Evergreen -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should create Apps directory after successful update" {
            $AppsDir = Join-Path -Path $script:TestPath -ChildPath "Apps"
            Test-Path -Path $AppsDir -PathType "Container" | Should -Be $true
        }

        It "Should create Manifests directory after successful update" {
            $ManifestsDir = Join-Path -Path $script:TestPath -ChildPath "Manifests"
            Test-Path -Path $ManifestsDir -PathType "Container" | Should -Be $true
        }

        It "Should create version file after successful update" {
            $VersionFile = Join-Path -Path $script:TestPath -ChildPath ".evergreen_version"
            Test-Path -Path $VersionFile -PathType "Leaf" | Should -Be $true
        }

        It "Version file should contain valid version format" {
            $VersionFile = Join-Path -Path $script:TestPath -ChildPath ".evergreen_version"
            if (Test-Path -Path $VersionFile) {
                $Version = Get-Content -Path $VersionFile -Raw -ErrorAction "SilentlyContinue"
                $Version = $Version.Trim()
                $Version | Should -Match "^v?\d{2}\.\d{2}\.\d{2}\.\d+"
            }
        }
    }

    Context "Validate Update-Evergreen with custom path" {
        BeforeAll {
            $script:CustomTestPath = Join-Path -Path $script:TestPath -ChildPath "CustomCache"
            $env:EVERGREEN_APPS_PATH = $script:CustomTestPath
        }

        It "Should use custom EVERGREEN_APPS_PATH when set" {
            Update-Evergreen -ErrorAction Stop
            Test-Path -Path $script:CustomTestPath -PathType "Container" | Should -Be $true
        }

        It "Should create Apps directory in custom path" {
            $AppsDir = Join-Path -Path $script:CustomTestPath -ChildPath "Apps"
            Test-Path -Path $AppsDir -PathType "Container" | Should -Be $true
        }

        AfterAll {
            if (Test-Path -Path $script:CustomTestPath) {
                Remove-Item -Path $script:CustomTestPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }
    }
}

Describe -Tag "Update" -Name "Update-Evergreen Idempotency" {
    BeforeAll {
        # Set custom test path for this test suite
        $script:IdempotencyTestPath = Join-Path -Path $script:TestPath -ChildPath "IdempotencyTest"
        $env:EVERGREEN_APPS_PATH = $script:IdempotencyTestPath
        New-Item -Path $script:IdempotencyTestPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
    }

    AfterAll {
        # Clean up test directory
        if (Test-Path -Path $script:IdempotencyTestPath) {
            Remove-Item -Path $script:IdempotencyTestPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }
        # Restore original EVERGREEN_APPS_PATH
        if ($script:OriginalAppsPath) {
            $env:EVERGREEN_APPS_PATH = $script:OriginalAppsPath
        }
        else {
            Remove-Item Env:\EVERGREEN_APPS_PATH -ErrorAction "SilentlyContinue"
        }
    }

    Context "Validate multiple runs of Update-Evergreen" {
        It "First run should not throw" {
            { Update-Evergreen -ErrorAction Stop } | Should -Not -Throw
        }

        It "Second run without Force should not throw" {
            { Update-Evergreen -ErrorAction Stop } | Should -Not -Throw
        }

        It "Run with Force should not throw" {
            { Update-Evergreen -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "Version file should still exist after multiple runs" {
            $VersionFile = Join-Path -Path $script:IdempotencyTestPath -ChildPath ".evergreen_version"
            Test-Path -Path $VersionFile -PathType "Leaf" | Should -Be $true
        }
    }
}
