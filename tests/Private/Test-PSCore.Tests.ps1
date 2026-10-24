<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Name "Test-PSCore" {
    It "Reports whether the current edition and version satisfy the default threshold" {
        InModuleScope -ModuleName "Evergreen" {
            $expected = ($PSVersionTable.PSEdition -eq "Core") -and ($PSVersionTable.PSVersion -ge [System.Version]"6.0.0")
            Test-PSCore | Should -Be $expected
        }
    }

    It "Treats the current version as an inclusive threshold" {
        InModuleScope -ModuleName "Evergreen" {
            $expected = $PSVersionTable.PSEdition -eq "Core"
            Test-PSCore -Version $PSVersionTable.PSVersion | Should -Be $expected
        }
    }

    It "Returns False when the requested version is newer than the current version" {
        InModuleScope -ModuleName "Evergreen" {
            $version = [System.Version]::new($PSVersionTable.PSVersion.Major + 1, 0)
            Test-PSCore -Version $version | Should -Be $false
        }
    }

    It "Rejects an invalid version" {
        InModuleScope -ModuleName "Evergreen" {
            { Test-PSCore -Version "not-a-version" } | Should -Throw
        }
    }
}
