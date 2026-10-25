<#
    .SYNOPSIS
        Pester tests for Get-BellSoftLibericaJDK.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-BellSoftLibericaJDK" {
        BeforeEach {
            $res = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Download = [PSCustomObject]@{
                        Uri          = "https://api.example.com/releases?os=#Platform&version=#Version&arch=#Architecture&bitness=#Bitness"
                        ContentType  = "application/json"
                        Platforms    = @("linux")
                        Versions     = @("21")
                        Architectures = @("x64")
                        Bitness      = @("64")
                    }
                }
            }
            $script:TestLibericaRequestUris = @()
            $script:TestLibericaReleases = @(
                [PSCustomObject]@{
                    version      = "21.0.1"
                    LTS          = $true
                    bundleType   = "jdk"
                    packageType  = "tar.gz"
                    downloadUrl  = "https://example.com/liberica-jdk.tar.gz"
                    sha1         = "abc123"
                    size         = 1234
                }
            )
            Mock Invoke-EvergreenRestMethod {
                param ($Uri)
                $script:TestLibericaRequestUris += $Uri
                $script:TestLibericaReleases
            }
            Mock Get-Architecture { "x64" }
        }

        It "Returns formatted release metadata" {
            $Results = @(Get-BellSoftLibericaJDK -res $res)

            $Results.Count | Should -Be 1
            $Results[0].Version | Should -Be "21.0.1"
            $Results[0].Architecture | Should -Be "x64"
            $Results[0].URI | Should -Be "https://example.com/liberica-jdk.tar.gz"
        }

        It "Makes one request for each configured value combination" {
            $res.Get.Download.Platforms = @("linux", "windows")
            $res.Get.Download.Versions = @("21", "22")

            $null = @(Get-BellSoftLibericaJDK -res $res)

            $script:TestLibericaRequestUris.Count | Should -Be 4
            $script:TestLibericaRequestUris | Should -Contain "https://api.example.com/releases?os=windows&version=21&arch=x64&bitness=64"
        }

        It "Escapes substituted URL values literally" {
            $res.Get.Download.Platforms = @("linux&other=value")

            $null = @(Get-BellSoftLibericaJDK -res $res)

            $script:TestLibericaRequestUris[0] | Should -Be "https://api.example.com/releases?os=linux%26other%3Dvalue&version=21&arch=x64&bitness=64"
        }

        It "Rejects incomplete download configuration" {
            $res.Get.Download.Bitness = @()

            { Get-BellSoftLibericaJDK -res $res } | Should -Throw "*Get.Download.Bitness*"
        }

        It "Rejects a URI template missing a required placeholder" {
            $res.Get.Download.Uri = "https://api.example.com/releases?os=#Platform"

            { Get-BellSoftLibericaJDK -res $res } | Should -Throw "*missing the #Version placeholder*"
        }

        It "Rejects malformed release data" {
            $script:TestLibericaReleases = @([PSCustomObject]@{ version = "21.0.1" })

            { Get-BellSoftLibericaJDK -res $res } | Should -Throw "*missing downloadUrl*"
        }

        It "Rejects a non-HTTP download URL" {
            $script:TestLibericaReleases[0].downloadUrl = "file:///liberica.tar.gz"

            { Get-BellSoftLibericaJDK -res $res } | Should -Throw "*invalid downloadUrl*"
        }

        It "Stops when an API request fails" {
            Mock Invoke-EvergreenRestMethod { Write-Error -Message "API request failed." }

            { Get-BellSoftLibericaJDK -res $res } | Should -Throw "*API request failed*"
        }
    }
}
