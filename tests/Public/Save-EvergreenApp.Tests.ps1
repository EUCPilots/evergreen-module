<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
    # Get details for Microsoft Edge
    $Installers = Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Channel -eq "Stable" }
}

BeforeAll {
}

Describe -Tag "Save" -Name "Save-EvergreenApp" -ForEach $Installers {
    BeforeAll {
        # Renaming the automatic $_ variable to $application to make it easier to work with
        $installer = $_

        # Create download path
        if ($env:Temp) {
            $Path = Join-Path -Path $env:Temp -ChildPath "Downloads"
        }
        elseif ($env:TMPDIR) {
            $Path = Join-Path -Path $env:TMPDIR -ChildPath "Downloads"
        }
        elseif ($env:RUNNER_TEMP) {
            $Path = Join-Path -Path $env:RUNNER_TEMP -ChildPath "Downloads"
        }
        New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
    }

    # Test that Save-EvergreenApp accepts the object and saves the file
    Context "Validate Save-EvergreenApp works with <installer.Architecture>." {
        It "Save-EvergreenApp should not throw with Path" {
            $params = @{
                InputObject = $installer
                Path        = $Path
                UserAgent   = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
                Force       = $true
                NoProgress  = $true
            }
            { Save-EvergreenApp @params } | Should -Not -Throw
        }

        # Test that the file downloaded into the path: "$Path/Stable/Enterprise/<version>/x64/MicrosoftEdgeEnterpriseX64.msi"
        It "Should save in the right path" {
            $File = [System.IO.Path]::Combine($Path, $installer.Channel, $installer.Release, $installer.Version, $installer.Architecture, $(Split-Path -Path $installer.URI -Leaf))
            Test-Path -Path $File -PathType "Leaf" | Should -Be $True
        }

        It "Save-EvergreenApp should not throw with CustomPath" {
            $params = @{
                InputObject = $installer
                CustomPath  = $Path
                UserAgent   = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
                Force       = $true
                NoProgress  = $true
            }
            { Save-EvergreenApp @params } | Should -Not -Throw
        }
    }
}

InModuleScope -ModuleName "Evergreen" {
    Describe -Tag "Save" -Name "Save-EvergreenApp download handling" {
        BeforeAll {
            $testApp = [PSCustomObject]@{
                URI          = "https://example.com/installer.msi"
                FileName     = "installer.msi"
                Version      = "1.0.0"
                Channel      = "Stable"
                Release      = "Enterprise"
                Architecture = "x64"
            }
        }

        It "Uses the supplied user agent and publishes the completed download" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            try {
                Mock Invoke-WebRequest {
                    param ($Uri, $OutFile)
                    [System.IO.File]::WriteAllText($OutFile, "installer")
                }

                $result = Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -UserAgent "test-agent"

                $result.Name | Should -Be "installer.msi"
                Get-Content -LiteralPath $result.FullName -Raw | Should -Be "installer"
                Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter { $UserAgent -eq "test-agent" }
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Does not create directories or download under WhatIf" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            try {
                Mock Invoke-WebRequest {}

                Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -WhatIf | Should -BeNullOrEmpty

                Test-Path -LiteralPath $testPath | Should -BeFalse
                Should -Invoke Invoke-WebRequest -Times 0 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Removes partial downloads and propagates request failures" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            try {
                New-Item -Path $testPath -ItemType Directory -Force | Out-Null
                Mock Invoke-WebRequest {
                    param ($Uri, $OutFile)
                    [System.IO.File]::WriteAllText($OutFile, "partial")
                    throw "download failed"
                }

                { Save-EvergreenApp -InputObject $testApp -CustomPath $testPath } | Should -Throw "*download failed*"
                @(Get-ChildItem -LiteralPath $testPath -Force) | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Rejects filenames that could escape the output directory" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            $unsafeApp = $testApp | Select-Object *
            $unsafeApp.FileName = "../outside.msi"
            try {
                Mock Invoke-WebRequest {}

                { Save-EvergreenApp -InputObject $unsafeApp -CustomPath $testPath } | Should -Throw "*invalid file name*"
                Should -Invoke Invoke-WebRequest -Times 0 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Accepts a Path destination bound from a pipeline property" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            $pipelineApp = [PSCustomObject]@{
                URI          = $testApp.URI
                FileName     = $testApp.FileName
                Version      = $testApp.Version
                Channel      = $testApp.Channel
                Release      = $testApp.Release
                Architecture = $testApp.Architecture
                Path         = $testPath
            }
            try {
                Mock Invoke-WebRequest {
                    param ($Uri, $OutFile)
                    [System.IO.File]::WriteAllText($OutFile, "installer")
                }

                $result = $pipelineApp | Save-EvergreenApp

                $expectedPath = [System.IO.Path]::Combine($testPath, "Stable", "Enterprise", "1.0.0", "x64", "installer.msi")
                $result.FullName | Should -Be $expectedPath
                Test-Path -LiteralPath $result.FullName -PathType Leaf | Should -BeTrue
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Accepts a CustomPath destination bound from a pipeline property" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            $pipelineApp = [PSCustomObject]@{
                URI          = $testApp.URI
                FileName     = $testApp.FileName
                Version      = $testApp.Version
                Channel      = $testApp.Channel
                Release      = $testApp.Release
                Architecture = $testApp.Architecture
                CustomPath   = $testPath
            }
            try {
                Mock Invoke-WebRequest {
                    param ($Uri, $OutFile)
                    [System.IO.File]::WriteAllText($OutFile, "installer")
                }

                $result = $pipelineApp | Save-EvergreenApp

                $expectedPath = Join-Path -Path $testPath -ChildPath "installer.msi"
                $result.FullName | Should -Be $expectedPath
                Test-Path -LiteralPath $result.FullName -PathType Leaf | Should -BeTrue
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }
    }
}

Describe -Tag "Save" -Name "Save-EvergreenApp proxy validation" {
    It "Should throw if ProxyCredential is provided without Proxy" {
        $Creds = [System.Management.Automation.PSCredential]::new(
            "proxy-user",
            (ConvertTo-SecureString -String "proxy-pass" -AsPlainText -Force)
        )

        $Dummy = [PSCustomObject]@{
            URI          = "https://example.com/app.msi"
            Version      = "1.0.0"
            Channel      = "Stable"
            Release      = "Enterprise"
            Architecture = "x64"
        }

        { Save-EvergreenApp -InputObject $Dummy -Path ([System.IO.Path]::GetTempPath()) -ProxyCredential $Creds -NoProgress } | Should -Throw
    }
}
