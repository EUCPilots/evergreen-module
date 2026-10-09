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
    Context "Validate Shell extraction and expand.exe fallback" {
        BeforeAll {
            $OriginalSystemRoot = $env:SystemRoot
            $env:SystemRoot = $TestDrive
            $NeedsComStub = -not (Get-Command -Name New-Object).Parameters.ContainsKey("ComObject")
            if ($NeedsComStub) {
                InModuleScope -ModuleName "Evergreen" {
                    function script:New-Object {
                        param ([System.String] $ComObject)
                        throw "COM creation must be mocked in these tests."
                    }
                }
            }
        }

        AfterAll {
            $env:SystemRoot = $OriginalSystemRoot
            if ($NeedsComStub) {
                InModuleScope -ModuleName "Evergreen" {
                    Remove-Item -Path "Function:New-Object"
                }
            }
        }

        BeforeEach {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ TestRoot = $TestDrive } {
                param ($TestRoot)

                $script:CabPath = Join-Path -Path $TestRoot -ChildPath "test.cab"
                $script:CabDestination = Join-Path -Path $TestRoot -ChildPath "destination"
                $script:ExpandStub = Join-Path -Path $TestRoot -ChildPath "expand.ps1"
                Set-Content -Path $script:CabPath -Value "test"
                New-Item -Path $script:CabDestination -ItemType "Directory" -Force | Out-Null
                Set-Content -Path $script:ExpandStub -Value @'
param ($CabPath, [switch] $I, $Destination)
Set-Content -Path (Join-Path -Path $Destination -ChildPath "expanded.txt") -Value "expanded"
'@

                Mock Test-IsWindows { $true }
                Mock Join-Path { $script:ExpandStub } -ParameterFilter { $ChildPath -eq "System32\expand.exe" }

                $script:SourceCab = [PSCustomObject]@{ Entries = $null }
                $script:SourceCab | Add-Member -MemberType ScriptMethod -Name Items -Value { $this.Entries }
                $script:DestinationFolder = [PSCustomObject]@{ Copied = $false }
                $script:DestinationFolder | Add-Member -MemberType ScriptMethod -Name CopyHere -Value { $this.Copied = $true }
                $script:Shell = [PSCustomObject]@{
                    CabPath = $script:CabPath
                    Source = $script:SourceCab
                    Destination = $script:DestinationFolder
                }
                $script:Shell | Add-Member -MemberType ScriptMethod -Name NameSpace -Value {
                    param ($FolderPath)
                    if ($FolderPath -eq $this.CabPath) { $this.Source }
                    else { $this.Destination }
                }
                Mock New-Object { $script:Shell } -ParameterFilter { $ComObject -eq "Shell.Application" }
                Mock Remove-Item {}
            }
        }

        It "Should retry with expand.exe when Shell returns <Case> items" -TestCases @(
            @{ Case = "null"; Entries = $null }
            @{ Case = "empty"; Entries = @() }
        ) {
            param ($Case, $Entries)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ Entries = $Entries } {
                param ($Entries)

                $script:SourceCab.Entries = $Entries
                $Items = Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination

                Split-Path -Path $Items -Leaf | Should -Be "expanded.txt"
                Test-Path -Path $Items -PathType "Leaf" | Should -BeTrue
                $script:DestinationFolder.Copied | Should -BeFalse
                Should -Invoke Remove-Item -Times 0 -Exactly
            }
        }

        It "Should still retry with expand.exe when Shell throws" {
            InModuleScope -ModuleName "Evergreen" {
                Mock New-Object { throw "COM unavailable" } -ParameterFilter { $ComObject -eq "Shell.Application" }

                $Items = Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination

                Split-Path -Path $Items -Leaf | Should -Be "expanded.txt"
                Test-Path -Path $Items -PathType "Leaf" | Should -BeTrue
            }
        }

        It "Should not retry when Shell returns items" {
            InModuleScope -ModuleName "Evergreen" {
                $script:SourceCab.Entries = @([PSCustomObject]@{ Name = "shell.txt" })

                $Items = Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination

                $Items | Should -Be (Join-Path -Path $script:CabDestination -ChildPath "shell.txt")
                $script:DestinationFolder.Copied | Should -BeTrue
                Should -Invoke Join-Path -Times 0 -Exactly -ParameterFilter { $ChildPath -eq "System32\expand.exe" }
            }
        }

        It "Should throw when neither extraction approach returns items" {
            InModuleScope -ModuleName "Evergreen" {
                Set-Content -Path $script:ExpandStub -Value 'param ($CabPath, [switch] $I, $Destination)'

                { Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination } |
                    Should -Throw "Failed to expand CAB file*"
            }
        }
    }

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
