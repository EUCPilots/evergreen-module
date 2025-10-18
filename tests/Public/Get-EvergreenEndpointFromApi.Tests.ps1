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

Describe -Tag "Get" -Name "Get-EvergreenEndpointFromApi" {
    Context "Validate Get-EvergreenEndpointFromApi parameter validation" {
        It "Should throw when Name parameter is null or empty" {
            { Get-EvergreenEndpointFromApi -Name "" } | Should -Throw
        }

        It "Should not throw with valid application name" {
            { Get-EvergreenEndpointFromApi -Name "MicrosoftEdge" } | Should -Not -Throw
        }
    }

    Context "Validate Get-EvergreenEndpointFromApi with known application" {
        BeforeAll {
            $script:Result = Get-EvergreenEndpointFromApi -Name "MicrosoftEdge" -ErrorAction "SilentlyContinue"
        }

        It "Should return data for known application" {
            $script:Result | Should -Not -BeNullOrEmpty
        }

        It "Should return an object with expected properties" {
            if ($script:Result) {
                $script:Result.PSObject.Properties.Name | Should -Contain "Name"
            }
        }
    }

    Context "Validate Get-EvergreenEndpointFromApi with unknown application" {
        It "Should handle unknown application gracefully" {
            { Get-EvergreenEndpointFromApi -Name "NonExistentApplication12345" -ErrorAction Stop } | Should -Throw
        }
    }
}
