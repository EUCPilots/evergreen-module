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

Describe -Name "Get-InstallerType" {
    Context "It returns expected output" {
        It "Returns Default given a default URL" {
            InModuleScope -ModuleName "Evergreen" {
                $Url = "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.34662/Teams_windows_x64.msi"
                Get-InstallerType -String $Url | Should -Be "Default"
            }
        }

        It "Returns User given an User URL" {
            InModuleScope -ModuleName "Evergreen" {
                $Url = "https://github.com/microsoft/PowerToys/releases/download/v0.69.1/PowerToysUserSetup-0.69.1-arm64.exe"
                Get-InstallerType -String $Url | Should -Be "User"
            }
        }

        It "Returns Portable given an portable URL" {
            InModuleScope -ModuleName "Evergreen" {
                $Url = "https://github.com/microsoft/PowerToys/releases/download/v0.69.1/PowerToysPortableSetup-0.69.1-arm64.exe"
                Get-InstallerType -String $Url | Should -Be "Portable"
            }
        }

        It "Returns Debug given an debug URL" {
            InModuleScope -ModuleName "Evergreen" {
                $Url = "https://github.com/microsoft/PowerToys/releases/download/v0.69.1/PowerToysDEBUG-0.69.1-arm64.exe"
                Get-InstallerType -String $Url | Should -Be "Debug"
            }
        }

        It "Returns Airgap given an airgap URL" {
            InModuleScope -ModuleName "Evergreen" {
                $Url = "https://github.com/podman-desktop/podman-desktop/releases/download/v1.14.2/podman-desktop-airgap-1.14.2-x64.exe"
                Get-InstallerType -String $Url | Should -Be "Airgap"
            }
        }

    }
}
