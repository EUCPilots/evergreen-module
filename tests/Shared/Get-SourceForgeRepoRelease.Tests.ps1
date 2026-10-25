<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-SourceForgeRepoRelease" {
        BeforeEach {
            $script:TestSourceForgeRelease = [PSCustomObject]@{
                release           = [PSCustomObject]@{}
                platform_releases = [PSCustomObject]@{
                    windows = [PSCustomObject]@{
                        filename = "/project/example/files/App/2.4/App-2.4.exe/download"
                        url      = "https://sourceforge.net/projects/example/files/App/2.4/App-2.4.exe/download"
                    }
                }
            }
            $script:TestSourceForgeFeed = @(
                [PSCustomObject]@{
                    link        = "https://sourceforge.net/projects/example/files/App/2.4/App-2.4.exe/download"
                    description = [PSCustomObject]@{
                        "#cdata-section" = "App 2.4.exe"
                    }
                    content     = [PSCustomObject]@{
                        filesize = 1234
                        hash     = [PSCustomObject]@{
                            "#text" = "abc123"
                        }
                    }
                }
            )
            $script:TestSourceForgeDownload = @{
                Feed         = "https://sourceforge.net/projects/example/rss?path="
                ContentType  = "application/rss+xml; charset=utf-8"
                ReplaceText  = @{ Link = "/download" }
                MatchFileTypes = "\.exe$|\.msi$"
            }
            Mock Invoke-EvergreenRestMethod {
                param ($Uri)
                if ($Uri -like "*best_release.json") {
                    $script:TestSourceForgeRelease
                }
                else {
                    $script:TestSourceForgeFeed
                }
            }
            Mock Resolve-SystemNetWebRequest {
                [PSCustomObject]@{
                    ResponseUri = [System.Uri]"https://mirror.example:8443/project/example/files/App/2.4/App-2.4.exe"
                }
            }
        }

        It "Returns formatted release metadata and preserves the resolved mirror URI" {
            $Results = @(Get-SourceForgeRepoRelease `
                -Uri "https://sourceforge.net/projects/example/best_release.json" `
                -Download $script:TestSourceForgeDownload `
                -MatchVersion "(\d+(\.\d+){1,3})")

            $Results.Count | Should -Be 1
            $Results[0].Version | Should -Be "2.4"
            $Results[0].Type | Should -Be "exe"
            $Results[0].Size | Should -Be 1234
            $Results[0].Md5 | Should -Be "abc123"
            $Results[0].FileName | Should -Be "App 2.4.exe"
            $Results[0].URI | Should -Be "https://mirror.example:8443/project/example/files/App/2.4/App%202.4.exe?viasf=1"
        }

        It "Encodes reserved characters in the downloaded filename" {
            $script:TestSourceForgeFeed[0].description."#cdata-section" = "App #2?.exe"

            $Results = @(Get-SourceForgeRepoRelease `
                -Uri "https://sourceforge.net/projects/example/best_release.json" `
                -Download $script:TestSourceForgeDownload `
                -MatchVersion "(\d+(\.\d+){1,3})")

            $Results[0].URI | Should -Be "https://mirror.example:8443/project/example/files/App/2.4/App%20%232%3F.exe?viasf=1"
        }

        It "Rejects a release response missing required properties" {
            $script:TestSourceForgeRelease = [PSCustomObject]@{
                release = [PSCustomObject]@{}
            }

            {
                Get-SourceForgeRepoRelease `
                    -Uri "https://sourceforge.net/projects/example/best_release.json" `
                    -Download $script:TestSourceForgeDownload `
                    -MatchVersion "(\d+(\.\d+){1,3})"
            } | Should -Throw "*platform_releases*"
        }

        It "Rejects a release path without a matching version" {
            $script:TestSourceForgeRelease.platform_releases.windows.filename = "/project/example/files/App/latest/App.exe/download"

            {
                Get-SourceForgeRepoRelease `
                    -Uri "https://sourceforge.net/projects/example/best_release.json" `
                    -Download $script:TestSourceForgeDownload `
                    -MatchVersion "version-(\d+)"
            } | Should -Throw "*Failed to find a version*"
        }

        It "Rejects a feed with no matching file items" {
            $script:TestSourceForgeFeed = @()

            {
                Get-SourceForgeRepoRelease `
                    -Uri "https://sourceforge.net/projects/example/best_release.json" `
                    -Download $script:TestSourceForgeDownload `
                    -MatchVersion "(\d+(\.\d+){1,3})"
            } | Should -Throw "*No SourceForge feed items matched*"
        }
    }
}
