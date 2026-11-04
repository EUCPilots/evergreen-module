<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Get" -Name "Get-EvergreenLibrary" {
    Context "Validate remote inventory and read failures" {
        BeforeAll {
            Mock Invoke-EvergreenRestMethod -ModuleName Evergreen {
                if ($Uri -like "*/EvergreenLibrary.json") {
                    [PSCustomObject]@{
                        Name = "RemoteLibrary"
                        Applications = @(
                            [PSCustomObject]@{ Name = "FirstApp" }
                            [PSCustomObject]@{ Name = "SecondApp" }
                        )
                    }
                }
                elseif ($Uri -like "*/FirstApp/FirstApp.json") {
                    [PSCustomObject]@{ Version = "2.0.0" }
                }
                else {
                    throw "Fixture remote manifest failure"
                }
            }
        }

        It "Builds remote inventory without reusing versions when the next request fails" {
            $Result = Get-EvergreenLibrary -Uri "https://storage.test/library/EvergreenLibrary.json" -WarningVariable Warnings -WarningAction SilentlyContinue

            $Result.Library.Name | Should -Be "RemoteLibrary"
            $Result.Inventory.Count | Should -Be 2
            $Result.Inventory[0].ApplicationName | Should -Be "FirstApp"
            $Result.Inventory[0].Versions.Version | Should -Be "2.0.0"
            $Result.Inventory[1].ApplicationName | Should -Be "SecondApp"
            $Result.Inventory[1].Versions | Should -BeNullOrEmpty
            $Warnings | Should -Match "Fixture remote manifest failure"
            Should -Invoke Invoke-EvergreenRestMethod -ModuleName Evergreen -Times 3 -Exactly
        }

        It "Rejects a URI outside the supported library format" {
            { Get-EvergreenLibrary -Uri "https://storage.test/other.json" } | Should -Throw "*must be in the format*"
            Should -Invoke Invoke-EvergreenRestMethod -ModuleName Evergreen -Times 0 -Exactly
        }
    }

    Context "Validate local library failures" {
        BeforeEach {
            $LocalPath = Join-Path $TestDrive "LocalLibrary"
            $null = New-Item -Path $LocalPath -ItemType Directory -Force
        }

        It "Rejects a missing directory" {
            { Get-EvergreenLibrary -Path (Join-Path $TestDrive "Missing") } | Should -Throw "*does not exist or is not a directory*"
        }

        It "Rejects a directory without a library manifest" {
            { Get-EvergreenLibrary -Path $LocalPath } | Should -Throw "*Cannot find EvergreenLibrary.json*"
        }

        It "Propagates invalid library JSON" {
            "{invalid" | Set-Content (Join-Path $LocalPath "EvergreenLibrary.json")
            { Get-EvergreenLibrary -Path $LocalPath } | Should -Throw
        }

        It "Warns for missing application directories and manifests without inventing inventory" {
            '{"Applications":[{"Name":"MissingDirectory"},{"Name":"MissingManifest"}]}' |
                Set-Content (Join-Path $LocalPath "EvergreenLibrary.json")
            $null = New-Item -Path (Join-Path $LocalPath "MissingManifest") -ItemType Directory

            $Result = Get-EvergreenLibrary -Path $LocalPath -WarningVariable Warnings -WarningAction SilentlyContinue

            $Result.Inventory.Count | Should -Be 0
            $Warnings.Count | Should -Be 2
            $Warnings[0] | Should -Match "MissingDirectory"
            $Warnings[1] | Should -Match "MissingManifest.json"
        }
    }

    Context "Validate Get-EvergreenLibrary basic functionality" {
        It "Should throw" {
            { Get-EvergreenLibrary } | Should -Throw
        }
    }

    Context "Validate version data is reset after a manifest read failure" {
        BeforeAll {
            $script:TestLibraryPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "GetEvergreenLibraryTest-$([System.Guid]::NewGuid().ToString())"
            $null = New-Item -Path $script:TestLibraryPath -ItemType "Directory" -Force
            $null = New-Item -Path (Join-Path -Path $script:TestLibraryPath -ChildPath "FirstApp") -ItemType "Directory" -Force
            $null = New-Item -Path (Join-Path -Path $script:TestLibraryPath -ChildPath "SecondApp") -ItemType "Directory" -Force

            [PSCustomObject]@{
                Name = "TestLibrary"
                Applications = @(
                    [PSCustomObject]@{ Name = "FirstApp" }
                    [PSCustomObject]@{ Name = "SecondApp" }
                )
            } | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path -Path $script:TestLibraryPath -ChildPath "EvergreenLibrary.json") -Encoding "Utf8"
            '[{"Version":"1.0.0"}]' | Out-File -FilePath (Join-Path -Path $script:TestLibraryPath -ChildPath "FirstApp/FirstApp.json") -Encoding "Utf8"
            '{invalid json' | Out-File -FilePath (Join-Path -Path $script:TestLibraryPath -ChildPath "SecondApp/SecondApp.json") -Encoding "Utf8"
        }

        AfterAll {
            Remove-Item -Path $script:TestLibraryPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }

        It "Should not attach the previous application's versions after a read failure" {
            $Library = Get-EvergreenLibrary -Path $script:TestLibraryPath -WarningAction "SilentlyContinue"

            $Library.Inventory[0].Versions.Version | Should -Be "1.0.0"
            $Library.Inventory[1].Versions | Should -BeNullOrEmpty
        }
    }

    Context "Validate Get-EvergreenLibrary with valid library" -Tag "Integration" -Skip {
        BeforeAll {
            # This test requires Update-Evergreen to have been run first
            # Mark as skip for CI environments where the library may not exist
            try {
                $script:Library = Get-EvergreenLibrary -ErrorAction "Stop"
            }
            catch {
                $script:Library = $null
            }
        }

        It "Should return library data if available" -Skip:($null -eq $script:Library) {
            $script:Library | Should -Not -BeNullOrEmpty
        }

        It "Should return object with Inventory property" -Skip:($null -eq $script:Library) {
            $script:Library.PSObject.Properties.Name | Should -Contain "Inventory"
        }

        It "Inventory should contain application data" -Skip:($null -eq $script:Library) {
            if ($script:Library.Inventory) {
                ($script:Library.Inventory | Measure-Object).Count | Should -BeGreaterThan 0
            }
        }
    }
}
