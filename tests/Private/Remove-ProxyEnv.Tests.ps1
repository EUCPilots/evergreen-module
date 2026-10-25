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
    Context "Tests that proxy configuration is removed" {
        It "Removes proxy and credential state" {
            InModuleScope -ModuleName "Evergreen" {
                $Credential = [System.Management.Automation.PSCredential]::new(
                    "proxy-user",
                    (ConvertTo-SecureString -String "proxy-pass" -AsPlainText -Force)
                )
                Set-ProxyEnv -Proxy "proxyserver" -ProxyCredential $Credential

                Remove-ProxyEnv

                Test-ProxyEnv | Should -BeFalse
                Test-ProxyEnv -Creds | Should -BeFalse
            }
        }

        It "Does not throw when proxy state is already absent" {
            InModuleScope -ModuleName "Evergreen" {
                Remove-ProxyEnv

                { Remove-ProxyEnv } | Should -Not -Throw
            }
        }
    }

    AfterAll {
        InModuleScope -ModuleName "Evergreen" {
            Remove-ProxyEnv
        }
    }
}
