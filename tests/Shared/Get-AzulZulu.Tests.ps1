<#
    .SYNOPSIS
        Pester tests for Get-AzulZulu.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-AzulZulu" {
        BeforeEach {
            $res = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Update = [PSCustomObject]@{
                        Uri         = "https://api.azul.com/metadata/v1/zulu/packages/"
                        ContentType = "application/json"
                    }
                }
            }
            $script:TestAzulZuluReleases = @(
                [PSCustomObject]@{
                    distro_version       = @(25, 0, 2, 0)
                    java_version         = @(25, 0, 2)
                    openjdk_build_number = 1
                    download_url         = "https://cdn.azul.com/zulu/bin/zulu25.30.17-ca-jdk25.0.2-win_x64.msi"
                },
                [PSCustomObject]@{
                    distro_version       = @(25, 0, 2, 0)
                    java_version         = @(25, 0, 2)
                    openjdk_build_number = 1
                    download_url         = "https://cdn.azul.com/gzmetadata/zulu25.30.17-ca-jre25.0.2-win_x64.msi"
                },
                [PSCustomObject]@{
                    distro_version       = @(25, 0, 2, 0)
                    java_version         = @(25, 0, 2)
                    openjdk_build_number = 1
                    download_url         = "https://cdn.azul.com/zulu/bin/zulu25.30.17-ca-fx-jdk25.0.2-win_x64.msi"
                },
                [PSCustomObject]@{
                    distro_version       = @(25, 0, 2, 0)
                    java_version         = @(25, 0, 2)
                    openjdk_build_number = 1
                    download_url         = "https://cdn.azul.com/zulu/bin/zulu25.30.17-ca-jdk25.0.2-win_x64.tar.gz"
                },
                [PSCustomObject]@{
                    distro_version       = @(24, 0, 2, 0)
                    java_version         = @(24, 0, 2)
                    openjdk_build_number = 1
                    download_url         = "https://cdn.azul.com/zulu/bin/zulu24.30.17-ca-jdk24.0.2-win_x64.msi"
                }
            )
            Mock Invoke-EvergreenRestMethod { $script:TestAzulZuluReleases }
        }

        It "Returns latest-version downloads with the expected properties" {
            $Results = @(Get-AzulZulu -res $res)

            $Results.Count | Should -Be 3
            ($Results.Version | Select-Object -Unique) | Should -Be "25.0.2.0"
            ($Results.ImageType | Sort-Object -Unique) | Should -Contain "JDK"
            ($Results.ImageType | Sort-Object -Unique) | Should -Contain "JRE"
            ($Results.ImageType | Sort-Object -Unique) | Should -Contain "JDKFX"
            ($Results.URI -join "`n") | Should -Match "gzmetadata"
            ($Results.URI -join "`n") | Should -Not -Match "\.tar\.gz(?:$|`n)"
            foreach ($Result in $Results) {
                $Result.Version | Should -Not -BeNullOrEmpty
                $Result.JavaVersion | Should -Be "25.0.2+1"
                $Result.Architecture | Should -Be "x64"
                $Result.Type | Should -Be "msi"
                $Result.URI | Should -Not -BeNullOrEmpty
            }
        }

        It "Skips releases with invalid versions and warns" {
            $script:TestAzulZuluReleases += [PSCustomObject]@{
                distro_version = "not-a-version"
                download_url   = "https://cdn.azul.com/zulu/bin/jdk.msi"
            }
            $Warnings = @()

            $Results = @(Get-AzulZulu -res $res -WarningVariable Warnings)

            $Results.Count | Should -Be 3
            ($Warnings -join "`n") | Should -Match "invalid 'distro_version'"
        }

        It "Returns no releases and warns when all versions are invalid" {
            $script:TestAzulZuluReleases = @(
                [PSCustomObject]@{ distro_version = "invalid"; download_url = "https://example.com/jdk.msi" }
            )
            $Warnings = @()

            $Results = @(Get-AzulZulu -res $res -WarningVariable Warnings)

            $Results.Count | Should -Be 0
            ($Warnings -join "`n") | Should -Match "No releases with a valid 'distro_version'"
        }

        It "Skips latest releases with invalid download URLs" {
            $script:TestAzulZuluReleases = @(
                [PSCustomObject]@{ distro_version = @(25, 0, 2, 0); download_url = "" },
                [PSCustomObject]@{ distro_version = @(24, 0, 2, 0); download_url = "https://example.com/jdk.msi" }
            )
            $Warnings = @()

            $Results = @(Get-AzulZulu -res $res -WarningVariable Warnings)

            $Results.Count | Should -Be 0
            ($Warnings -join "`n") | Should -Match "empty 'download_url'"
        }

        It "Reports an unknown architecture instead of defaulting to x86" {
            $script:TestAzulZuluReleases = @(
                [PSCustomObject]@{
                    distro_version = @(25, 0, 2, 0)
                    java_version   = @(25, 0, 2)
                    download_url   = "https://cdn.azul.com/zulu/bin/zulu25.30.17-ca-jdk25.0.2-unrecognized.msi"
                }
            )
            $Warnings = @()

            $Results = @(Get-AzulZulu -res $res -WarningVariable Warnings)

            $Results[0].Architecture | Should -Be "Unknown"
            ($Warnings -join "`n") | Should -Match "Could not determine architecture"
        }
    }
}
