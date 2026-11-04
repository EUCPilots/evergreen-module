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
}

Describe -Tag "Get" -Name "Get-EvergreenAppFromLibrary" {
    Context "Validate Get-EvergreenAppFromLibrary with invalid input" {
        It "Should throw when Inventory parameter is null" {
            { Get-EvergreenAppFromLibrary -Inventory $null -Name "MicrosoftEdge" } | Should -Throw
        }

        It "Should throw when Inventory object doesn't have Inventory property" {
            $InvalidObject = [PSCustomObject]@{
                Property1 = "Value1"
            }
            { Get-EvergreenAppFromLibrary -Inventory $InvalidObject -Name "MicrosoftEdge" } | Should -Throw
        }

        It "Should throw when Name parameter is null or empty" {
            $ValidInventory = [PSCustomObject]@{
                Inventory = @()
            }
            { Get-EvergreenAppFromLibrary -Inventory $ValidInventory -Name "" } | Should -Throw
        }
    }

    Context "Validate Get-EvergreenAppFromLibrary with valid library" -Tag "Integration" -Skip {
        BeforeAll {
            # This test requires a valid Evergreen library, which may not exist in CI
            # Mark as skip for now, but can be enabled in local testing
            try {
                $script:Library = Get-EvergreenLibrary -ErrorAction "Stop"
            }
            catch {
                $script:Library = $null
            }
        }

        It "Should not throw with valid library and application name" -Skip:($null -eq $script:Library) {
            { Get-EvergreenAppFromLibrary -Inventory $script:Library -Name "MicrosoftEdge" } | Should -Not -Throw
        }

        It "Should return application data" -Skip:($null -eq $script:Library) {
            $Result = Get-EvergreenAppFromLibrary -Inventory $script:Library -Name "MicrosoftEdge"
            $Result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Validate Get-EvergreenAppFromLibrary with mock data" {
        BeforeAll {
            # Create a mock library inventory
            $script:MockLibrary = [PSCustomObject]@{
                Inventory = @(
                    [PSCustomObject]@{
                        ApplicationName = "MicrosoftEdge"
                        Versions = @(
                            [PSCustomObject]@{
                                Version = "130.0.2849.68"
                                Architecture = "x64"
                                Channel = "Stable"
                            }
                            [PSCustomObject]@{
                                Version = "130.0.2849.56"
                                Architecture = "x64"
                                Channel = "Stable"
                            }
                        )
                    }
                    [PSCustomObject]@{
                        ApplicationName = "GoogleChrome"
                        Versions = @(
                            [PSCustomObject]@{
                                Version = "130.0.6723.92"
                                Architecture = "x64"
                            }
                        )
                    }
                )
            }
        }

        It "Should not throw with valid mock library" {
            { Get-EvergreenAppFromLibrary -Inventory $script:MockLibrary -Name "MicrosoftEdge" } | Should -Not -Throw
        }

        It "Should return application data for existing application" {
            $Result = Get-EvergreenAppFromLibrary -Inventory $script:MockLibrary -Name "MicrosoftEdge"
            $Result | Should -Not -BeNullOrEmpty
        }

        It "Should return correct number of versions" {
            $Result = Get-EvergreenAppFromLibrary -Inventory $script:MockLibrary -Name "MicrosoftEdge"
            ($Result | Measure-Object).Count | Should -Be 2
        }

        It "Should return versions sorted in descending order" {
            $Result = Get-EvergreenAppFromLibrary -Inventory $script:MockLibrary -Name "MicrosoftEdge"
            $Result[0].Version | Should -Be "130.0.2849.68"
            $Result[1].Version | Should -Be "130.0.2849.56"
        }

        It "Should produce error for non-existent application" {
            { Get-EvergreenAppFromLibrary -Inventory $script:MockLibrary -Name "NonExistentApp" -ErrorAction Stop } | Should -Throw
        }

        It "Should accept an empty Inventory property and report a missing application" {
            $EmptyInventory = [PSCustomObject]@{ Inventory = @() }
            { Get-EvergreenAppFromLibrary -Inventory $EmptyInventory -Name "Missing" -ErrorAction Stop } |
                Should -Throw -ExpectedMessage "*Cannot find an application*"
        }

        It "Should sort numeric and nonstandard versions consistently" {
            $Inventory = [PSCustomObject]@{
                Inventory = @(
                    [PSCustomObject]@{
                        ApplicationName = "MixedVersions"
                        Versions = @(
                            [PSCustomObject]@{ Version = "2.0.0-rc.1" }
                            [PSCustomObject]@{ Version = "1.0.0" }
                            [PSCustomObject]@{ Version = "3.0.0" }
                        )
                    }
                )
            }

            $Result = @(Get-EvergreenAppFromLibrary -Inventory $Inventory -Name "MixedVersions")
            ($Result.Version -join ",") | Should -Be "3.0.0,1.0.0,2.0.0-rc.1"
        }
    }

    Context "Validate Get-EvergreenAppFromLibrary alias" {
        It "Get-EvergreenLibraryApp should be an alias for Get-EvergreenAppFromLibrary" {
            $Alias = Get-Alias -Name "Get-EvergreenLibraryApp" -ErrorAction "SilentlyContinue"
            $Alias.ResolvedCommandName | Should -Be "Get-EvergreenAppFromLibrary"
        }
    }
}
