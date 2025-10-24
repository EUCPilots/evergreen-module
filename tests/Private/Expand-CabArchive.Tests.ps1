<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Private" -Name "Expand-CabArchive" {
    Context "Validate Expand-CabArchive parameter validation" {
        It "Should throw when Path parameter is null or empty" {
            InModuleScope -ModuleName "Evergreen" {
                { Expand-CabArchive -Path "" -DestinationPath "/tmp" } | Should -Throw
            }
        }

        It "Should throw when Path does not exist" {
            InModuleScope -ModuleName "Evergreen" {
                { Expand-CabArchive -Path "/nonexistent/file.cab" -DestinationPath "/tmp" -ErrorAction Stop } | Should -Throw
            }
        }

        It "Should throw when DestinationPath parent does not exist" {
            InModuleScope -ModuleName "Evergreen" {
                # Create a temp file to satisfy Path validation
                if ($env:Temp) {
                    $TestFile = Join-Path -Path $env:Temp -ChildPath "test.cab"
                }
                elseif ($env:TMPDIR) {
                    $TestFile = Join-Path -Path $env:TMPDIR -ChildPath "test.cab"
                }
                else {
                    $TestFile = "/tmp/test.cab"
                }
                
                "test" | Out-File -FilePath $TestFile -Force
                { Expand-CabArchive -Path $TestFile -DestinationPath "/nonexistent/path/file" -ErrorAction Stop } | Should -Throw
                Remove-Item -Path $TestFile -Force -ErrorAction "SilentlyContinue"
            }
        }
    }

    Context "Validate Expand-CabArchive on Windows" -Skip:(-not $IsWindows) {
        BeforeAll {
            # This would require a valid CAB file to test properly
            # Skipping actual expansion tests as they require Windows and valid CAB files
        }

        It "Should be available on Windows" -Skip:(-not $IsWindows) {
            InModuleScope -ModuleName "Evergreen" {
                Get-Command -Name Expand-CabArchive -ErrorAction "SilentlyContinue" | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Validate Expand-CabArchive on non-Windows" -Skip:($IsWindows) {
        It "Should handle non-Windows platforms" -Skip:($IsWindows) {
            InModuleScope -ModuleName "Evergreen" {
                # The function should handle non-Windows platforms gracefully
                Get-Command -Name Expand-CabArchive -ErrorAction "SilentlyContinue" | Should -Not -BeNullOrEmpty
            }
        }
    }
}
