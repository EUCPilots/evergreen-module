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

Describe -Name "Get-Architecture" {
    Context "It returns expected output" {
        It "Returns x64 given an x64 URL" {
            InModuleScope -ModuleName "Evergreen" {
                $64bitUrl = "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.34662/Teams_windows_x64.msi"
                Get-Architecture -String $64bitUrl | Should -Be "x64"
            }
        }

        It "Returns x86 given an x86 URL" {
            InModuleScope -ModuleName "Evergreen" {
                $32bitUrl = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/2001320074/AcroRdrDCUpd2001320074.msp"
                Get-Architecture -String $32bitUrl | Should -Be "x86"
            }
        }

        It "Returns x86 given a string that won't match anything" {
            InModuleScope -ModuleName "Evergreen" {
                Get-Architecture -String "the quick brown fox" | Should -Be "x86"
            }
        }

        It "Returns arm32" {
            InModuleScope -ModuleName "Evergreen" {
                Get-Architecture -String "arm32" | Should -Be "ARM32"
            }
        }

        It "Returns win-arm64" {
            InModuleScope -ModuleName "Evergreen" {
                Get-Architecture -String "win-arm64" | Should -Be "ARM64"
            }
        }

        It "Does not match architecture markers embedded in words" {
            InModuleScope -ModuleName "Evergreen" {
                Get-Architecture -String "notx64package" | Should -Be "x86"
                Get-Architecture -String "farm64tool" | Should -Be "x86"
            }
        }

        It "Does not treat version numbers as architecture markers" {
            InModuleScope -ModuleName "Evergreen" {
                Get-Architecture -String "release-64.2" | Should -Be "x86"
                Get-Architecture -String "version.64.2" | Should -Be "x86"
            }
        }

        It "Matches numeric architecture suffixes before file extensions" {
            InModuleScope -ModuleName "Evergreen" {
                Get-Architecture -String "https://example.com/app-64.msi" | Should -Be "x64"
                Get-Architecture -String "https://example.com/app-32.exe" | Should -Be "x86"
            }
        }
    }
}
