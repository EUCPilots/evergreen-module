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

Describe -Name "ConvertFrom-IniFile" {
    Context "Ensure ConvertFrom-IniFile works as expected" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                $Ini = Get-Content -Path "$env:GITHUB_WORKSPACE\tests\Test.ini"
                { ConvertFrom-IniFile -InputObject $Ini } | Should -Not -Throw
            }
        }

        It "Returns a hashtable from an INI file" {
            InModuleScope -ModuleName "Evergreen" {
                $Ini = Get-Content -Path "$env:GITHUB_WORKSPACE\tests\Test.ini"
                (ConvertFrom-IniFile -InputObject $Ini) | Should -BeOfType [Hashtable]
            }
        }
    }
}
