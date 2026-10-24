<#
    .SYNOPSIS
        Pester tests for Get-OperaApp.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-OperaApp" {
        BeforeEach {
            $res = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Update = [PSCustomObject]@{
                        Uri      = [ordered]@{
                            Stable = "https://update.example.com/stable"
                            Beta   = "https://update.example.com/beta"
                        }
                        Channels = @("Stable", "Beta")
                        Property = "current_version"
                    }
                    Download = [PSCustomObject]@{
                        Uri          = [ordered]@{
                            Stable = "https://download.example.com/stable/#version/Opera_#version#architecture.exe"
                            Beta   = "https://download.example.com/beta/#version/Opera_beta_#version#architecture.exe"
                        }
                        Architecture = [ordered]@{
                            x64 = "_x64"
                            x86 = ""
                        }
                        Architectures = @("x64", "x86")
                    }
                }
            }
            $script:TestOperaRequestUris = @()
            Mock Invoke-EvergreenRestMethod {
                param ($Uri)
                $script:TestOperaRequestUris += $Uri
                [PSCustomObject]@{ current_version = "90.0.4254.19" }
            }
            Mock Get-FileType { "exe" }
        }

        It "Returns one result for each configured channel and architecture" {
            $Results = @(Get-OperaApp -res $res)

            $Results.Count | Should -Be 4
            $script:TestOperaRequestUris | Should -Be @(
                "https://update.example.com/stable",
                "https://update.example.com/beta"
            )
            $Results[0].Version | Should -Be "90.0.4254.19"
            $Results[0].Channel | Should -Be "Stable"
            $Results[0].Architecture | Should -Be "x64"
            $Results[0].Type | Should -Be "exe"
            $Results[0].URI | Should -Be "https://download.example.com/stable/90.0.4254.19/Opera_90.0.4254.19_x64.exe"
            $Results[1].URI | Should -Be "https://download.example.com/stable/90.0.4254.19/Opera_90.0.4254.19.exe"
            $Results[2].Channel | Should -Be "Beta"
        }

        It "Allows Stable-only manifests" {
            $res.Get.Update.Channels = @("Stable")
            $res.Get.Download.Architectures = @("x64")

            $Results = @(Get-OperaApp -res $res)

            $Results.Count | Should -Be 1
            $Results[0].Channel | Should -Be "Stable"
        }

        It "Replaces version text literally" {
            Mock Invoke-EvergreenRestMethod {
                [PSCustomObject]@{ current_version = '$&.1' }
            }

            $Results = @(Get-OperaApp -res $res)

            $Results[0].URI | Should -Be "https://download.example.com/stable/$&.1/Opera_$&.1_x64.exe"
        }

        It "Rejects an empty update version" {
            Mock Invoke-EvergreenRestMethod {
                [PSCustomObject]@{ current_version = " " }
            }

            { Get-OperaApp -res $res } | Should -Throw "*missing a non-empty 'current_version'*"
        }

        It "Rejects an update response missing the configured version property" {
            Mock Invoke-EvergreenRestMethod {
                [PSCustomObject]@{ version = "90.0.4254.19" }
            }

            { Get-OperaApp -res $res } | Should -Throw "*missing a non-empty 'current_version'*"
        }

        It "Rejects an empty update response" {
            Mock Invoke-EvergreenRestMethod { $null }

            { Get-OperaApp -res $res } | Should -Throw "*update response for channel 'Stable' is empty*"
        }

        It "Rejects a channel without an update URI" {
            $res.Get.Update.Uri.Remove("Stable")

            { Get-OperaApp -res $res } | Should -Throw "*missing the update URI for channel 'Stable'*"
        }

        It "Rejects a channel without a download URI" {
            $res.Get.Download.Uri.Remove("Stable")

            { Get-OperaApp -res $res } | Should -Throw "*missing the download URI for channel 'Stable'*"
        }

        It "Rejects a download URI missing a required placeholder" {
            $res.Get.Download.Uri.Stable = "https://download.example.com/stable/Opera_#architecture.exe"

            { Get-OperaApp -res $res } | Should -Throw "*missing the #version placeholder*"
        }

        It "Rejects an architecture without a mapping" {
            $res.Get.Download.Architectures = @("arm64")

            { Get-OperaApp -res $res } | Should -Throw "*missing the download architecture mapping for 'arm64'*"
        }
    }
}
