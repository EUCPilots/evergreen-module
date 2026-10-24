<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Private" -Name "Test-IsWindows" {
    $ExpectedIsWindows = [bool]($env:OS -eq 'Windows_NT')

    Context "Validate Test-IsWindows basic functionality" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                { Test-IsWindows } | Should -Not -Throw
            }
        }

        It "Should return a boolean value" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Test-IsWindows
                $Result | Should -BeOfType [bool]
            }
        }

        It "Should return true on Windows platform" -Skip:(-not $ExpectedIsWindows) {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Test-IsWindows
                $Result | Should -Be $true
            }
        }

        It "Should return true for Windows PowerShell Desktop edition" -Skip:($PSVersionTable.PSEdition -ne "Desktop") {
            InModuleScope -ModuleName "Evergreen" {
                Test-IsWindows | Should -Be $true
            }
        }

        It "Should return false on non-Windows platform" -Skip:($ExpectedIsWindows) {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Test-IsWindows
                $Result | Should -Be $false
            }
        }
    }
}
