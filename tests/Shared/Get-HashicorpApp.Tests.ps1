<#
    .SYNOPSIS
        Pester tests for Get-HashicorpApp.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-HashicorpApp" {
        BeforeEach {
            $res = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Update = [PSCustomObject]@{
                        Uri              = "https://api.github.com/repos/hashicorp/boundary/releases/latest"
                        MatchVersion     = "(\d+(\.\d+){1,4}).*"
                        MatchFileTypes   = "\.exe$"
                    }
                    Download = [PSCustomObject]@{
                        Uri = @{
                            x64 = "https://releases.hashicorp.com/boundary/#version/boundary_#version_windows_amd64.zip"
                            x86 = "https://releases.hashicorp.com/boundary/#version/boundary_#version_windows_386.zip"
                        }
                        ReplaceText = "#version"
                    }
                }
            }
            Mock Get-GitHubRepoRelease {
                [PSCustomObject]@{
                    Version = "1.2.3"
                }
            }
        }

        It "Returns versioned download URLs with architecture keys" {
            $Results = @(Get-HashicorpApp -res $res)

            $Results.Count | Should -Be 2
            $Results[0].Architecture | Should -Be "x64"
            $Results[0].URI | Should -Be "https://releases.hashicorp.com/boundary/1.2.3/boundary_1.2.3_windows_amd64.zip"
            $Results[1].Architecture | Should -Be "x86"
            $Results[1].URI | Should -Be "https://releases.hashicorp.com/boundary/1.2.3/boundary_1.2.3_windows_386.zip"
            $Results.Type | Should -Be @("zip", "zip")
        }

        It "Stops when GitHub is rate limited" {
            Mock Get-GitHubRepoRelease {
                [PSCustomObject]@{
                    Version = "RateLimited"
                }
            }

            { Get-HashicorpApp -res $res } | Should -Throw "*rate limit reached*"
        }

        It "Rejects an invalid rendered download URI" {
            $res.Get.Download.Uri.x64 = "file:///download/#version.zip"

            { Get-HashicorpApp -res $res } | Should -Throw "*not a valid HTTP or HTTPS URI*"
        }

        It "Rejects missing download templates" {
            $res.Get.Download.Uri = @{}

            { Get-HashicorpApp -res $res } | Should -Throw "*Get.Download.Uri*"
        }
    }
}
