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
                Get-ModuleResource | Should -BeOfType [System.Collections.IDictionary]
            }
        }

        It "Given an invalid path, it throws" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-ModuleResource -Path "C:\Temp\test.txt" } | Should -Throw
            }
        }

        It "Treats wildcard characters in the path literally" {
            InModuleScope -ModuleName "Evergreen" {
                $Path = Join-Path -Path (Get-Module -Name "Evergreen").ModuleBase -ChildPath "Evergreen.jso?"
                { Get-ModuleResource -Path $Path } | Should -Throw
            }
        }

        It "Throws when the resource file contains malformed JSON" {
            $Path = Join-Path -Path $TestDrive -ChildPath "Malformed.json"
            Set-Content -LiteralPath $Path -Value "{ invalid json" -Encoding UTF8

            InModuleScope -ModuleName "Evergreen" -Parameters @{ ResourcePath = $Path } {
                { Get-ModuleResource -Path $ResourcePath } | Should -Throw
            }
        }

        It "Throws when the JSON root is not an object" {
            $Path = Join-Path -Path $TestDrive -ChildPath "UnexpectedRoot.json"
            Set-Content -LiteralPath $Path -Value '["not", "an", "object"]' -Encoding UTF8

            InModuleScope -ModuleName "Evergreen" -Parameters @{ ResourcePath = $Path } {
                { Get-ModuleResource -Path $ResourcePath } | Should -Throw "*root must be a JSON object*"
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
