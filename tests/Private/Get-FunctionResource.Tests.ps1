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

Describe -Name "Get-FunctionResource" {
    Context "Ensure function resources are returned" {
        It "Given a valid app it returns valid data" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FunctionResource -AppName "MicrosoftEdge" | Should -BeOfType [System.Object]
            }
        }

        It "Given an invalid application, it throws" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-FunctionResource -AppName "DoesNotExist" } | Should -Throw
            }
        }
    }
}
