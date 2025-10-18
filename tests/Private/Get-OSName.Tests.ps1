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

Describe -Tag "Private" -Name "Get-OSName" {
    Context "Validate Get-OSName basic functionality" {
        It "Should not throw" {
            { Get-OSName } | Should -Not -Throw
        }

        It "Should return a string" {
            $Result = Get-OSName
            $Result | Should -BeOfType [string]
        }

        It "Should not return null or empty" {
            $Result = Get-OSName
            $Result | Should -Not -BeNullOrEmpty
        }

        It "Should return Windows on Windows platform" -Skip:(-not $IsWindows) {
            $Result = Get-OSName
            $Result | Should -Match "Windows"
        }

        It "Should return macOS or Linux on non-Windows platform" -Skip:($IsWindows) {
            $Result = Get-OSName
            $Result | Should -Match "macOS|Linux"
        }
    }
}
