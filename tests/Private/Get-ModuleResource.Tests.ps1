<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Name "Get-ModuleResource" {
    Context "Ensure module resources are returned" {
        It "Returns the module resource" {
            InModuleScope -ModuleName "Evergreen" {
                Get-ModuleResource | Should -BeOfType [System.Object]
            }
        }

        It "Given an invalid path, it throws" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-ModuleResource -Path "C:\Temp\test.txt" } | Should -Throw
            }
        }

        It "Returns an object with the expected properties" {
            InModuleScope -ModuleName "Evergreen" {
                (Get-ModuleResource).Uri.Project | Should -Not -BeNullOrEmpty
                (Get-ModuleResource).Uri.Docs | Should -Not -BeNullOrEmpty
                (Get-ModuleResource).Uri.Issues | Should -Not -BeNullOrEmpty
                (Get-ModuleResource).Uri.Info | Should -Not -BeNullOrEmpty
            }
        }
    }
}
