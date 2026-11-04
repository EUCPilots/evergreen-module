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

Describe -Tag "Start" -Name "Start-EvergreenLibraryUpdate" {
    Context "Validate Start-EvergreenLibraryUpdate parameter validation" {
        It "Should throw if ProxyCredential is provided without Proxy" {
            $Creds = [System.Management.Automation.PSCredential]::new(
                "proxy-user",
                (ConvertTo-SecureString -String "proxy-pass" -AsPlainText -Force)
            )
            { Start-EvergreenLibraryUpdate -Path "/tmp" -ProxyCredential $Creds } | Should -Throw
        }

        It "Should throw when Path parameter is null or empty" {
            { Start-EvergreenLibraryUpdate -Path "" -AppName "MicrosoftEdge" } | Should -Throw
        }

        It "Should throw when AppName parameter is null or empty" {
            if ($env:Temp) {
                $TestPath = Join-Path -Path $env:Temp -ChildPath "LibraryUpdateTest"
            }
            elseif ($env:TMPDIR) {
                $TestPath = Join-Path -Path $env:TMPDIR -ChildPath "LibraryUpdateTest"
            }
            else {
                $TestPath = "/tmp/LibraryUpdateTest"
            }
            
            { Start-EvergreenLibraryUpdate -Path $TestPath -AppName "" } | Should -Throw
        }
    }

    Context "Validate Start-EvergreenLibraryUpdate basic functionality" -Tag "Integration" -Skip {
        BeforeAll {
            # This test requires a valid library setup, which is complex
            # Mark as skip for CI environments
            if ($env:Temp) {
                $script:TestLibPath = Join-Path -Path $env:Temp -ChildPath "LibraryUpdateFuncTest"
            }
            elseif ($env:TMPDIR) {
                $script:TestLibPath = Join-Path -Path $env:TMPDIR -ChildPath "LibraryUpdateFuncTest"
            }
            else {
                $script:TestLibPath = "/tmp/LibraryUpdateFuncTest"
            }
        }

        AfterAll {
            if (Test-Path -Path $script:TestLibPath) {
                Remove-Item -Path $script:TestLibPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Should not throw with valid parameters" -Skip {
            # Requires library setup
            New-EvergreenLibrary -Path $script:TestLibPath
            { Start-EvergreenLibraryUpdate -Path $script:TestLibPath -AppName "MicrosoftEdge" } | Should -Not -Throw
        }
    }

    Context "Validate application state is isolated per library entry" {
        BeforeAll {
            $script:TestLibPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "LibraryUpdateStateTest-$([System.Guid]::NewGuid().ToString())"
            $null = New-Item -Path (Join-Path -Path $script:TestLibPath -ChildPath "FirstApp") -ItemType "Directory" -Force
            $null = New-Item -Path (Join-Path -Path $script:TestLibPath -ChildPath "SecondApp") -ItemType "Directory" -Force
            foreach ($Version in @("2.0.0", "3.0.0")) {
                $VersionPath = Join-Path -Path $script:TestLibPath -ChildPath "FirstApp/$Version"
                $null = New-Item -Path $VersionPath -ItemType "Directory" -Force
                $null = New-Item -Path (Join-Path -Path $VersionPath -ChildPath "saved.exe") -ItemType "File" -Force
            }
            [PSCustomObject]@{
                Name = "TestLibrary"
                Applications = @(
                    [PSCustomObject]@{ Name = "FirstApp"; EvergreenApp = "FirstApp"; Filter = "" }
                    [PSCustomObject]@{ Name = "SecondApp"; EvergreenApp = "SecondApp"; Filter = "" }
                )
            } | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path -Path $script:TestLibPath -ChildPath "EvergreenLibrary.json") -Encoding "Utf8"

            Mock Get-EvergreenApp -ModuleName Evergreen -MockWith {
                if ($Name -eq "FirstApp") {
                    @(
                        [PSCustomObject]@{ Version = "3.0.0"; URI = "https://example.test/saved.exe" }
                        [PSCustomObject]@{ Version = "2.0.0"; URI = "https://example.test/saved.exe" }
                        [PSCustomObject]@{ Version = "1.0.0"; URI = "https://example.test/not-saved.exe" }
                    )
                }
            }
            Mock Save-EvergreenApp -ModuleName Evergreen -MockWith {
                Get-ChildItem -LiteralPath $Path -Filter "saved.exe" -File -Recurse
            }
        }

        AfterAll {
            Remove-Item -Path $script:TestLibPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }

        It "Should export only versions with matching saved installers and not reuse prior application data" {
            Start-EvergreenLibraryUpdate -Path $script:TestLibPath -Confirm:$false -WarningAction "SilentlyContinue"

            $firstManifest = Get-Content -Path (Join-Path -Path $script:TestLibPath -ChildPath "FirstApp/FirstApp.json") -Raw | ConvertFrom-Json
            $firstManifest.Count | Should -Be 2
            $firstManifest[0].Path | Should -Be (Join-Path -Path $script:TestLibPath -ChildPath "FirstApp/2.0.0/saved.exe")
            $firstManifest[1].Path | Should -Be (Join-Path -Path $script:TestLibPath -ChildPath "FirstApp/3.0.0/saved.exe")
            Test-Path -LiteralPath (Join-Path -Path $script:TestLibPath -ChildPath "SecondApp/SecondApp.json") | Should -Be $false
        }
    }
}
