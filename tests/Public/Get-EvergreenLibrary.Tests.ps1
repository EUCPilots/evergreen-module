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

    Context "Validate Get-EvergreenLibrary with valid library" -Skip {
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
