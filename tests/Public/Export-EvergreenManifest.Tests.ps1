<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
    # Get the supported applications
    # Sort randomly so that we get test various GitHub applications when we have API request limits
    $Applications = Find-EvergreenApp | `
        Sort-Object { Get-Random } | Select-Object -ExpandProperty "Name"
}

Describe -Tag "Export" -Name "Export-EvergreenManifest" -ForEach $Applications {
    BeforeAll {
        # Renaming the automatic $_ variable to $application to make it easier to work with
        $application = $_
        $Manifest = Export-EvergreenManifest -Name $application
    }

    Context "Validate Export-EvergreenManifest works with: <application>." {
        It "'Export-EvergreenManifest -Name <application>' should not throw" {
            { Export-EvergreenManifest -Name $application } | Should -Not -Throw
        }
    }

    Context "Validate Export-EvergreenManifest output object properties." {
        It "Has expected property Name" {
            $Manifest.Name.Length | Should -BeGreaterThan 0
        }

        It "Has expected property Source" {
            $Manifest.Source.Length | Should -BeGreaterThan 0
        }

        It "Has expected property Get" {
            $Manifest.Get.Length | Should -BeGreaterThan 0
        }
    }
}

Describe -Tag "Export" -Name "Export-EvergreenManifest fail tests" {
    Context "Validate Export-EvergreenManifest fails gracefully" {
        It "Should Throw with invalid app" {
            { Export-EvergreenManifest -Name "NonExistentApplication" } | Should -Throw
        }
    }
}
