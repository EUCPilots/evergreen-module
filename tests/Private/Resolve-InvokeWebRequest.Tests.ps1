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
    Describe -Name "Resolve-InvokeWebRequest" {
        Context "Ensure Resolve-InvokeWebRequest works as expected" {
            It "Returns data from a URL" {
                $params = @{
                    Uri                = "https://aka.ms"
                    UserAgent          = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
                    MaximumRedirection = 0
                }
                Resolve-InvokeWebRequest @params | Should -BeOfType [System.String]
            }

            It "Should throw with an invalid URL" {
                { Resolve-InvokeWebRequest -Uri "https://nonsense.git" -WarningAction "SilentlyIgnore" } | Should -Throw
            }

            It "Should throw with an invalid proxy server " {
                Set-ProxyEnv -Proxy "test.local"
                { Resolve-InvokeWebRequest -Uri "https://example.com" -WarningAction "SilentlyIgnore" } | Should -Throw
                Remove-ProxyEnv
            }
        }
    }
}
