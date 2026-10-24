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

        It "Should return an integer" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Convert-Segment -Segment "test"
                $Result | Should -BeOfType [int]
            }
        }

        It "Should convert numeric segments within the Int32 range exactly" {
            InModuleScope -ModuleName "Evergreen" {
                Convert-Segment -Segment "2147483647" | Should -Be 2147483647
            }
        }

        It "Should handle alphanumeric segments" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Convert-Segment -Segment "abc123"
                $Result | Should -BeOfType [int]
                $Result | Should -BeGreaterOrEqual 0
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
                Convert-Segment -Segment "" | Should -Be 0
            }
        }

        It "Should throw with null value" {
            InModuleScope -ModuleName "Evergreen" {
                { Convert-Segment -Segment $null } | Should -Throw -ExceptionType ([System.ArgumentNullException])
            }
        }

        It "Should throw when a numeric segment exceeds the Int32 range" {
            InModuleScope -ModuleName "Evergreen" {
                { Convert-Segment -Segment "2147483648" } | Should -Throw -ExceptionType ([System.OverflowException])
            }
        }

        It "Should return a bounded integer for long and Unicode segments" {
            InModuleScope -ModuleName "Evergreen" {
                $LongSegment = Convert-Segment -Segment ("x" * 1000)
                $UnicodeSegment = Convert-Segment -Segment "版本"

                $LongSegment | Should -BeOfType [int]
                $LongSegment | Should -BeGreaterOrEqual 0
                $UnicodeSegment | Should -BeOfType [int]
                $UnicodeSegment | Should -BeGreaterOrEqual 0
            }
        }
    }
}
