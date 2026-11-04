<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe "Get-VersionItemSortData" {
        It "Parses a valid version and retains its source item and index" {
            $Item = [PSCustomObject]@{ Version = "1.2.3" }

            $Result = Get-VersionItemSortData -Item $Item -Index 4

            [System.Object]::ReferenceEquals($Result.Item, $Item) | Should -BeTrue
            $Result.Index | Should -Be 4
            $Result.VersionText | Should -Be "1.2.3"
            $Result.ParsedVersion | Should -Be ([System.Version]"1.2.3")
            $Result.HasParsedVersion | Should -BeTrue
        }

        It "Retains unparseable and missing versions without marking them parsed" -TestCases @(
            @{ Item = [PSCustomObject]@{ Version = "preview" }; ExpectedText = "preview" }
            @{ Item = [PSCustomObject]@{ Version = "" }; ExpectedText = "" }
            @{ Item = [PSCustomObject]@{}; ExpectedText = "" }
        ) {
            param ($Item, $ExpectedText)

            $Result = Get-VersionItemSortData -Item $Item -Index 0

            $Result.VersionText | Should -Be $ExpectedText
            $Result.ParsedVersion | Should -BeNull
            $Result.HasParsedVersion | Should -BeFalse
        }
    }
}
