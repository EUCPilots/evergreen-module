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
        BeforeEach {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    rate = [PSCustomObject]@{
                        limit     = 60
                        remaining = 42
                        reset     = 1760000000
                    }
                }
            }

            $script:OriginalGitHubToken = [System.Environment]::GetEnvironmentVariable("GITHUB_TOKEN", "Process")
            $script:OriginalGhToken = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "Process")
            [System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", $null, "Process")
            [System.Environment]::SetEnvironmentVariable("GH_TOKEN", $null, "Process")
        }

        AfterEach {
            [System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", $script:OriginalGitHubToken, "Process")
            [System.Environment]::SetEnvironmentVariable("GH_TOKEN", $script:OriginalGhToken, "Process")
        }

        It "Returns the rate data from a valid response" {
            $result = Get-GitHubRateLimit

            $result.limit | Should -Be 60
            $result.remaining | Should -Be 42
            $result.reset | Should -Be 1760000000
        }

        It "Warns when no requests remain" {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    rate = [PSCustomObject]@{
                        limit     = 60
                        remaining = 0
                        reset     = 1760000000
                    }
                }
            }

            $warnings = @()
            Get-GitHubRateLimit -WarningVariable warnings | Out-Null

            $warnings | Should -Not -BeNullOrEmpty
        }

        It "Throws when the rate object is missing" {
            Mock Invoke-RestMethod { [PSCustomObject]@{} }

            { Get-GitHubRateLimit } | Should -Throw "*missing the required*"
        }

        It "Throws when the response is null" {
            Mock Invoke-RestMethod { $null }

            { Get-GitHubRateLimit } | Should -Throw "*missing the required*"
        }

        It "Throws when a rate property is missing" {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    rate = [PSCustomObject]@{
                        remaining = 42
                    }
                }
            }

            { Get-GitHubRateLimit } | Should -Throw "*missing the required*"
        }

        It "Throws when a rate value is not an integer" {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    rate = [PSCustomObject]@{
                        remaining = "many"
                        reset     = 1760000000
                    }
                }
            }

            { Get-GitHubRateLimit } | Should -Throw "*invalid*"
        }

        It "Throws when the reset value is outside the supported timestamp range" {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    rate = [PSCustomObject]@{
                        remaining = 42
                        reset     = [long]::MaxValue
                    }
                }
            }

            { Get-GitHubRateLimit } | Should -Throw "*outside the supported Unix timestamp range*"
        }

        It "Uses a non-empty GH_TOKEN when GITHUB_TOKEN is blank" {
            [System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", " ", "Process")
            [System.Environment]::SetEnvironmentVariable("GH_TOKEN", "gh-token-value", "Process")

            Mock Invoke-RestMethod {
                $Headers.Authorization | Should -Be "token gh-token-value"
                [PSCustomObject]@{
                    rate = [PSCustomObject]@{
                        limit     = 60
                        remaining = 42
                        reset     = 1760000000
                    }
                }
            }

            Get-GitHubRateLimit | Out-Null
        }

        It "Prefers GITHUB_TOKEN when both tokens are non-empty" {
            [System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", "github-token-value", "Process")
            [System.Environment]::SetEnvironmentVariable("GH_TOKEN", "gh-token-value", "Process")

            Mock Invoke-RestMethod {
                $Headers.Authorization | Should -Be "token github-token-value"
                [PSCustomObject]@{
                    rate = [PSCustomObject]@{
                        limit     = 60
                        remaining = 42
                        reset     = 1760000000
                    }
                }
            }

            Get-GitHubRateLimit | Out-Null
        }

        It "Propagates API request errors" {
            Mock Invoke-RestMethod { throw "GitHub request failed" }

            { Get-GitHubRateLimit } | Should -Throw "*GitHub request failed*"
        }
    }
}
