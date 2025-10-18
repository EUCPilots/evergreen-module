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
    Context "Validate Test-IsWindows basic functionality" {
        It "Should not throw" {
            { Test-IsWindows } | Should -Not -Throw
        }

        It "Should return a boolean value" {
            $Result = Test-IsWindows
            $Result | Should -BeOfType [bool]
        }

        It "Should return true on Windows platform" -Skip:(-not $IsWindows) {
            $Result = Test-IsWindows
            $Result | Should -Be $true
        }

        It "Should return false on non-Windows platform" -Skip:($IsWindows) {
            $Result = Test-IsWindows
            $Result | Should -Be $false
        }
    }
}
