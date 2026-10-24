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

Describe -Name "Set-ProxyEnv" {
    BeforeAll {
    }

    Context "Tests that Set-ProxyEnv does not throw" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                { Set-ProxyEnv -Proxy "proxyserver" } | Should -Not -Throw
            }
        }
    }

    Context "Tests that the proxy server was set" {
        It "Returns True if proxy server is set" {
            InModuleScope -ModuleName "Evergreen" {
                Set-ProxyEnv -Proxy "proxyserver"
                Test-ProxyEnv | Should -BeTrue
            }
        }
    }

    Context "Tests that proxy configuration is replaced" {
        It "Clears credentials when setting a new proxy without credentials" {
            InModuleScope -ModuleName "Evergreen" {
                $Credential = [System.Management.Automation.PSCredential]::new(
                    "proxy-user",
                    (ConvertTo-SecureString -String "proxy-pass" -AsPlainText -Force)
                )
                Set-ProxyEnv -Proxy "first-proxy" -ProxyCredential $Credential
                Set-ProxyEnv -Proxy "second-proxy"

                $script:EvergreenProxy | Should -Be "second-proxy"
                Test-ProxyEnv -Creds | Should -BeFalse
            }
        }

        It "Does not set proxy state when WhatIf is specified" {
            InModuleScope -ModuleName "Evergreen" {
                Remove-ProxyEnv
                Set-ProxyEnv -Proxy "proxyserver" -WhatIf
                Test-ProxyEnv | Should -BeFalse
            }
        }

        It "Rejects an empty proxy value" {
            InModuleScope -ModuleName "Evergreen" {
                { Set-ProxyEnv -Proxy "" } | Should -Throw
            }
        }
    }

    AfterAll {
        InModuleScope -ModuleName "Evergreen" {
            Remove-ProxyEnv
        }
    }
}
