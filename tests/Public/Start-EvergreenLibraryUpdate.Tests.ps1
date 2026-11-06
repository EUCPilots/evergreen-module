<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "This is OK for tests.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Start" -Name "Start-EvergreenLibraryUpdate" {
    Context "Validate filtered updates and library changes" {
        BeforeEach {
            $UpdatePath = Join-Path $TestDrive ([Guid]::NewGuid().ToString("N"))
            $null = New-Item -Path (Join-Path $UpdatePath "FixtureApp") -ItemType Directory -Force
            [PSCustomObject]@{
                Applications = @(
                    [PSCustomObject]@{
                        Name = "FixtureApp"
                        EvergreenApp = "FixtureApp"
                        Filter = '$_.Architecture -eq "x64"'
                    }
                )
            } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $UpdatePath "EvergreenLibrary.json")
            Mock Get-EvergreenApp -ModuleName Evergreen {
                [PSCustomObject]@{ Version = "2.0.0"; Architecture = "x64"; FileName = "custom.exe"; URI = "https://example.test/download" }
                [PSCustomObject]@{ Version = "2.0.0"; Architecture = "x86"; FileName = "other.exe"; URI = "https://example.test/other" }
            }
            Mock Save-EvergreenApp -ModuleName Evergreen {
                $Directory = Join-Path $Path "2.0.0/x64"
                $null = New-Item -Path $Directory -ItemType Directory -Force
                $FilePath = Join-Path $Directory "custom.exe"
                Set-Content -LiteralPath $FilePath -Value "fixture"
                Get-Item -LiteralPath $FilePath
            }
        }

        It "Filters versions, forwards proxy options and reports newly saved custom filenames" {
            $Credential = [PSCredential]::new("proxy-user", [System.Security.SecureString]::new())
            $Result = Start-EvergreenLibraryUpdate -Path $UpdatePath -Proxy "http://proxy.test:8080" -ProxyCredential $Credential -Confirm:$false

            $Result.Status | Should -Be "NEW"
            $Result.Installer | Should -Be (Join-Path $UpdatePath "FixtureApp/2.0.0/x64/custom.exe")
            $Manifest = Get-Content (Join-Path $UpdatePath "FixtureApp/FixtureApp.json") -Raw | ConvertFrom-Json
            @($Manifest).Count | Should -Be 1
            $Manifest.Architecture | Should -Be "x64"
            $Manifest.Path | Should -Be $Result.Installer
            Should -Invoke Get-EvergreenApp -ModuleName Evergreen -Times 1 -Exactly -ParameterFilter {
                $Name -eq "FixtureApp" -and $Proxy -eq "http://proxy.test:8080" -and $ProxyCredential.UserName -eq "proxy-user"
            }
            Should -Invoke Save-EvergreenApp -ModuleName Evergreen -Times 1 -Exactly -ParameterFilter {
                $InputObject.Architecture -eq "x64" -and $Proxy -eq "http://proxy.test:8080" -and $ProxyCredential.UserName -eq "proxy-user"
            }
        }

        It "Warns on an invalid filter without downloading or exporting versions" {
            '{"Applications":[{"Name":"FixtureApp","EvergreenApp":"FixtureApp","Filter":"{"}]}' |
                Set-Content (Join-Path $UpdatePath "EvergreenLibrary.json")

            $Result = Start-EvergreenLibraryUpdate -Path $UpdatePath -Confirm:$false -WarningVariable Warnings -WarningAction SilentlyContinue

            $Result | Should -BeNullOrEmpty
            ($Warnings -join "`n") | Should -Match "Failed applying filter"
            ($Warnings -join "`n") | Should -Match "No media found"
            Should -Invoke Get-EvergreenApp -ModuleName Evergreen -Times 0 -Exactly
            Test-Path (Join-Path $UpdatePath "FixtureApp/FixtureApp.json") | Should -BeFalse
        }

        It "Does not save installers or export versions under WhatIf" {
            Start-EvergreenLibraryUpdate -Path $UpdatePath -WhatIf -WarningAction SilentlyContinue

            Should -Invoke Save-EvergreenApp -ModuleName Evergreen -Times 0 -Exactly
            Test-Path (Join-Path $UpdatePath "FixtureApp/FixtureApp.json") | Should -BeFalse
        }

        It "Rejects a missing library directory" {
            { Start-EvergreenLibraryUpdate -Path (Join-Path $UpdatePath "Missing") -Confirm:$false } |
                Should -Throw "*does not exist or is not a directory*"
        }

        It "Rejects a missing library manifest" {
            Remove-Item (Join-Path $UpdatePath "EvergreenLibrary.json")
            { Start-EvergreenLibraryUpdate -Path $UpdatePath -Confirm:$false } | Should -Throw "*Cannot find EvergreenLibrary.json*"
        }
    }

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
