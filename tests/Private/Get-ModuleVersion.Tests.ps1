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

Describe -Tag "Private" -Name "Get-ModuleVersion" {
    Context "Validate Get-ModuleVersion basic functionality" {
        It "Should not throw" {
            { Get-ModuleVersion } | Should -Not -Throw
        }

        It "Should return a version object or string" {
            $Result = Get-ModuleVersion
            $Result | Should -Not -BeNullOrEmpty
        }

        It "Should return a valid version format" {
            $Result = Get-ModuleVersion
            $Result.ToString() | Should -Match "\d+\.\d+\.\d+"
        }
    }
}
