<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
    function Get-TestTempPath {
        [CmdletBinding()]
        param ()

        if ($env:Temp) {
            return $env:Temp
        }
        if ($env:TMPDIR) {
            return $env:TMPDIR
        }
        return "/tmp"
    }

    function New-TestLibrary {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [System.String] $Path
        )

        New-Item -Path $Path -ItemType "Directory" -Force | Out-Null

        $library = [PSCustomObject] @{
            Name         = "EvergreenLibrary"
            Applications = @(
                [PSCustomObject] @{
                    Name         = "ContosoApp"
                    EvergreenApp = "ContosoApp"
                    Filter       = ""
                },
                [PSCustomObject] @{
                    Name         = "FabrikamApp"
                    EvergreenApp = "FabrikamApp"
                    Filter       = ""
                }
            )
        }
        $library | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path -Path $Path -ChildPath "EvergreenLibrary.json") -Encoding "Utf8" -NoNewline

        $contosoPath = Join-Path -Path $Path -ChildPath "ContosoApp"
        New-Item -Path $contosoPath -ItemType "Directory" -Force | Out-Null
        $contosoVersions = @()
        foreach ($version in @("1.0.0", "2.0.0", "3.0.0", "4.0.0")) {
            $installerName = "Contoso-$version.exe"
            $installerPath = Join-Path -Path $contosoPath -ChildPath $installerName
            Set-Content -Path $installerPath -Value "test" -Encoding "Utf8"
            $contosoVersions += [PSCustomObject] @{
                Version = $version
                URI     = "https://example.test/$installerName"
                Path    = $installerPath
            }
        }
        $contosoVersions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $contosoPath -ChildPath "ContosoApp.json") -Encoding "Utf8" -NoNewline

        $fabrikamPath = Join-Path -Path $Path -ChildPath "FabrikamApp"
        New-Item -Path $fabrikamPath -ItemType "Directory" -Force | Out-Null
        $fabrikamVersions = @()
        foreach ($version in @("1.0.0", "2.0.0")) {
            $installerName = "Fabrikam-$version.exe"
            $installerPath = Join-Path -Path $fabrikamPath -ChildPath $installerName
            Set-Content -Path $installerPath -Value "test" -Encoding "Utf8"
            $fabrikamVersions += [PSCustomObject] @{
                Version = $version
                URI     = "https://example.test/$installerName"
                Path    = $installerPath
            }
        }
        $fabrikamVersions | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $fabrikamPath -ChildPath "FabrikamApp.json") -Encoding "Utf8" -NoNewline
    }
}

