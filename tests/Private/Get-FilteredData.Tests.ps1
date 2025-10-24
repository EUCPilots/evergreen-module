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
    # Create temporary directory for test JSON files
    if ($env:Temp) {
        $script:TestPath = Join-Path -Path $env:Temp -ChildPath "GetFilteredDataTests"
    }
    elseif ($env:TMPDIR) {
        $script:TestPath = Join-Path -Path $env:TMPDIR -ChildPath "GetFilteredDataTests"
    }
    else {
        $script:TestPath = "/tmp/GetFilteredDataTests"
    }
    New-Item -Path $script:TestPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

    # Create test data
    $script:TestData = @(
        [PSCustomObject]@{ Release = "Enterprise"; Architecture = "x64"; Version = "1.0.0"; Channel = "Stable" }
        [PSCustomObject]@{ Release = "Enterprise"; Architecture = "ARM64"; Version = "1.0.0"; Channel = "Stable" }
        [PSCustomObject]@{ Release = "Professional"; Architecture = "x64"; Version = "1.1.0"; Channel = "Beta" }
        [PSCustomObject]@{ Release = "Enterprise"; Architecture = "x86"; Version = "2.0.0"; Channel = "Stable" }
        [PSCustomObject]@{ Release = "Professional"; Architecture = "x64"; Version = "2.5.0"; Channel = "Stable" }
    )
}

AfterAll {
    # Clean up test directory
    if (Test-Path -Path $script:TestPath) {
        Remove-Item -Path $script:TestPath -Recurse -Force -ErrorAction "SilentlyContinue"
    }
}

