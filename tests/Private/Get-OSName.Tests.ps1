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
    # Ensure $IsWindows is defined across PowerShell editions (Windows PowerShell and PowerShell Core)
    $IsWindows = [bool]($env:OS -eq 'Windows_NT')

    Context "Validate Get-OSName basic functionality" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-OSName } | Should -Not -Throw
            }
        }

        It "Should return a string" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-OSName
                $Result | Should -BeOfType [string]
            }
        }

        It "Should not return null or empty" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-OSName
                $Result | Should -Not -BeNullOrEmpty
            }
        }

        It "Should return Windows on Windows platform" -Skip:(-not $IsWindows) {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-OSName
                $Result | Should -Match "Windows"
            }
        }

        It "Should return macOS or Linux on non-Windows platform" -Skip:($IsWindows) {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-OSName
                $Result | Should -Match "macOS|Linux"
            }
        }
    }
}
