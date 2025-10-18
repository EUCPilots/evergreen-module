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

Describe -Name "ConvertTo-DateTime" {
    Context "Format and return a datetime string" {
        It "Correctly formats the provided datetime" {
            InModuleScope -ModuleName "Evergreen" {
                (ConvertTo-DateTime -DateTime "2000/14/2" -Pattern "yyyy/d/M").Split("/")[-1] | Should -Be "2000"
            }
        }
    }
}
