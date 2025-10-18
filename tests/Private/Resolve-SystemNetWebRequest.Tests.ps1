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

Describe -Name "Resolve-SystemNetWebRequest" {
    Context "Ensure Resolve-SystemNetWebRequest works as expected" {
        It "Returns data from a URL" {
            InModuleScope -ModuleName "Evergreen" {
                $params = @{
                    Uri                = "https://github.com"
                    MaximumRedirection = 1
                }
                (Resolve-SystemNetWebRequest @params).ResponseUri | Should -BeOfType [System.Uri]
            }
        }
    }
}
