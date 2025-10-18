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

Describe -Name "Get-FileType" {
    Context "Ensure file type is returned" {
        It "Given a file path string it returns the right file type" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FileType -File "test.txt" | Should -Be "txt"
            }
        }

        It "Given an file path string without an extension it returns null" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FileType -File "testtxt" | Should -BeNullOrEmpty
            }
        }
    }
}
