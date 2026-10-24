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

        It "Extracts the extension from a URL with a query string and fragment" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FileType -File "https://example.com/download/package.msi?token=abc#section" | Should -Be "msi"
            }
        }

        It "Returns null for a URL without a file extension" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FileType -File "https://example.com/download/package?token=abc" | Should -BeNullOrEmpty
            }
        }

        It "Returns null for a dotfile without an extension" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FileType -File ".gitignore" | Should -BeNullOrEmpty
            }
        }

        It "Returns null for a path with a trailing dot" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FileType -File "package." | Should -BeNullOrEmpty
            }
        }

        It "Rejects whitespace-only input" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-FileType -File "   " } | Should -Throw
            }
        }
    }
}
