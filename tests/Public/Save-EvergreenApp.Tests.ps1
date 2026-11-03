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

                { Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -RetryCount 0 } | Should -Throw "*download failed*"
                @(Get-ChildItem -LiteralPath $testPath -Force) | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Retries transient failures with bounded exponential backoff" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            $script:downloadAttempts = 0
            try {
                Mock Invoke-WebRequest {
                    param ($Uri, $OutFile)
                    $script:downloadAttempts++
                    [System.IO.File]::WriteAllText($OutFile, "partial")
                    if ($script:downloadAttempts -lt 3) {
                        throw [System.Net.WebException]::new("connection reset")
                    }
                    [System.IO.File]::WriteAllText($OutFile, "installer")
                }
                Mock Start-Sleep {}

                $result = Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -RetryCount 2 -RetryDelaySeconds 1

                $result.Name | Should -Be "installer.msi"
                Get-Content -LiteralPath $result.FullName -Raw | Should -Be "installer"
                Should -Invoke Invoke-WebRequest -Times 3 -Exactly
                Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 1 }
                Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
                if ($PSVersionTable.PSVersion -ge [System.Version]"6.1") {
                    Should -Invoke Invoke-WebRequest -Times 3 -Exactly -ParameterFilter { $Resume }
                }
                else {
                    Should -Invoke Invoke-WebRequest -Times 0 -Exactly -ParameterFilter { $Resume }
                }
                if ($PSVersionTable.PSVersion -ge [System.Version]"6.1") {
                    Should -Invoke Invoke-WebRequest -Times 3 -Exactly -ParameterFilter { $Resume }
                }
                else {
                    Should -Invoke Invoke-WebRequest -Times 0 -Exactly -ParameterFilter { $Resume }
                }
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
                Remove-Variable -Name downloadAttempts -Scope Script -ErrorAction "SilentlyContinue"
            }
        }

        It "Honors Retry-After on retryable HTTP responses" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            $script:downloadAttempts = 0
            $script:retryException = [System.InvalidOperationException]::new("too many requests")
            $script:retryException | Add-Member -MemberType NoteProperty -Name Response -Value ([PSCustomObject]@{
                StatusCode = 429
                Headers    = @{ "Retry-After" = "5" }
            })
            try {
                Mock Invoke-WebRequest {
                    param ($Uri, $OutFile)
                    $script:downloadAttempts++
                    if ($script:downloadAttempts -eq 1) {
                        throw $script:retryException
                    }
                    [System.IO.File]::WriteAllText($OutFile, "installer")
                }
                Mock Start-Sleep {}

                Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -RetryCount 1 -RetryDelaySeconds 1 | Out-Null

                Should -Invoke Invoke-WebRequest -Times 2 -Exactly
                Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 5 }
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
                Remove-Variable -Name retryException, downloadAttempts -Scope Script -ErrorAction "SilentlyContinue"
            }
        }

        It "Does not retry permanent HTTP errors" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            $script:downloadAttempts = 0
            $script:permanentException = [System.InvalidOperationException]::new("not found")
            $script:permanentException | Add-Member -MemberType NoteProperty -Name Response -Value ([PSCustomObject]@{
                StatusCode = 404
                Headers    = @{}
            })
            try {
                Mock Invoke-WebRequest {
                    $script:downloadAttempts++
                    throw $script:permanentException
                }
                Mock Start-Sleep {}

                { Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -RetryCount 3 } | Should -Throw "*not found*"

                Should -Invoke Invoke-WebRequest -Times 1 -Exactly
                Should -Invoke Start-Sleep -Times 0 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $testPath -Recurse -Force -ErrorAction "SilentlyContinue"
                Remove-Variable -Name permanentException, downloadAttempts -Scope Script -ErrorAction "SilentlyContinue"
            }
        }

        It "Passes timeout settings supported by the current PowerShell version" {
            $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-Save-$([guid]::NewGuid().ToString('N'))"
            try {
                Mock Invoke-WebRequest {
                    param ($Uri, $OutFile)
                    [System.IO.File]::WriteAllText($OutFile, "installer")
                }

                if ($PSVersionTable.PSVersion -ge [System.Version]"7.4") {
                    Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -ConnectionTimeoutSeconds 17 -OperationTimeoutSeconds 121 | Out-Null
                    Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                        $ConnectionTimeoutSeconds -eq 17 -and $OperationTimeoutSeconds -eq 121
                    }
                }
                else {
                    Save-EvergreenApp -InputObject $testApp -CustomPath $testPath -ConnectionTimeoutSeconds 17 | Out-Null
                    Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter { $TimeoutSec -eq 17 }
                }
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
