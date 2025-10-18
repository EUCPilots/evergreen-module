<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Name "Remove-ProxyEnv" {
    BeforeAll {
        InModuleScope -ModuleName "Evergreen" {
            #Set-ProxyEnv -Proxy "proxyserver"
        }
    }

    Context "Tests that Remove-ProxyEnv does not throw" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                { Remove-ProxyEnv } | Should -Not -Throw
            }
        }
    }

    AfterAll {
    }
}
