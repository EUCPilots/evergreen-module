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

Describe -Name "Test-ProxyEnv" {
    BeforeAll {
    }

    Context "Tests that Test-ProxyEnv returns true when testing proxy environment" {
        It "Returns True if proxy server is set" {
            InModuleScope -ModuleName "Evergreen" {
                Set-ProxyEnv -Proxy "proxyserver"
                Test-ProxyEnv | Should -BeTrue
            }
        }

        It "Returns False if proxy credentials are not set" {
            InModuleScope -ModuleName "Evergreen" {
                Test-ProxyEnv -Creds | Should -BeFalse
            }
        }

        It "Checks the proxy when Creds is explicitly false" {
            InModuleScope -ModuleName "Evergreen" {
                Set-ProxyEnv -Proxy "proxyserver"
                Test-ProxyEnv -Creds:$false | Should -BeTrue
            }
        }

        It "Returns False for an empty credential value" {
            InModuleScope -ModuleName "Evergreen" {
                Set-ProxyEnv -Proxy "proxyserver" -ProxyCredential ([System.Management.Automation.PSCredential]::Empty)
                Test-ProxyEnv -Creds | Should -BeFalse
            }
        }
    }

    AfterAll {
        InModuleScope -ModuleName "Evergreen" {
            Remove-ProxyEnv
        }
    }
}
