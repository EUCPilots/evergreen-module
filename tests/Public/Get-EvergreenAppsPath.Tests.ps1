<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
    # Store original EVERGREEN_APPS_PATH if it exists
    $script:OriginalAppsPath = $env:EVERGREEN_APPS_PATH
}

AfterAll {
    # Restore original EVERGREEN_APPS_PATH
    if ($script:OriginalAppsPath) {
        $env:EVERGREEN_APPS_PATH = $script:OriginalAppsPath
    }
    else {
        Remove-Item Env:\EVERGREEN_APPS_PATH -ErrorAction "SilentlyContinue"
    }
}

Describe -Tag "Get" -Name "Get-EvergreenAppsPath" {
    Context "Validate Get-EvergreenAppsPath with environment variable" {
        BeforeAll {
            # Create a temporary test directory
            if ($env:Temp) {
                $script:TestPath = Join-Path -Path $env:Temp -ChildPath "EvergreenAppsPathTest"
            }
            elseif ($env:TMPDIR) {
                $script:TestPath = Join-Path -Path $env:TMPDIR -ChildPath "EvergreenAppsPathTest"
            }
            elseif ($env:RUNNER_TEMP) {
                $script:TestPath = Join-Path -Path $env:RUNNER_TEMP -ChildPath "EvergreenAppsPathTest"
            }
            New-Item -Path $script:TestPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
            $env:EVERGREEN_APPS_PATH = $script:TestPath
        }

        AfterAll {
            # Clean up test directory
            if (Test-Path -Path $script:TestPath) {
                Remove-Item -Path $script:TestPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Should not throw" {
            { Get-EvergreenAppsPath } | Should -Not -Throw
        }

        It "Should return a valid path" {
            $Path = Get-EvergreenAppsPath
            $Path | Should -Not -BeNullOrEmpty
        }

        It "Should return the path set in EVERGREEN_APPS_PATH environment variable" {
            $Path = Get-EvergreenAppsPath
            $Path | Should -Be $script:TestPath
        }
    }

    Context "Validate Get-EvergreenAppsPath without environment variable" {
        BeforeAll {
            # Remove EVERGREEN_APPS_PATH environment variable
            Remove-Item Env:\EVERGREEN_APPS_PATH -ErrorAction "SilentlyContinue"
        }

        It "Should not throw" {
            { Get-EvergreenAppsPath } | Should -Not -Throw
        }

        It "Should return a valid path" {
            $Path = Get-EvergreenAppsPath
            $Path | Should -Not -BeNullOrEmpty
        }

        It "Should return default path containing 'Evergreen' or '.evergreen'" {
            $Path = Get-EvergreenAppsPath
            $Path | Should -Match "Evergreen|\.evergreen"
        }
    }

    Context "Validate Get-EvergreenAppsPath with invalid path in environment variable" {
        BeforeAll {
            # Set EVERGREEN_APPS_PATH to a non-existent path
            $env:EVERGREEN_APPS_PATH = "/this/path/does/not/exist/evergreen"
        }

        It "Should not throw" {
            { Get-EvergreenAppsPath } | Should -Not -Throw
        }

        It "Should return the path even if it doesn't exist" {
            $Path = Get-EvergreenAppsPath
            $Path | Should -Be $env:EVERGREEN_APPS_PATH
        }

        It "Should produce a warning when path doesn't exist" {
            $WarningPreference = "Continue"
            $Warnings = @()
            $Path = Get-EvergreenAppsPath 3>&1 | Tee-Object -Variable Warnings
            $Warnings | Should -Not -BeNullOrEmpty
        }
    }
}
