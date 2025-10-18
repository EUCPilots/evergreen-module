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
                $script:Result.PSObject.Properties.Name | Should -Contain "Application"
            }
        }
    }

    Context "Validate Get-EvergreenEndpointFromApi with unknown application" {
        It "Should handle unknown application gracefully" {
            { Get-EvergreenEndpointFromApi -Name "NonExistentApplication12345" -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe -Name "Get-EvergreenEndpointFromApi returns a list of endpoints" {
    Context "Calling Get-EvergreenEndpointFromApi returns the list of endpoints" {
        It "Should return a list of endpoints" {
            $Output = Get-EvergreenEndpointFromApi
            $Output | Should -Not -BeNullOrEmpty
        }

        It "Should return an Endpoints property" {
            $Output = Get-EvergreenEndpointFromApi
            $Output.Endpoints | Should -BeOfType "String"
        }

        It "Should return a Ports property" {
            $Output = Get-EvergreenEndpointFromApi
            $Output.Ports | Should -BeOfType "String"
        }
    }
}

Describe -Name "Get-EvergreenEndpoint returns a list of endpoints for a single application" {
    Context "Calling Get-EvergreenEndpoint -Name returns the list of endpoints for a single application" {
        It "Should return a list of endpoints for Microsoft Edge" {
            $Output = Get-EvergreenEndpointFromApi -Name "MicrosoftEdge"
            $Output | Should -Not -BeNullOrEmpty
        }

        It "Should return a single object for Microsoft Edge" {
            $Output = Get-EvergreenEndpointFromApi -Name "MicrosoftEdge"
            $Output.Count | Should -HaveCount 1
        }
    }
}
