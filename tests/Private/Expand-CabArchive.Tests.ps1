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
param (
    [Parameter(Position = 0)]
    [System.String] $CabPath,
    [Parameter(Position = 1)]
    [System.String] $Destination,
    [System.Management.Automation.SwitchParameter] $D
)
if ($D) {
    Write-Output "   expanded.txt"
    exit 0
}
Set-Content -Path (Join-Path -Path $Destination -ChildPath "expanded.txt") -Value "expanded"
'@

                Mock Test-IsWindows { $true }
                Mock Join-Path { $script:ExpandStub } -ParameterFilter { $ChildPath -eq "System32\expand.exe" }

                $script:SourceCab = [PSCustomObject]@{ Entries = $null }
                $script:SourceCab | Add-Member -MemberType ScriptMethod -Name Items -Value { $this.Entries }
                $script:DestinationFolder = [PSCustomObject]@{
                    Copied = $false
                    Path   = $script:CabDestination
                }
                $script:DestinationFolder | Add-Member -MemberType ScriptMethod -Name CopyHere -Value {
                    param ($Items, $Options)
                    $this.Copied = $true
                    foreach ($Item in $Items) {
                        Set-Content -LiteralPath (Join-Path -Path $this.Path -ChildPath $Item.Name) -Value "shell"
                    }
                }
                $script:Shell = [PSCustomObject]@{
                    CabPath = $script:CabPath
                    Source = $script:SourceCab
                    Destination = $script:DestinationFolder
                }
                $script:Shell | Add-Member -MemberType ScriptMethod -Name NameSpace -Value {
                    param ($FolderPath)
                    if ($FolderPath -eq $this.CabPath) { $this.Source }
                    else {
                        $this.Destination.Path = $FolderPath
                        $this.Destination
                    }
                }
                Mock New-Object { $script:Shell } -ParameterFilter { $ComObject -eq "Shell.Application" }
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

        It "Should reject unsafe CAB entry paths without invoking the fallback" {
            InModuleScope -ModuleName "Evergreen" {
                $script:SourceCab.Entries = @([PSCustomObject]@{ Name = "..\escaped.txt" })

                { Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination } |
                    Should -Throw "*Refusing to extract unsafe CAB entry*"

                Should -Invoke Join-Path -Times 0 -Exactly -ParameterFilter { $ChildPath -eq "System32\expand.exe" }
                Test-Path -LiteralPath (Join-Path -Path $script:CabDestination -ChildPath "escaped.txt") | Should -BeFalse
            }
        }

        It "Should reject Windows reserved and normalizing file names" -TestCases @(
            @{ Name = "CON.txt" }
            @{ Name = "trailing-dot." }
            @{ Name = "trailing-space " }
        ) {
            param ($Name)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ EntryName = $Name } {
                param ($EntryName)

                $script:SourceCab.Entries = @([PSCustomObject]@{ Name = $EntryName })

                { Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination } |
                    Should -Throw "*Refusing to extract unsafe CAB entry*"

                Should -Invoke Join-Path -Times 0 -Exactly -ParameterFilter { $ChildPath -eq "System32\expand.exe" }
            }
        }

        It "Should resolve a relative destination path from the current location" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ TestRoot = $TestDrive } {
                param ($TestRoot)

                $OriginalLocation = Get-Location
                $RelativeDestination = "relative-destination-$([System.Guid]::NewGuid().ToString('N'))"
                try {
                    Set-Location -LiteralPath $TestRoot
                    $script:SourceCab.Entries = @([PSCustomObject]@{ Name = "shell.txt" })

                    $Items = Expand-CabArchive -Path $script:CabPath -DestinationPath $RelativeDestination

                    $Items | Should -Be (Join-Path -Path $TestRoot -ChildPath "$RelativeDestination\shell.txt")
                    Test-Path -LiteralPath $Items -PathType "Leaf" | Should -BeTrue
                }
                finally {
                    $TestDestination = Join-Path -Path $TestRoot -ChildPath $RelativeDestination
                    if (Test-Path -LiteralPath $TestDestination) {
                        Remove-Item -LiteralPath $TestDestination -Recurse -Force
                    }
                    Set-Location -LiteralPath $OriginalLocation
                }
            }
        }

        It "Should support destination paths containing wildcard characters" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ TestRoot = $TestDrive } {
                param ($TestRoot)

                $LiteralDestination = [System.IO.Path]::Combine($TestRoot, "destination[1]")
                $script:SourceCab.Entries = @([PSCustomObject]@{ Name = "shell.txt" })

                $Items = Expand-CabArchive -Path $script:CabPath -DestinationPath $LiteralDestination

                $Items | Should -Be ([System.IO.Path]::Combine($LiteralDestination, "shell.txt"))
                Test-Path -LiteralPath $Items -PathType "Leaf" | Should -BeTrue
            }
        }

        It "Should roll back promoted files and restore overwritten files when promotion fails" {
            InModuleScope -ModuleName "Evergreen" {
                $script:SourceCab.Entries = @(
                    [PSCustomObject]@{ Name = "first.txt" }
                    [PSCustomObject]@{ Name = "second.txt" }
                )
                $FirstDestination = Join-Path -Path $script:CabDestination -ChildPath "first.txt"
                $script:SecondDestination = Join-Path -Path $script:CabDestination -ChildPath "second.txt"
                Set-Content -LiteralPath $FirstDestination -Value "original"
                Mock Move-Item { throw "Simulated promotion failure" } -ParameterFilter {
                    $Destination -eq $script:SecondDestination
                }

                { Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination } |
                    Should -Throw "*changes were rolled back*"

                ([System.IO.File]::ReadAllText($FirstDestination)).Trim() | Should -Be "original"
                Test-Path -LiteralPath $script:SecondDestination | Should -BeFalse
            }
        }

        It "Should throw when neither extraction approach returns items" {
            InModuleScope -ModuleName "Evergreen" {
                Set-Content -Path $script:ExpandStub -Value @'
param (
    [Parameter(Position = 0)]
    [System.String] $CabPath,
    [Parameter(Position = 1)]
    [System.String] $Destination,
    [System.Management.Automation.SwitchParameter] $D
)
if ($D) {
    Write-Output "   missing.txt"
    exit 0
}
'@

                { Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination } |
                    Should -Throw "*expand.exe did not extract all CAB files*"
            }
        }

        It "Should preserve existing destination files when both extraction methods fail" {
            InModuleScope -ModuleName "Evergreen" {
                $ExistingFile = Join-Path -Path $script:CabDestination -ChildPath "existing.txt"
                Set-Content -Path $ExistingFile -Value "keep"
                Set-Content -Path $script:ExpandStub -Value @'
param (
    [Parameter(Position = 0)]
    [System.String] $CabPath,
    [Parameter(Position = 1)]
    [System.String] $Destination,
    [System.Management.Automation.SwitchParameter] $D
)
if ($D) {
    Write-Output "   missing.txt"
    exit 0
}
'@

                { Expand-CabArchive -Path $script:CabPath -DestinationPath $script:CabDestination } |
                    Should -Throw "*expand.exe did not extract all CAB files*"

                ([System.IO.File]::ReadAllText($ExistingFile)).Trim() | Should -Be "keep"
            }
        }

        It "Should remove a newly created destination when extraction fails" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ TestRoot = $TestDrive } {
                param ($TestRoot)

                $NewDestination = [System.IO.Path]::Combine($TestRoot, "failed-destination")
                Set-Content -Path $script:ExpandStub -Value @'
param (
    [Parameter(Position = 0)]
    [System.String] $CabPath,
    [Parameter(Position = 1)]
    [System.String] $Destination,
    [System.Management.Automation.SwitchParameter] $D
)
'@

                { Expand-CabArchive -Path $script:CabPath -DestinationPath $NewDestination } |
                    Should -Throw "*verifiable CAB file list*"

                Test-Path -LiteralPath $NewDestination | Should -BeFalse
            }
        }
    }

    Context "Validate Expand-CabArchive parameter validation" {
        It "Should throw when Path parameter is null or empty" {
            InModuleScope -ModuleName "Evergreen" {
                { Expand-CabArchive -Path "" -DestinationPath "/tmp" } | Should -Throw
            }
        }

        It "Should require a destination path" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ TestRoot = $TestDrive } {
                param ($TestRoot)

                $CabPath = Join-Path -Path $TestRoot -ChildPath "mandatory-parameter.cab"
                Set-Content -LiteralPath $CabPath -Value "test"
                { Expand-CabArchive -Path $CabPath } | Should -Throw
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
