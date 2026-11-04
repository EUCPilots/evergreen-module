<#
    .SYNOPSIS
        Shared Pester function tests.
#>
[OutputType()]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe "Get-OracleJava" {
        BeforeEach {
            $script:OracleFeed = [PSCustomObject]@{
                data = [PSCustomObject]@{
                    releases = @(
                        [PSCustomObject]@{ family = "JavaSE"; status = "delivered"; version = "9.99.0"; fullversion = "9.99.0+1"; ga = "2024-01-01" }
                        [PSCustomObject]@{ family = "JavaSE"; status = "delivered"; version = "10.1.0"; fullversion = "10.1.0+1"; ga = "2025-01-01" }
                        [PSCustomObject]@{ family = "JavaSE"; status = "delivered"; version = "10.2.0"; fullversion = "10.2.0+2"; ga = "2025-06-01" }
                        [PSCustomObject]@{ family = "JavaSE"; status = "available"; version = "99.0.0"; fullversion = "99.0.0+1"; ga = "2026-01-01" }
                        [PSCustomObject]@{ family = "Other"; status = "delivered"; version = "100.0.0"; fullversion = "100.0.0+1"; ga = "2026-01-01" }
                    )
                }
            }
            $script:OracleResource = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Update = [PSCustomObject]@{
                        Uri        = "https://updates.example.test/releases"
                        Headers    = @{ Accept = "application/json" }
                        UserAgent  = "Evergreen-test"
                        Family     = "JavaSE"
                        DateFormat = "yyyy-MM-dd"
                    }
                    Download = [PSCustomObject]@{
                        Uri = [ordered]@{
                            x64   = "https://example.test/jdk-x64.tar.gz"
                            arm64 = "https://example.test/jdk-arm64.tar.gz"
                        }
                    }
                }
            }
            Mock Invoke-EvergreenRestMethod { $script:OracleFeed }
            Mock Invoke-EvergreenWebRequest {
                if ($Uri -like "*x64*") { ("a" * 64) } else { "not-a-checksum" }
            }
            Mock Get-Architecture { "x64" }
            Mock Get-FileType { "tar.gz" }
        }

        It "Selects the latest delivered matching-family version by numeric components" {
            $Result = @(Get-OracleJava -res $script:OracleResource -WarningAction SilentlyContinue)

            $Result.Count | Should -Be 2
            $Result[0].Version | Should -Be "10.2.0"
            $Result[0].FullVersion | Should -Be "10.2.0+2"
            $Result[0].Sha256 | Should -Be ("a" * 64)
            $Result[1].Version | Should -Be "10.2.0"
            $Result[1].Sha256 | Should -BeNull
            $Result[1].URI | Should -Be "https://example.test/jdk-arm64.tar.gz"
            Should -Invoke Invoke-EvergreenWebRequest -Times 2 -Exactly
        }

        It "Rejects a response without a releases collection" {
            $script:OracleFeed = [PSCustomObject]@{ data = [PSCustomObject]@{} }

            { Get-OracleJava -res $script:OracleResource } | Should -Throw "*did not contain a releases collection*"
        }

        It "Rejects feeds without a delivered release for the requested family" {
            $script:OracleFeed.data.releases = @(
                [PSCustomObject]@{ family = "Other"; status = "delivered"; version = "1.0"; fullversion = "1.0+1"; ga = "2025-01-01" }
            )

            { Get-OracleJava -res $script:OracleResource } | Should -Throw "*No delivered release found*"
        }

        It "Rejects invalid versions and missing release metadata" -TestCases @(
            @{ Release = [PSCustomObject]@{ family = "JavaSE"; status = "delivered"; version = "v10"; fullversion = "10+1"; ga = "2025-01-01" }; ExpectedMessage = "Invalid release version" }
            @{ Release = [PSCustomObject]@{ family = "JavaSE"; status = "delivered"; version = "10"; fullversion = ""; ga = "2025-01-01" }; ExpectedMessage = "missing its fullversion or GA date" }
        ) {
            param ($Release, $ExpectedMessage)
            $script:OracleFeed.data.releases = @($Release)

            { Get-OracleJava -res $script:OracleResource } | Should -Throw "*$ExpectedMessage*"
        }
    }
}
