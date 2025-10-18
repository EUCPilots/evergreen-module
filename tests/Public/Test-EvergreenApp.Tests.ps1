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

Describe -Tag "Test" -Name "Test-EvergreenApp" {
    BeforeAll {
        $App = Get-EvergreenApp -Name "MicrosoftOneDrive"
        $Result = Test-EvergreenApp -InputObject $App
    }

    It "Should not throw with valid input" {
        $params = @{
            InputObject = $App
            UserAgent   = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
            Force       = $true
            NoProgress  = $true
        }
        { Test-EvergreenApp @params } | Should -Not -Throw
    }

    It "Should return an object with valid Result property" {
        $Result[0].Result | Should -BeOfType [System.Boolean]
    }

    It "Should return an object with valid URI property" {
        $Result[0].URI | Should -BeOfType [System.String]
    }
}
