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

        It "Should return a dictionary object" {
            $Manifest | Should -BeOfType [System.Collections.IDictionary]
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

Describe -Tag "Export" -Name "Export-EvergreenManifest pipeline support" {
    Context "Validate Export-EvergreenManifest accepts pipeline input" {
        It "Should accept an application name by value from the pipeline" {
            $Manifest = "MicrosoftEdge" | Export-EvergreenManifest
            $Manifest.Name.Length | Should -BeGreaterThan 0
        }

        It "Should accept Find-EvergreenApp output by property name from the pipeline" {
            $Manifest = Find-EvergreenApp -Name "MicrosoftEdge" | Select-Object -First 1 | Export-EvergreenManifest
            $Manifest.Name.Length | Should -BeGreaterThan 0
        }

        It "Should return a manifest for each application name passed from the pipeline" {
            $Manifests = @("MicrosoftEdge", "MicrosoftTeams" | Export-EvergreenManifest)
            $Manifests.Count | Should -Be 2
        }
    }
}

Describe -Tag "Export" -Name "Export-EvergreenManifest fail tests" {
    Context "Validate Export-EvergreenManifest fails gracefully" {
        It "Should Throw with invalid app" {
            { Export-EvergreenManifest -Name "NonExistentApplication" -InformationAction "SilentlyContinue" -WarningAction "SilentlyContinue" } | Should -Throw
        }

        It "Should throw a FileNotFoundException with invalid app" {
            { Export-EvergreenManifest -Name "NonExistentApplication" -InformationAction "SilentlyContinue" -WarningAction "SilentlyContinue" } | `
                Should -Throw -ExceptionType ([System.IO.FileNotFoundException])
        }

        It "Should throw with an empty name" {
            { Export-EvergreenManifest -Name "" } | Should -Throw
        }

        It "Should throw with a null name" {
            { Export-EvergreenManifest -Name $null } | Should -Throw
        }
    }

    Context "Validate Export-EvergreenManifest preserves the original error for a corrupt manifest" {
        BeforeAll {
            # Create a corrupt manifest in the apps cache
            $CorruptManifest = Join-Path -Path (Join-Path -Path (Get-EvergreenAppsPath) -ChildPath "Manifests") -ChildPath "ZZZCorruptManifestTest.json"
            Set-Content -Path $CorruptManifest -Value "{ this is not valid json" -Force
        }

        AfterAll {
            Remove-Item -Path $CorruptManifest -Force -ErrorAction "SilentlyContinue"
        }

        It "Should throw with a corrupt manifest" {
            { Export-EvergreenManifest -Name "ZZZCorruptManifestTest" -WarningAction "SilentlyContinue" } | Should -Throw
        }

        It "Should not report a corrupt manifest as not found" {
            $ErrorRecord = { Export-EvergreenManifest -Name "ZZZCorruptManifestTest" -WarningAction "SilentlyContinue" } | Should -Throw -PassThru
            $ErrorRecord.Exception | Should -Not -BeOfType ([System.IO.FileNotFoundException])
        }
    }
}
