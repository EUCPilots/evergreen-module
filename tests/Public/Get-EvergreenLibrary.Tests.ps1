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

Describe -Tag "Get" -Name "Get-EvergreenLibrary" {
    Context "Validate Get-EvergreenLibrary basic functionality" {
        It "Should not throw" {
            { Get-EvergreenLibrary } | Should -Not -Throw
        }
    }

    Context "Validate Get-EvergreenLibrary with valid library" -Skip {
        BeforeAll {
            # This test requires Update-Evergreen to have been run first
            # Mark as skip for CI environments where the library may not exist
            try {
                $script:Library = Get-EvergreenLibrary -ErrorAction "Stop"
            }
            catch {
                $script:Library = $null
            }
        }

        It "Should return library data if available" -Skip:($null -eq $script:Library) {
            $script:Library | Should -Not -BeNullOrEmpty
        }

        It "Should return object with Inventory property" -Skip:($null -eq $script:Library) {
            $script:Library.PSObject.Properties.Name | Should -Contain "Inventory"
        }

        It "Inventory should contain application data" -Skip:($null -eq $script:Library) {
            if ($script:Library.Inventory) {
                ($script:Library.Inventory | Measure-Object).Count | Should -BeGreaterThan 0
            }
        }
    }
}
