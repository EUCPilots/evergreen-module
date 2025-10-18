<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Name "Get-Platform" {
    InModuleScope -ModuleName "Evergreen" {
        Context "Ensure platform is returned" {
            It "Returns macOS" {
                Get-Platform -String "osx" | Should -Be "macOS"
            }

            It "Returns Linux" {
                Get-Platform -String "linux" | Should -Be "Linux"
            }

            It "Returns NuGet" {
                Get-Platform -String "file.nupkg" | Should -Be "NuGet"
            }

            It "Returns Debian" {
                Get-Platform -String "debian" | Should -Be "Debian"
            }

            It "Returns Debian" {
                Get-Platform -String "debian" | Should -Be "Debian"
            }

            It "Returns Ubuntu" {
                Get-Platform -String "ubuntu" | Should -Be "Ubuntu"
            }

            It "Returns CentOS" {
                Get-Platform -String "centos" | Should -Be "CentOS"
            }

            It "Returns Windows" {
                Get-Platform -String "file.exe" | Should -Be "Windows"
            }
        }

        Context "Ensure the default platform is returned" {
            It "Given a string that won't match, returns Windows" {
                Get-Platform -String "Neque porro quisquam est qui dolorem" | Should -Be "Windows"
            }
        }
    }
}
