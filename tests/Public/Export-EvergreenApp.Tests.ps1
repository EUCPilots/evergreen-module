<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Export" -Name "Export-EvergreenApp" {
    BeforeAll {
        $App = Get-EvergreenApp -Name "MicrosoftOneDrive"

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
        $File = Join-Path -Path $Path -ChildPath "MicrosoftOneDrive.json"

        $InvalidFile = Join-Path -Path $Path -ChildPath "JsonTest.json"
        "xxbbccss" | Out-File -FilePath $InvalidFile
    }

    Context "Validate Export-EvergreenApp functionality" {
        It "Should not throw with correct input" {
            { Export-EvergreenApp -InputObject $App -Path $File } | Should -Not -Throw
        }

        It "Should throw if the input file is invalid" {
            { Export-EvergreenApp -InputObject $App -Path $InvalidFile } | Should -Throw
        }

        It "Should write the output file OK" {
            (Get-Content -Path $File | ConvertFrom-Json).Count | Should -Match $App.Count
        }
    }

    Context "Validate Export-EvergreenApp ShouldProcess behavior" {
        It "Should not modify the target file or return success when WhatIf is used" {
            $WhatIfPath = Join-Path -Path $TestDrive -ChildPath "WhatIf.json"
            Set-Content -LiteralPath $WhatIfPath -Value '[{"Version":"1.0","URI":"https://example.com/old"}]'
            $OriginalContent = Get-Content -LiteralPath $WhatIfPath -Raw
            $Input = [PSCustomObject] @{
                Version = "2.0"
                URI     = "https://example.com/new"
            }

            $Result = @($Input | Export-EvergreenApp -Path $WhatIfPath -WhatIf)

            (Get-Content -LiteralPath $WhatIfPath -Raw) | Should -Be $OriginalContent
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Validate Export-EvergreenApp file handling" {
        It "Should throw and return no success object when the output path is invalid" {
            $InvalidPath = Join-Path -Path $TestDrive -ChildPath "missing/output.json"
            $Input = [PSCustomObject] @{
                Version = "1.0"
                URI     = "https://example.com/download"
            }

            $Result = $null
            { $Result = Export-EvergreenApp -InputObject @($Input) -Path $InvalidPath -ErrorAction "Stop" } |
                Should -Throw
            $Result | Should -BeNullOrEmpty
        }

        It "Should read and merge multiline JSON in the existing file" {
            $ExistingPath = Join-Path -Path $TestDrive -ChildPath "Existing.json"
            @'
[
  {
    "Version": "1.0",
    "URI": "https://example.com/old"
  }
]
'@ | Set-Content -LiteralPath $ExistingPath
            $Input = [PSCustomObject] @{
                Version = "2.0"
                URI     = "https://example.com/new"
            }

            Export-EvergreenApp -InputObject @($Input) -Path $ExistingPath | Out-Null
            $Versions = @(Get-Content -LiteralPath $ExistingPath -Raw | ConvertFrom-Json)

            $Versions.Count | Should -Be 2
            $Versions.Version | Should -Be @("1.0", "2.0")
        }
    }

    Context "Validate Export-EvergreenApp pipeline batching and sorting" {
        It "Should batch pipeline input into one write and sort numeric versions before nonstandard versions" {
            $BatchPath = Join-Path -Path $TestDrive -ChildPath "Batch.json"
            $Input = @(
                [PSCustomObject] @{ Version = "preview"; URI = "https://example.com/preview" }
                [PSCustomObject] @{ Version = "2.0"; URI = "https://example.com/v2" }
                [PSCustomObject] @{ Version = "1.0"; URI = "https://example.com/v1" }
            )

            $Result = @($Input | Export-EvergreenApp -Path $BatchPath)
            $Versions = @(Get-Content -LiteralPath $BatchPath -Raw | ConvertFrom-Json)

            $Result.Count | Should -Be 1
            $Versions.Version | Should -Be @("1.0", "2.0", "preview")
        }

        It "Should preserve nested values through the configured JSON depth" {
            $NestedPath = Join-Path -Path $TestDrive -ChildPath "Nested.json"
            $Nested = "leaf"
            for ($Depth = 0; $Depth -lt 25; $Depth++) {
                $Nested = [PSCustomObject] @{ Child = $Nested }
            }
            $Input = [PSCustomObject] @{
                Version = "1.0"
                URI     = "https://example.com/nested"
                Nested  = $Nested
            }

            Export-EvergreenApp -InputObject @($Input) -Path $NestedPath | Out-Null
            $Saved = Get-Content -LiteralPath $NestedPath -Raw | ConvertFrom-Json
            $Value = $Saved.Nested
            for ($Depth = 0; $Depth -lt 25; $Depth++) {
                $Value = $Value.Child
            }

            $Value | Should -Be "leaf"
        }
    }
}
