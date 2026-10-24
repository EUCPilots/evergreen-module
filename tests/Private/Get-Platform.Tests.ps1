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

            It "Returns Linux when the archive name explicitly includes Linux" {
                Get-Platform -String "tool-linux-x64.tar.gz" | Should -Be "Linux"
            }

            It "Does not infer Linux from a generic tar.gz archive" {
                Get-Platform -String "tool.tar.gz" | Should -Be "Windows"
            }

            It "Returns NuGet" {
                Get-Platform -String "file.nupkg" | Should -Be "NuGet"
            }

            It "Returns Debian for a Debian package extension" {
                Get-Platform -String "tool.deb" | Should -Be "Debian"
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

            It "Matches platform indicators without regard to case" {
                Get-Platform -String "TOOL-OSX-ARM64" | Should -Be "macOS"
            }

            It "Ignores platform-like query parameters" {
                Get-Platform -String "https://example.com/tool.exe?platform=linux" | Should -Be "Windows"
            }

            It "Does not match a platform name embedded in another word" {
                Get-Platform -String "superlinuxclient" | Should -Be "Windows"
            }

            It "Returns Windows for conflicting platform indicators" {
                Get-Platform -String "tool-windows-linux.zip" | Should -Be "Windows"
            }
        }

        Context "Ensure unknown platforms are explicit" {
            It "Given a string that won't match, returns Windows" {
                Get-Platform -String "Neque porro quisquam est qui dolorem" | Should -Be "Windows"
            }
        }
    }
}
