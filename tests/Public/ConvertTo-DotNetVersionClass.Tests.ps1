<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Convert" -Name "ConvertTo-DotNetVersionClass" {
    BeforeAll {
        $App = Get-EvergreenApp -Name "MicrosoftOneDrive"
    }

    It "Should return a valid .NET version class" {
        ($App[0] | ConvertTo-DotNetVersionClass) | Should -BeOfType [System.Version]
    }

    It "Should return a string for a version number that fails to convert" {
        ConvertTo-DotNetVersionClass -Version "v22-build1" | Should -BeOfType [System.String]
    }

    It "Should return the expected string when converting a version string" {
        ConvertTo-DotNetVersionClass -Version "v22-build1" | Should -BeExactly "1185050.991806090049.0.0"
    }
}
