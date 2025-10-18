<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs to log host.")]
param ()

BeforeDiscovery {
    $MicrosoftEdge = Find-EvergreenApp -Name "MicrosoftEdge"
}

BeforeAll {
}

Describe -Tag "Find" -Name "Find-EvergreenApp MicrosoftEdge" -ForEach $MicrosoftEdge {
    BeforeEach {
        $Application = $_
    }

    Context "Validate apps returned by a Find-EvergreenApp query" {
        It "Has a Name property" {
            $Application.Name | Should -Not -BeNullOrEmpty
        }

        It "Has an Application property" {
            $Application.Application | Should -Not -BeNullOrEmpty
        }

        It "Has a Link property" {
            $Application.Link | Should -Not -BeNullOrEmpty
        }
    }
}

Describe -Tag "Find" -Name "Find-EvergreenApp" {
    Context "Validate Find-EvergreenApp works" {

        # Test that the function returns OK
        It "Should not Throw" {
            { Find-EvergreenApp } | Should -Not -Throw
        }

        # Test that the function returns something
        It "Should returns an object" {
            $Applications = Find-EvergreenApp
            ($Applications | Measure-Object).Count | Should -BeGreaterThan 0
        }
    }

    Context "Validate Find-EvergreenApp fails gracefully" {
        It "Should Throw with invalid app" {
            { Find-EvergreenApp -Name "NonExistentApplication" } | Should -Throw
        }
    }
}
