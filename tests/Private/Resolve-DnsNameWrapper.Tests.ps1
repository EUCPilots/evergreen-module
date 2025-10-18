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

Describe -Name "Resolve-DnsNameWrapper" {
    Context "Ensure Resolve-DnsNameWrapper works as expected" {
        It "Returns DNS records OK" {
            InModuleScope -ModuleName "Evergreen" {
                $params = @{
                    Name = "github.com"
                    Type = "TXT"
                }
                Resolve-DnsNameWrapper @params | Should -BeOfType [System.String]
            }
        }
    }
}
