<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe "Invoke-OutputFilter" {
        BeforeEach {
            Mock Get-EvergreenAppsPath { "/evergreen-test" }
            Mock Get-FilteredData { "filtered-$($InputObject.Value)" }
        }

        It "Passes pipeline input through when no filter exists" {
            Mock Test-Path { $false }
            $InputObject = [PSCustomObject]@{ Value = "original" }

            $Result = $InputObject | Invoke-OutputFilter -Name "Example"

            [System.Object]::ReferenceEquals($Result, $InputObject) | Should -BeTrue
            Should -Invoke Get-FilteredData -Times 0 -Exactly
        }

        It "Applies the matching filter to each non-null pipeline item" {
            Mock Test-Path { $true }
            $InputObjects = @(
                [PSCustomObject]@{ Value = "first" }
                [PSCustomObject]@{ Value = "second" }
            )

            $Result = @($InputObjects | Invoke-OutputFilter -Name "Example")

            $Result | Should -Be @("filtered-first", "filtered-second")
            Should -Invoke Get-FilteredData -Times 2 -Exactly -ParameterFilter {
                $FilterPath -eq [System.IO.Path]::Combine("/evergreen-test", "Filters", "Example.json")
            }
        }

        It "Passes null input through without invoking the data filter" {
            Mock Test-Path { $true }

            $Result = Invoke-OutputFilter -InputObject $null -Name "Example"

            $Result | Should -BeNull
            Should -Invoke Get-FilteredData -Times 0 -Exactly
        }
    }
}
