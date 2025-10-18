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
    Describe -Name "Get-GitHubRepoRelease" {
        Context "Throw scenarios" {
            It "Does not throw when passed a correct URL" {
                # Params for Get-GitHubRepoRelease
                $params = @{
                    Uri          = "https://api.github.com/repos/atom/atom/releases/latest"
                    MatchVersion = "(\d+(\.\d+){1,4}).*"
                }
                { Get-GitHubRepoRelease @params } | Should -Not -Throw
            }

            It "Should throw when passed an incorrect URL" {
                # Params for Get-GitHubRepoRelease
                $params = @{
                    Uri          = "https://api.example.com/repos/atom/atom/releases/latest"
                    MatchVersion = "(\d+(\.\d+){1,4}).*"
                }
                { Get-GitHubRepoRelease @params } | Should -Throw
            }

            It "Should throw with an invalid proxy server " {
                Set-ProxyEnv -Proxy "test.local"
                $params = @{
                    Uri          = "https://api.github.com/repos/atom/atom/releases/latest"
                    MatchVersion = "(\d+(\.\d+){1,4}).*"
                }
                { Get-GitHubRepoRelease @params } | Should -Throw
                Remove-ProxyEnv
            }
        }

        Context "It returns an object with the expected properties" {
            BeforeAll {
                # Params for Get-GitHubRepoRelease
                $params = @{
                    Uri          = "https://api.github.com/repos/atom/atom/releases/latest"
                    MatchVersion = "(\d+(\.\d+){1,4}).*"
                }
                $result = Get-GitHubRepoRelease @params
            }

            It "Returns a Version property" {
                $result.Version.Length | Should -BeGreaterThan 0
            }

            It "Returns a Platform property" {
                $result.Platform.Length | Should -BeGreaterThan 0
            }

            It "Returns a Architecture property" {
                $result.Architecture.Length | Should -BeGreaterThan 0
            }

            It "Returns a Type property" {
                $result.Type.Length | Should -BeGreaterThan 0
            }

            It "Returns a Date property" {
                $result.Date.Length | Should -BeGreaterThan 0
            }

            It "Returns a Size property" {
                $result.Size.Length | Should -BeGreaterThan 0
            }

            It "Returns a URI property" {
                $result.URI.Length | Should -BeGreaterThan 0
            }
        }
    }
}
