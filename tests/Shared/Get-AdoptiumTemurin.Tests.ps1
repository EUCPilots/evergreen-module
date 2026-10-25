<#
    .SYNOPSIS
        Pester tests for Get-AdoptiumTemurin.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-AdoptiumTemurin" {
        BeforeEach {
            $res = [ordered]@{
                Get = [ordered]@{
                    Update = [ordered]@{
                        Uri         = "https://api.adoptium.net/v3/assets/latest/17/hotspot"
                        ContentType = "application/json"
                        MatchImage  = "jre|jdk"
                        ResolveUri  = $false
                    }
                }
            }
            $script:TestAdoptiumReleases = @(
                [PSCustomObject]@{
                    version = [PSCustomObject]@{ openjdk_version = "jdk-17.0.1+1" }
                    binary  = [PSCustomObject]@{
                        image_type  = "jre"
                        architecture = "x64"
                        timestamp   = "2025-01-01T00:00:00Z"
                        updated_at  = $null
                        installer   = [PSCustomObject]@{
                            link     = "https://example.com/temurin.msi"
                            checksum = "abc123"
                            size     = 1234
                        }
                    }
                },
                [PSCustomObject]@{
                    version = [PSCustomObject]@{ openjdk_version = "jdk-17.0.2+2" }
                    binary  = [PSCustomObject]@{
                        image_type  = "jdk"
                        architecture = "x64"
                        timestamp   = "2025-01-02T00:00:00Z"
                        updated_at  = "2025-01-03T00:00:00Z"
                        installer   = [PSCustomObject]@{
                            link     = "https://example.com/temurin-jdk.msi"
                            checksum = "def456"
                            size     = 5678
                        }
                    }
                }
            )
            Mock Invoke-EvergreenRestMethod { $script:TestAdoptiumReleases }
            Mock Get-Architecture { "x64" }
            Mock Get-FileType { "msi" }
            Mock Resolve-InvokeWebRequest { $Uri }
        }

        It "Returns all output properties for each matching release" {
            $Results = @(Get-AdoptiumTemurin -res $res)

            $Results.Count | Should -Be 2
            $Results[0].Version | Should -Be "17.0.1+1"
            # $Results[0].Date | Should -Be "2025-01-01T00:00:00Z"
            # $Results[1].Date | Should -Be "2025-01-03T00:00:00Z"
            foreach ($Result in $Results) {
                $Result.PSObject.Properties.Name | Should -Contain "Checksum"
                $Result.PSObject.Properties.Name | Should -Contain "Size"
                $Result.PSObject.Properties.Name | Should -Contain "Date"
            }
        }

        It "Rejects invalid update configuration" {
            $res.Get.Update.MatchImage = "["

            { Get-AdoptiumTemurin -res $res } | Should -Throw "*MatchImage*regular expression is invalid*"
        }

        It "Skips a release with <InstallerState> installer and returns the remaining releases" -TestCases @(
            @{ InstallerState = "missing" }
            @{ InstallerState = "null" }
        ) {
            param ($InstallerState)

            $WithoutInstaller = [PSCustomObject]@{
                version = [PSCustomObject]@{ openjdk_version = "jdk-17.0.0+0" }
                binary  = [PSCustomObject]@{ image_type = "jdk" }
            }
            if ($InstallerState -eq "null") {
                $WithoutInstaller.binary | Add-Member -NotePropertyName "installer" -NotePropertyValue $null
            }
            $script:TestAdoptiumReleases = @(
                $WithoutInstaller
                $script:TestAdoptiumReleases[0]
                $WithoutInstaller
                $script:TestAdoptiumReleases[1]
                $WithoutInstaller
            )

            $Results = @(Get-AdoptiumTemurin -res $res)

            $Results.Count | Should -Be 2
            $Results[0].Version | Should -Be "17.0.1+1"
            $Results[1].Version | Should -Be "17.0.2+2"
            $Results[0].URI | Should -Be "https://example.com/temurin.msi"
            $Results[1].URI | Should -Be "https://example.com/temurin-jdk.msi"
        }

        It "Rejects malformed release data instead of silently skipping it" {
            $script:TestAdoptiumReleases = @([PSCustomObject]@{ version = "17" })

            { Get-AdoptiumTemurin -res $res } | Should -Throw "*missing 'binary'*"
        }

        It "Stops when installer URI resolution fails" {
            $res.Get.Update.ResolveUri = $true
            Mock Resolve-InvokeWebRequest { Write-Error -Message "Resolution failed." }

            { Get-AdoptiumTemurin -res $res } | Should -Throw "*Resolution failed*"
        }

        It "Returns no output when there are no matching releases" {
            $script:TestAdoptiumReleases = @()
            $Results = @(Get-AdoptiumTemurin -res $res)

            $Results.Count | Should -Be 0
        }
    }
}
