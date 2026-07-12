<#
    .SYNOPSIS
        Pester tests for Get-GitLabRepoRelease.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-GitLabRepoRelease" {
        BeforeEach {
            $script:resourceStrings = [PSCustomObject]@{
                Properties = [PSCustomObject]@{
                    GitLab = $null
                }
            }

            Mock -CommandName Get-EvergreenUserAgent -MockWith {
                return "Evergreen-Pester-Agent"
            }

            Mock -CommandName Test-ProxyEnv -MockWith {
                return $false
            }

            Mock -CommandName ConvertTo-DateTime -MockWith {
                param (
                    [System.String] $DateTime,
                    [System.String] $Pattern
                )
                return "07/12/2026 12:00:00"
            }

            Mock -CommandName Get-Platform -MockWith {
                return "Windows"
            }

            Mock -CommandName Get-Architecture -MockWith {
                return "x64"
            }

            Mock -CommandName Get-InstallerType -MockWith {
                return "MSI"
            }
        }

        Context "Throw scenarios" {
            It "Does not throw when passed a correct URL" {
                Mock -CommandName Invoke-RestMethod -MockWith {
                    return [PSCustomObject]@{
                        tag_name   = "v1.2.3"
                        created_at = "2026-07-01T10:00:00Z"
                        assets     = [PSCustomObject]@{
                            links = @(
                                [PSCustomObject]@{
                                    name             = "app-x64.msi"
                                    direct_asset_url = "https://gitlab.example.com/downloads/app-x64.msi"
                                    url              = "https://gitlab.example.com/downloads/app-x64.msi"
                                }
                            )
                        }
                    }
                }

                $params = @{
                    Uri    = "https://gitlab.com/api/v4/projects/123/releases/latest"
                    Filter = "\.msi$"
                }

                { Get-GitLabRepoRelease @params } | Should -Not -Throw
            }

            It "Should throw when passed an incorrect URL" {
                $params = @{
                    Uri = "https://api.example.com/projects/123/releases/latest"
                }

                { Get-GitLabRepoRelease @params } | Should -Throw
            }
        }

        Context "ReturnVersionOnly scenarios" {
            It "Returns version from releases endpoint" {
                Mock -CommandName Invoke-RestMethod -MockWith {
                    return [PSCustomObject]@{
                        tag_name   = "v5.4.3"
                        created_at = "2026-07-01T10:00:00Z"
                        assets     = [PSCustomObject]@{
                            links = @()
                        }
                    }
                }

                $params = @{
                    Uri               = "https://gitlab.com/api/v4/projects/123/releases/latest"
                    MatchVersion      = "(\d+(\.\d+){1,4}).*"
                    ReturnVersionOnly = $true
                }

                $result = Get-GitLabRepoRelease @params
                $result.Version | Should -Be "5.4.3"
            }

            It "Returns version from repository tags endpoint" {
                Mock -CommandName Invoke-RestMethod -MockWith {
                    return @(
                        [PSCustomObject]@{
                            name = "release-7.8.9"
                        }
                    )
                }

                $params = @{
                    Uri               = "https://gitlab.com/api/v4/projects/123/repository/tags"
                    MatchVersion      = "(\d+(\.\d+){1,4}).*"
                    ReturnVersionOnly = $true
                }

                $result = Get-GitLabRepoRelease @params
                $result.Version | Should -Be "7.8.9"
            }
        }

        Context "Object output scenarios" {
            It "Returns an object with expected properties from assets links" {
                Mock -CommandName Invoke-RestMethod -MockWith {
                    return [PSCustomObject]@{
                        tag_name    = "v3.2.1"
                        created_at  = "2026-07-01T10:00:00Z"
                        released_at = "2026-07-02T09:00:00Z"
                        assets      = [PSCustomObject]@{
                            links = @(
                                [PSCustomObject]@{
                                    name             = "tool-x64.msi"
                                    direct_asset_url = "https://gitlab.example.com/downloads/tool-x64.msi"
                                    url              = "https://gitlab.example.com/downloads/tool-x64.msi"
                                }
                            )
                            sources = @()
                        }
                    }
                }

                $params = @{
                    Uri          = "https://gitlab.com/api/v4/projects/123/releases/latest"
                    MatchVersion = "(\d+(\.\d+){1,4}).*"
                    Filter       = "\.msi$"
                }

                $result = Get-GitLabRepoRelease @params | Select-Object -First 1

                $result.Version | Should -Be "3.2.1"
                $result.Date | Should -Not -BeNullOrEmpty
                $result.Architecture | Should -Be "x64"
                $result.InstallerType | Should -Be "MSI"
                $result.Type | Should -Be "msi"
                $result.URI | Should -Be "https://gitlab.example.com/downloads/tool-x64.msi"
            }
        }
    }
}
