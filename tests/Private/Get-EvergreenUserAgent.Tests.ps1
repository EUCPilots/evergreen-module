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

Describe -Tag "Private" -Name "Get-EvergreenUserAgent" {
    Context "Validate Get-EvergreenUserAgent basic functionality" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-EvergreenUserAgent } | Should -Not -Throw
            }
        }

        It "Should return a string" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-EvergreenUserAgent
                $Result | Should -BeOfType [string]
            }
        }

        It "Should not return null or empty" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-EvergreenUserAgent
                $Result | Should -Not -BeNullOrEmpty
            }
        }

        It "Should contain module name in user agent string" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-EvergreenUserAgent
                $Result | Should -Match "Evergreen"
            }
        }

        It "Should contain version number in user agent string" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-EvergreenUserAgent
                $Result | Should -Match "\d+\.\d+\.\d+"
            }
        }

        It "Should contain OS information in user agent string" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-EvergreenUserAgent
                $Result | Should -Match "Windows|macOS|Linux"
            }
        }
    }
}
