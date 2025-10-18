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
}
