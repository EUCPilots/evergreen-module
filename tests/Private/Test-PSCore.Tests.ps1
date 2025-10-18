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
    Context "Tests whether we are running on PowerShell Core" {
        It "Returns True if running Windows PowerShell" {
            InModuleScope -ModuleName "Evergreen" {
                $Version = "6.0.0"
                If (($PSVersionTable.PSVersion -ge [version]::Parse($Version)) -and ($PSVersionTable.PSEdition -eq "Core")) {
                    Test-PSCore | Should -Be $True
                }
            }
        }
    }
    Context "Tests whether we are running on Windows PowerShell" {
        It "Returns False if running Windows PowerShell" {
            InModuleScope -ModuleName "Evergreen" {
                $Version = "6.0.0"
                If (($PSVersionTable.PSVersion -lt [version]::Parse($Version)) -and ($PSVersionTable.PSEdition -eq "Desktop")) {
                    Test-PSCore | Should -Be $False
                }
            }
        }
    }
}
