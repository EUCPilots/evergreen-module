<#
    .SYNOPSIS
        Pester tests for Get-JetBrainsApp.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-JetBrainsApp" {
        BeforeEach {
            $res = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Update = [PSCustomObject]@{
                        Uri            = "https://data.example.com/releases?code=#ReplaceEdition&latest"
                        ReplaceEdition = "#ReplaceEdition"
                        DatePattern    = "yyyy-MM-dd"
                        Editions       = [ordered]@{
                            "PyCharm Community"    = "PCC"
                            "PyCharm Professional" = "PCP"
                        }
                    }
                }
            }
            $script:TestJetBrainsCalls = @()
            $script:TestJetBrainsFeed = [PSCustomObject]@{
                PCC = [PSCustomObject]@{
                    version   = "2025.1"
                    build     = "251.1"
                    date      = "2025-04-01"
                    downloads = [PSCustomObject]@{
                        windows = [PSCustomObject]@{
                            link         = "https://download.example.com/pycharm-community.exe"
                            checksumLink = "https://download.example.com/pycharm-community.exe.sha256"
                            size         = 1234
                        }
                        windowsZip = [PSCustomObject]@{
                            link = "https://download.example.com/pycharm-community.zip"
                            size = 1235
                        }
                        windowsARM64 = [PSCustomObject]@{
                            link = "https://download.example.com/pycharm-community-arm64.exe"
                            size = 1236
                        }
                        windowsZipARM64 = [PSCustomObject]@{
                            link = "https://download.example.com/pycharm-community-arm64.zip"
                            size = 1237
                        }
                    }
                }
                PCP = [PSCustomObject]@{
                    version   = "2025.1"
                    build     = "251.1"
                    date      = "2025-04-01"
                    downloads = [PSCustomObject]@{
                        windows = [PSCustomObject]@{
                            link = "https://download.example.com/pycharm-professional.exe"
                            size = 2345
                        }
                    }
                }
            }
            $script:TestJetBrainsFeed.PCC = @($script:TestJetBrainsFeed.PCC)
            $script:TestJetBrainsFeed.PCP = @($script:TestJetBrainsFeed.PCP)
            Mock Invoke-EvergreenRestMethod {
                param ($Uri)
                $script:TestJetBrainsCalls += $Uri
                if ($Uri -like "*.sha256") {
                    return "abcdef0123456789  pycharm-community.exe"
                }
                return $script:TestJetBrainsFeed
            }
        }

        It "Requests all configured editions in one feed call" {
            $Results = @(Get-JetBrainsApp -res $res)

            $script:TestJetBrainsCalls.Count | Should -Be 2
            $script:TestJetBrainsCalls[0] | Should -Be "https://data.example.com/releases?code=PCC,PCP&latest"
            $Results.Count | Should -Be 5
            $Results[0].Edition | Should -Be "PyCharm Community"
            $Results[0].Sha256 | Should -Be "abcdef0123456789"
            $Results[0].URI | Should -Be "https://download.example.com/pycharm-community.exe"
            $Results[1].URI | Should -Be "https://download.example.com/pycharm-community.zip"
            $Results[2].URI | Should -Be "https://download.example.com/pycharm-community-arm64.exe"
            $Results[3].URI | Should -Be "https://download.example.com/pycharm-community-arm64.zip"
            $Results[4].Sha256 | Should -BeNullOrEmpty
        }

        It "Replaces the edition placeholder literally" {
            $res.Get.Update.Uri = "https://data.example.com/releases?code=#Edition.&latest"
            $res.Get.Update.ReplaceEdition = "#Edition."
            $res.Get.Update.Editions = [ordered]@{ "PyCharm Community" = "PCC" }

            $null = @(Get-JetBrainsApp -res $res)

            $script:TestJetBrainsCalls[0] | Should -Be "https://data.example.com/releases?code=PCC&latest"
        }

        It "Warns and skips an edition missing from the response" {
            $script:TestJetBrainsFeed = [PSCustomObject]@{
                PCC = $script:TestJetBrainsFeed.PCC
            }

            $Results = Get-JetBrainsApp -res $res -WarningVariable Warnings

            $Results.Count | Should -Be 4
            $Warnings[0] | Should -Match "PyCharm Professional"
        }

        It "Leaves the checksum empty when checksum retrieval fails" {
            Mock Invoke-EvergreenRestMethod {
                param ($Uri)
                if ($Uri -like "*.sha256") {
                    throw "Checksum request failed."
                }
                return $script:TestJetBrainsFeed
            }

            $Results = @(Get-JetBrainsApp -res $res -WarningVariable Warnings)

            $Results[0].Sha256 | Should -BeNullOrEmpty
            $Results[0].Sha256 | Should -Not -Be $Results[0].URI
            $Warnings[0] | Should -Match "Checksum request failed"
        }

        It "Warns and skips a release without downloads" {
            $script:TestJetBrainsFeed.PCC[0].downloads = $null

            $Results = @(Get-JetBrainsApp -res $res -WarningVariable Warnings)

            $Results.Count | Should -Be 1
            $Results[0].Edition | Should -Be "PyCharm Professional"
            $Warnings[0] | Should -Match "No Windows download link"
        }

        It "Warns and skips a release without supported Windows links" {
            $script:TestJetBrainsFeed.PCC[0].downloads = [PSCustomObject]@{
                windows = [PSCustomObject]@{ link = " " }
                linux = [PSCustomObject]@{ link = "https://download.example.com/pycharm.tar.gz" }
            }

            $Results = @(Get-JetBrainsApp -res $res -WarningVariable Warnings)

            $Results.Count | Should -Be 1
            $Results[0].Edition | Should -Be "PyCharm Professional"
            $Warnings[0] | Should -Match "No Windows download link"
        }

        It "Rejects release data missing its version or date" {
            $script:TestJetBrainsFeed.PCC[0].version = $null

            { Get-JetBrainsApp -res $res } | Should -Throw "*PyCharm Community*missing the version or date*"
        }
    }
}