Describe -Tag "Remove" -Name "Remove-EvergreenLibraryAppVersion" {
    Context "Validate pruning keeps latest versions" {
        BeforeEach {
            $script:LibPath = Join-Path -Path (Get-TestTempPath) -ChildPath "RemoveEvergreenLibraryAppVersionTest-$([System.Guid]::NewGuid().ToString())"
            New-TestLibrary -Path $script:LibPath
        }

        AfterEach {
            Remove-Item -Path $script:LibPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }

        It "Should remove old versions and keep latest 3 for ContosoApp" {
            $result = Remove-EvergreenLibraryAppVersion -Path $script:LibPath -Keep 3 -Name "ContosoApp" -Confirm:$false
            $result.ApplicationName | Should -Be "ContosoApp"
            $result.RemovedCount | Should -Be 1
            $result.KeptCount | Should -Be 3

            Test-Path -Path (Join-Path -Path $script:LibPath -ChildPath "ContosoApp/Contoso-1.0.0.exe") | Should -Be $false
            Test-Path -Path (Join-Path -Path $script:LibPath -ChildPath "ContosoApp/Contoso-2.0.0.exe") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:LibPath -ChildPath "ContosoApp/Contoso-3.0.0.exe") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:LibPath -ChildPath "ContosoApp/Contoso-4.0.0.exe") | Should -Be $true

            $manifest = @(Get-Content -Path (Join-Path -Path $script:LibPath -ChildPath "ContosoApp/ContosoApp.json") | ConvertFrom-Json)
            $manifest.Count | Should -Be 3
            ($manifest.Version -contains "1.0.0") | Should -Be $false
        }

        It "Should not prune apps not selected by Name" {
            Test-Path -Path (Join-Path -Path $script:LibPath -ChildPath "FabrikamApp/Fabrikam-1.0.0.exe") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:LibPath -ChildPath "FabrikamApp/Fabrikam-2.0.0.exe") | Should -Be $true
        }

        It "Should report pruning details on the verbose stream without changing result objects" {
            $records = @(Remove-EvergreenLibraryAppVersion -Path $script:LibPath -Keep 3 -Name "ContosoApp" -Confirm:$false -Verbose 4>&1)
            $messages = ($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
            $results = @($records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] })

            $results.Count | Should -Be 1
            $results[0].ApplicationName | Should -Be "ContosoApp"
            $results[0].RemovedFiles.Count | Should -Be 1
            $results[0].KeptCount | Should -Be 3
            $messages | Should -Match "Selected 1 of 2 applications"
            $messages | Should -Match "Found 4 version entries"
            $messages | Should -Match "Retaining version '4.0.0'"
            $messages | Should -Match "Pruning version '1.0.0'"
            $messages | Should -Match "Removed installer"
            $messages | Should -Match "Updated app manifest"
            $messages | Should -Match "1 installer files removed"
        }

        It "Should explain why pruning is unnecessary" {
            $records = @(Remove-EvergreenLibraryAppVersion -Path $script:LibPath -Keep 3 -Name "FabrikamApp" -Confirm:$false -Verbose 4>&1)
            $messages = ($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
            $result = $records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }

            $messages | Should -Match "No pruning required for 'FabrikamApp'"
            $result.RemovedCount | Should -Be 0
            $result.KeptCount | Should -Be 2
        }

        It "Should explain skipped installer removals" {
            $manifestPath = Join-Path -Path $script:LibPath -ChildPath "ContosoApp/ContosoApp.json"
            $versions = @(Get-Content -Path $manifestPath | ConvertFrom-Json)
            $versions[0].Path = ""
            Remove-Item -Path $versions[1].Path -Force
            $versions | ConvertTo-Json | Out-File -FilePath $manifestPath -Encoding "Utf8" -NoNewline

            $records = @(Remove-EvergreenLibraryAppVersion -Path $script:LibPath -Keep 2 -Name "ContosoApp" -Confirm:$false -Verbose 4>&1)
            $messages = ($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
            $result = $records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }

            $messages | Should -Match "no installer path is recorded"
            $messages | Should -Match "does not exist or is not a file"
            $result.RemovedFiles.Count | Should -Be 0
            $result.RemovedCount | Should -Be 2
        }

        It "Should report when no applications match the requested name" {
            $records = @(Remove-EvergreenLibraryAppVersion -Path $script:LibPath -Name "UnknownApp" -Verbose 4>&1)
            $messages = ($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
            $results = @($records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] })

            $messages | Should -Match "Selected 0 of 2 applications"
            $results.Count | Should -Be 0
        }
    }

    Context "Validate WhatIf does not delete installers or change manifest" {
        BeforeAll {
            $script:WhatIfLibPath = Join-Path -Path (Get-TestTempPath) -ChildPath "RemoveEvergreenLibraryAppVersionWhatIfTest-$([System.Guid]::NewGuid().ToString())"
            New-TestLibrary -Path $script:WhatIfLibPath

            $script:PreManifest = Get-Content -Path (Join-Path -Path $script:WhatIfLibPath -ChildPath "ContosoApp/ContosoApp.json") -Raw
        }

        AfterAll {
            Remove-Item -Path $script:WhatIfLibPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }

        It "Should only report actions when using WhatIf" {
            $records = @(Remove-EvergreenLibraryAppVersion -Path $script:WhatIfLibPath -Keep 3 -Name "ContosoApp" -WhatIf -Verbose 4>&1)
            $messages = ($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"

            $messages | Should -Match "Installer removal not approved by ShouldProcess"
            $messages | Should -Match "Manifest update not approved by ShouldProcess"
            $messages | Should -Match "0 installer files removed"
            $messages | Should -Not -Match ": Removed installer "
            $messages | Should -Not -Match ": Updated app manifest "

            Test-Path -Path (Join-Path -Path $script:WhatIfLibPath -ChildPath "ContosoApp/Contoso-1.0.0.exe") | Should -Be $true
            $postManifest = Get-Content -Path (Join-Path -Path $script:WhatIfLibPath -ChildPath "ContosoApp/ContosoApp.json") -Raw
            $postManifest | Should -Be $script:PreManifest
        }
    }
}