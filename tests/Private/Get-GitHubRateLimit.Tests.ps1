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

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-GitHubRateLimit" {
        Context "Throw scenarios" {
            It "Should throw with an invalid proxy server " {
                Set-ProxyEnv -Proxy "test.local"
                { Get-GitHubRateLimit } | Should -Throw
                Remove-ProxyEnv
            }
        }

        Context "Working scenarios" {
            It "Should return the expected result" {
                (Get-GitHubRateLimit).limit | Should -BeGreaterOrEqual 60
            }
        }
    }
}
