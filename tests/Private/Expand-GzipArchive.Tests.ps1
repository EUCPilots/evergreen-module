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

Describe -Name "Expand-GzipArchive" {
    Context "Test that Expand-GzipArchive works as expected" {
        It "Should throw when given a file path that does not exist" {
            InModuleScope -ModuleName "Evergreen" {
                { Expand-GzipArchive -Path $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "file.tar.gz")) } | Should -Throw
            }
        }

        It "Should throw when given a destination path that does not exist" {
            InModuleScope -ModuleName "Evergreen" {
                $params = @{
                    Path             = $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini.gz"))
                    DestinationPath  = $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "dummyfolder", "TestFile.ini"))
                }
                { Expand-GzipArchive @params } | Should -Throw
            }
        }

        It "Should not throw when expanding a .gz file" {
            InModuleScope -ModuleName "Evergreen" {
                $params = @{
                    Path            = $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini.gz"))
                    DestinationPath = $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini"))
                }
                { Expand-GzipArchive @params } | Should -Not -Throw
            }
        }

        It "Should return an object of type string" {
            InModuleScope -ModuleName "Evergreen" {
                $params = @{
                    Path            = $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini.gz"))
                    DestinationPath = $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini"))
                }
                $File = Expand-GzipArchive @params
                $File | Should -BeOfType [System.String]
            }
        }

        It "Should have expanded the file successfully" {
            $([System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini")) | Should -Exist
        }
    }
}
