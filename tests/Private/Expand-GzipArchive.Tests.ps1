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

        It "Should throw when the destination is the source file" {
            InModuleScope -ModuleName "Evergreen" {
                $Path = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini.gz")
                { Expand-GzipArchive -Path $Path -DestinationPath $Path } | Should -Throw
            }
        }

        It "Should throw when an inferred destination has no .gz suffix" {
            InModuleScope -ModuleName "Evergreen" {
                $Path = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini.gz")
                $NonGzipPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString("N"))
                [System.IO.File]::Copy($Path, $NonGzipPath)
                try {
                    { Expand-GzipArchive -Path $NonGzipPath } | Should -Throw
                }
                finally {
                    Remove-Item -LiteralPath $NonGzipPath -Force
                }
            }
        }

        It "Should throw when the buffer size is not positive" {
            InModuleScope -ModuleName "Evergreen" {
                $Path = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini.gz")
                { Expand-GzipArchive -Path $Path -BufferSize 0 } | Should -Throw
                { Expand-GzipArchive -Path $Path -BufferSize -1 } | Should -Throw
            }
        }

        It "Should expand to a relative destination in the current directory" {
            InModuleScope -ModuleName "Evergreen" {
                $Path = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "tests", "TestFile.ini.gz")
                $Directory = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString("N"))
                $null = New-Item -Path $Directory -ItemType Directory
                Push-Location -LiteralPath $Directory
                try {
                    Expand-GzipArchive -Path $Path -DestinationPath "Expanded.ini" | Should -Be "Expanded.ini"
                    Test-Path -LiteralPath "Expanded.ini" -PathType Leaf | Should -BeTrue
                }
                finally {
                    Pop-Location
                    Remove-Item -LiteralPath $Directory -Recurse -Force
                }
            }
        }

        It "Should preserve an existing destination when decompression fails" {
            InModuleScope -ModuleName "Evergreen" {
                $Directory = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString("N"))
                $null = New-Item -Path $Directory -ItemType Directory
                $Path = [System.IO.Path]::Combine($Directory, "invalid.gz")
                $DestinationPath = [System.IO.Path]::Combine($Directory, "expanded.ini")
                [System.IO.File]::WriteAllBytes($Path, [byte[]]@(1, 2, 3))
                [System.IO.File]::WriteAllText($DestinationPath, "existing content")
                try {
                    { Expand-GzipArchive -Path $Path -DestinationPath $DestinationPath } | Should -Throw
                    [System.IO.File]::ReadAllText($DestinationPath) | Should -Be "existing content"
                    @([System.IO.Directory]::GetFiles($Directory, "*.tmp")) | Should -HaveCount 0
                }
                finally {
                    Remove-Item -LiteralPath $Directory -Recurse -Force
                }
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