Describe -Tag "Private" -Name "Get-FilteredData" {
    Context "Validate Get-FilteredData with equality operator" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-eq.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Release"
                        operator = "eq"
                        value    = "Enterprise"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should not throw with valid filter" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-eq.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                { Get-FilteredData -FilterPath $FilterFile -InputObject $TestData } | Should -Not -Throw
            }
        }

        It "Should return matching items" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-eq.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 3
            }
        }

        It "Should return only items where Release equals Enterprise" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-eq.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | ForEach-Object { $_.Release | Should -Be "Enterprise" }
            }
        }
    }

    Context "Validate Get-FilteredData with multiple AND filters" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-and.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Release"
                        operator = "eq"
                        value    = "Enterprise"
                    }
                    @{
                        property = "Architecture"
                        operator = "eq"
                        value    = "x64"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should return items matching all conditions" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-and.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 1
                $Result.Release | Should -Be "Enterprise"
                $Result.Architecture | Should -Be "x64"
            }
        }
    }

    Context "Validate Get-FilteredData with multiple OR filters" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-or.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Architecture"
                        operator = "eq"
                        value    = "x64"
                    }
                    @{
                        property = "Architecture"
                        operator = "eq"
                        value    = "ARM64"
                    }
                )
                logicalOperator = "or"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should return items matching any condition" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-or.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 4
            }
        }

        It "Should return items with x64 or ARM64 architecture" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-or.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result.Architecture | ForEach-Object { $_ | Should -BeIn @("x64", "ARM64") }
            }
        }
    }

    Context "Validate Get-FilteredData with 'ne' (not equal) operator" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-ne.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Architecture"
                        operator = "ne"
                        value    = "x86"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should exclude items matching the condition" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-ne.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 4
                $Result.Architecture | ForEach-Object { $_ | Should -Not -Be "x86" }
            }
        }
    }

    Context "Validate Get-FilteredData with 'like' operator" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-like.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Release"
                        operator = "like"
                        value    = "*prise"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should return items matching the pattern" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-like.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 3
                $Result.Release | ForEach-Object { $_ | Should -BeLike "*prise" }
            }
        }
    }

    Context "Validate Get-FilteredData with 'match' (regex) operator" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-match.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Version"
                        operator = "match"
                        value    = "^2\."
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should return items matching the regex pattern" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-match.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 2
                $Result.Version | ForEach-Object { $_ | Should -Match "^2\." }
            }
        }
    }

    Context "Validate Get-FilteredData with 'in' operator" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-in.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Architecture"
                        operator = "in"
                        value    = @("x64", "ARM64")
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should return items where property is in value array" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-in.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 4
                $Result.Architecture | ForEach-Object { $_ | Should -BeIn @("x64", "ARM64") }
            }
        }
    }

    Context "Validate Get-FilteredData with comparison operators" {
        BeforeAll {
            # Greater than
            $FilterFileGt = Join-Path -Path $script:TestPath -ChildPath "filter-gt.json"
            $FilterJsonGt = @{
                filters = @(
                    @{
                        property = "Version"
                        operator = "gt"
                        value    = "1.5.0"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFileGt -Value $FilterJsonGt -Force

            # Less than
            $FilterFileLt = Join-Path -Path $script:TestPath -ChildPath "filter-lt.json"
            $FilterJsonLt = @{
                filters = @(
                    @{
                        property = "Version"
                        operator = "lt"
                        value    = "2.0.0"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFileLt -Value $FilterJsonLt -Force
        }

        It "Should filter using greater than operator" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-gt.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 2
            }
        }

        It "Should filter using less than operator" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-lt.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 3
            }
        }
    }

    Context "Validate Get-FilteredData with default logical operator" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-no-logic.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Release"
                        operator = "eq"
                        value    = "Enterprise"
                    }
                    @{
                        property = "Architecture"
                        operator = "eq"
                        value    = "x64"
                    }
                )
                # No logicalOperator specified - should default to "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should default to AND logic when logicalOperator is not specified" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-no-logic.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 1
            }
        }
    }

    Context "Validate Get-FilteredData with empty results" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-empty.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Release"
                        operator = "eq"
                        value    = "NonExistent"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should return empty array when no items match" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-empty.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -BeNullOrEmpty
            }
        }
    }

    Context "Validate Get-FilteredData parameter validation" {
        It "Should throw when FilterPath parameter is empty" {
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ TestData = $TestData } {
                param($TestData)
                { Get-FilteredData -FilterPath "" -InputObject $TestData } | Should -Throw
            }
        }

        It "Should throw when FilterPath does not exist" {
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ TestData = $TestData } {
                param($TestData)
                { Get-FilteredData -FilterPath "/nonexistent/filter.json" -InputObject $TestData -ErrorAction Stop } | Should -Throw
            }
        }

        It "Should throw when InputObject parameter is empty" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-eq.json"
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile } {
                param($FilterFile)
                { Get-FilteredData -FilterPath $FilterFile -InputObject @() } | Should -Not -Throw
            }
        }
    }

    Context "Validate Get-FilteredData with invalid JSON" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-invalid.json"
            Set-Content -Path $FilterFile -Value "{ invalid json }" -Force
        }

        It "Should throw with invalid JSON" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-invalid.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                { Get-FilteredData -FilterPath $FilterFile -InputObject $TestData -ErrorAction Stop } | Should -Throw
            }
        }
    }

    Context "Validate Get-FilteredData output type" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-output.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Channel"
                        operator = "eq"
                        value    = "Stable"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should return array of objects" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-output.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -BeOfType [System.Object]
            }
        }

        It "Should preserve object properties" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-output.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result[0].PSObject.Properties.Name | Should -Contain "Release"
                $Result[0].PSObject.Properties.Name | Should -Contain "Architecture"
                $Result[0].PSObject.Properties.Name | Should -Contain "Version"
                $Result[0].PSObject.Properties.Name | Should -Contain "Channel"
            }
        }
    }

    Context "Validate Get-FilteredData with default operator fallback" {
        BeforeAll {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-no-operator.json"
            $FilterJson = @{
                filters = @(
                    @{
                        property = "Release"
                        # No operator specified - should default to "eq"
                        value    = "Enterprise"
                    }
                )
                logicalOperator = "and"
            } | ConvertTo-Json -Depth 10
            Set-Content -Path $FilterFile -Value $FilterJson -Force
        }

        It "Should default to equality operator when operator is not specified" {
            $FilterFile = Join-Path -Path $script:TestPath -ChildPath "filter-no-operator.json"
            $TestData = $script:TestData
            InModuleScope -ModuleName "Evergreen" -Parameters @{ FilterFile = $FilterFile; TestData = $TestData } {
                param($FilterFile, $TestData)
                $Result = Get-FilteredData -FilterPath $FilterFile -InputObject $TestData
                $Result | Should -Not -BeNullOrEmpty
                ($Result | Measure-Object).Count | Should -Be 3
                $Result.Release | ForEach-Object { $_ | Should -Be "Enterprise" }
            }
        }
    }
}
