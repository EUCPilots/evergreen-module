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

    It "Should return a .NET version for text segments" {
        ConvertTo-DotNetVersionClass -Version "v22-build1" | Should -BeOfType [System.Version]
    }

    It "Should pad versions with fewer than four segments" {
        ConvertTo-DotNetVersionClass -Version "1.2" | Should -Be ([System.Version]"1.2.0.0")
    }

    It "Should saturate the combined excess segments at Int32.MaxValue" {
        ConvertTo-DotNetVersionClass -Version "1.2.3.2147483647.1" |
            Should -Be ([System.Version]"1.2.3.2147483647")
    }

    It "Should reject repeated separators instead of accepting empty segments" {
        { ConvertTo-DotNetVersionClass -Version "1..2" } |
            Should -Throw -ExceptionType ([System.ArgumentException])
    }

    It "Should reject a trailing separator" {
        { ConvertTo-DotNetVersionClass -Version "1.2." } |
            Should -Throw -ExceptionType ([System.ArgumentException])
    }

    It "Should throw when a numeric component exceeds Int32.MaxValue" {
        { ConvertTo-DotNetVersionClass -Version "1.2.3.2147483648" } |
            Should -Throw -ExceptionType ([System.OverflowException])
    }
}
