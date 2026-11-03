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

    It "Should produce a stable value for the same text segments" {
        (ConvertTo-DotNetVersionClass -Version "1.2-beta") |
            Should -Be (ConvertTo-DotNetVersionClass -Version "1.2-beta")
    }

    It "Should document that text-derived components are not semantic-version ordering" {
        $Help = Get-Help ConvertTo-DotNetVersionClass -Full
        $Help.Description.Text -join " " | Should -Match "does not preserve semantic version ordering"
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

    It "Should reject a leading separator" {
        { ConvertTo-DotNetVersionClass -Version "-1.2" } |
            Should -Throw -ExceptionType ([System.ArgumentException])
    }

    It "Should reject whitespace-only input" {
        { ConvertTo-DotNetVersionClass -Version "   " } |
            Should -Throw -ExceptionType ([System.ArgumentException])
    }

    It "Should reject each supported separator at the start or end" {
        foreach ($Separator in ".", "_", "+", "-") {
            { ConvertTo-DotNetVersionClass -Version "${Separator}1.2" } |
                Should -Throw -ExceptionType ([System.ArgumentException])
            { ConvertTo-DotNetVersionClass -Version "1.2${Separator}" } |
                Should -Throw -ExceptionType ([System.ArgumentException])
        }
    }

    It "Should reject adjacent mixed separators" {
        { ConvertTo-DotNetVersionClass -Version "1._2" } |
            Should -Throw -ExceptionType ([System.ArgumentException])
    }

    It "Should reject Unicode decimal digits instead of hashing them as text" {
        $UnicodeVersion = "{0}.{1}" -f [char]0x0661, [char]0x0662
        { ConvertTo-DotNetVersionClass -Version $UnicodeVersion } |
            Should -Throw -ExceptionType ([System.ArgumentException])
    }

    It "Should throw when a numeric component exceeds Int32.MaxValue" {
        { ConvertTo-DotNetVersionClass -Version "1.2.3.2147483648" } |
            Should -Throw -ExceptionType ([System.OverflowException])
    }
}
