<#
    .SYNOPSIS
        Shared Pester function tests.
#>
[OutputType()]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe "Get-ElgatoApp" {
        BeforeEach {
            $script:ElgatoFeed = [PSCustomObject]@{
                stable = @(
                    [PSCustomObject]@{
                        version    = "1.2.3"
                        downloadUrl = "https://example.test/Elgato-1.2.3-x64.msi"
                    }
                )
                beta = @(
                    [PSCustomObject]@{
                        version  = "2.0.0-beta"
                        fileURLs = [PSCustomObject]@{
                            windows = "https://example.test/Elgato-2.0.0-x64.exe"
                            mac     = "https://example.test/Elgato-2.0.0-arm64.pkg"
                        }
                    }
                )
            }
            $script:ElgatoResource = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Update = [PSCustomObject]@{
                        Uri      = "https://updates.example.test/feed"
                        Property = @("stable", "beta")
                    }
                }
            }
            Mock Invoke-EvergreenRestMethod { $script:ElgatoFeed }
            Mock Resolve-SystemNetWebRequest {
                [PSCustomObject]@{
                    ResponseUri = [System.Uri]($Uri + "?resolved=1")
                }
            }
            Mock Get-Architecture { "x64" }
            Mock Get-FileType { "installer" }
        }

        It "Returns stable single-URL releases and resolves each beta file URL" {
            $Result = @(Get-ElgatoApp -res $script:ElgatoResource)

            $Result.Count | Should -Be 3
            $Result[0].Version | Should -Be "1.2.3"
            $Result[0].Release | Should -Be "Stable"
            $Result[0].URI | Should -Be "https://example.test/Elgato-1.2.3-x64.msi"
            $X64Release = $Result | Where-Object URI -Like "*x64.exe*"
            $Arm64Release = $Result | Where-Object URI -Like "*arm64.pkg*"
            $X64Release.Release | Should -Be "Beta"
            $X64Release.URI | Should -Be "https://example.test/Elgato-2.0.0-x64.exe?resolved=1"
            $Arm64Release.URI | Should -Be "https://example.test/Elgato-2.0.0-arm64.pkg?resolved=1"
            $Arm64Release.Architecture | Should -Be "x64"
            Should -Invoke Resolve-SystemNetWebRequest -Times 2 -Exactly
        }

        It "Returns no releases when the update feed is null" {
            Mock Invoke-EvergreenRestMethod { $null }

            @(Get-ElgatoApp -res $script:ElgatoResource) | Should -BeNullOrEmpty
        }
    }
}
