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

Describe -Tag "Private" -Name "Convert-Segment" {
    Context "Validate Convert-Segment basic functionality" {
        It "Should not throw with valid segment" {
            InModuleScope -ModuleName "Evergreen" {
                { Convert-Segment -Segment "test-segment" } | Should -Not -Throw
            }
        }

        It "Should return a string" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Convert-Segment -Segment "test"
                $Result | Should -BeOfType [string]
            }
        }

        It "Should handle alphanumeric segments" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Convert-Segment -Segment "abc123"
                $Result | Should -Not -BeNullOrEmpty
            }
        }

        It "Should handle segments with hyphens" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Convert-Segment -Segment "test-segment"
                $Result | Should -Not -BeNullOrEmpty
            }
        }

        It "Should handle segments with underscores" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Convert-Segment -Segment "test_segment"
                $Result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Validate Convert-Segment with edge cases" {
        It "Should handle empty string" {
            InModuleScope -ModuleName "Evergreen" {
                { Convert-Segment -Segment "" } | Should -Not -Throw
            }
        }

        It "Should throw with null value" {
            { Convert-Segment -Segment $null } | Should -Throw
        }
    }
}
