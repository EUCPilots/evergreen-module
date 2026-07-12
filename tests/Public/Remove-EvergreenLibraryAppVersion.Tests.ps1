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
        BeforeAll {
            $script:LibPath = Join-Path -Path (Get-TestTempPath) -ChildPath "RemoveEvergreenLibraryAppVersionTest-$([System.Guid]::NewGuid().ToString())"
            New-TestLibrary -Path $script:LibPath
        }

        AfterAll {
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
            $null = Remove-EvergreenLibraryAppVersion -Path $script:WhatIfLibPath -Keep 3 -Name "ContosoApp" -WhatIf

            Test-Path -Path (Join-Path -Path $script:WhatIfLibPath -ChildPath "ContosoApp/Contoso-1.0.0.exe") | Should -Be $true
            $postManifest = Get-Content -Path (Join-Path -Path $script:WhatIfLibPath -ChildPath "ContosoApp/ContosoApp.json") -Raw
            $postManifest | Should -Be $script:PreManifest
        }
    }
}