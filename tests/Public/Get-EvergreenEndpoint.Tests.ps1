<#
    .SYNOPSIS
        Get-EvergreenEndpoint Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

Describe -Name "Get-EvergreenEndpoint returns a list of endpoints" {
    Context "Calling Get-EvergreenEndpoint returns the list of endpoints" {
        It "Should return a list of endpoints" {
            $Output = Get-EvergreenEndpoint
            $Output | Should -Not -BeNullOrEmpty
        }

        It "Should return an Endpoints property" {
            $Output = Get-EvergreenEndpoint
            $Output.Endpoints | Should -BeOfType "String"
        }

        It "Should return a Ports property" {
            $Output = Get-EvergreenEndpoint
            $Output.Ports | Should -BeOfType "String"
        }
    }
}

Describe -Name "Get-EvergreenEndpoint returns a list of endpoints for a single application" {
    Context "Calling Get-EvergreenEndpoint -Name returns the list of endpoints for a single application" {
        It "Should return a list of endpoints for Microsoft Edge" {
            $Output = Get-EvergreenEndpoint -Name "MicrosoftEdge"
            $Output | Should -Not -BeNullOrEmpty
        }

        It "Should return a single object for Microsoft Edge" {
            $Output = Get-EvergreenEndpoint -Name "MicrosoftEdge"
            $Output.Count | Should -HaveCount 1
        }
    }
}

Describe -Name "Get-EvergreenEndpoint fail tests" {
    Context "Get-EvergreenEndpoint returns null from a non-supported application" {
        It "Should throw with invalid app" {
            Get-EvergreenEndpoint -Name "NonExistentApplication" | Should -BeNullOrEmpty
        }
    }
}
