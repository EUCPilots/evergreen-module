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

Describe -Tag "Private" -Name "Get-Symbol" {
    Context "Validate Get-Symbol basic functionality" {
        It "Should not throw with Symbol parameter" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-Symbol -Symbol "Tick" } | Should -Not -Throw
            }
        }

        It "Should return a string" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-Symbol -Symbol "Tick"
                $Result | Should -BeOfType [string]
            }
        }

        It "Should not return null or empty" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-Symbol -Symbol "Tick"
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Validate Get-Symbol with different symbol types" {
        It "Should handle Tick symbol" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-Symbol -Symbol "Tick" } | Should -Not -Throw
            }
        }

        It "Should handle Cross symbol" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-Symbol -Symbol "Cross" } | Should -Not -Throw
            }
        }

        It "Should handle Arrow symbol" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-Symbol -Symbol "Arrow" } | Should -Not -Throw
            }
        }

        It "Should handle Bullet symbol" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-Symbol -Symbol "Bullet" } | Should -Not -Throw
            }
        }
    }

    Context "Validate Get-Symbol with invalid input" {
        It "Should handle unknown symbol gracefully" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-Symbol -Symbol "UnknownSymbol" } | Should -Not -Throw
            }
        }
    }
}
