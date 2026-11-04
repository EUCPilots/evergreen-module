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

        It "Should return PSCustomObject output" {
            Find-EvergreenApp -Name "MicrosoftEdge" | ForEach-Object {
                $_ | Should -BeOfType "PSCustomObject"
            }
        }

        It "Should only return applications matching the -Name value" {
            Find-EvergreenApp -Name "MicrosoftEdge" | ForEach-Object {
                $_.Name | Should -Match "MicrosoftEdge"
            }
        }

        It "Should match case-insensitively" {
            ($null -ne (Find-EvergreenApp -Name "microsoftedge")) | Should -BeTrue
        }

        It "Should work via the 'fea' alias" {
            { fea -Name "MicrosoftEdge" } | Should -Not -Throw
        }

        It "Should work via the 'ApplicationName' parameter alias" {
            { Find-EvergreenApp -ApplicationName "MicrosoftEdge" } | Should -Not -Throw
        }
    }

    Context "Validate Find-EvergreenApp supports pipeline input" {
        It "Should return results for every value passed on the pipeline" {
            $Output = "MicrosoftEdge", "MicrosoftTeams" | Find-EvergreenApp
            $Output.Name | Should -Contain "MicrosoftEdge"
            $Output.Name | Should -Contain "MicrosoftTeams"
        }
    }

    Context "Validate Find-EvergreenApp handles special characters in -Name" {
        It "Should not throw a regex parse error for input with regex metacharacters" {
            { Find-EvergreenApp -Name "Microsoft(" -WarningAction "SilentlyContinue" } |
                Should -Throw -ErrorId "ApplicationNotFound,Find-EvergreenApp"
        }

        It "Should treat '.' as a literal character, not a regex wildcard" {
            { Find-EvergreenApp -Name "Microsoft...." -WarningAction "SilentlyContinue" } |
                Should -Throw -ErrorId "ApplicationNotFound,Find-EvergreenApp"
        }

        It "Should match against the manifest base name, not the .json extension" {
            { Find-EvergreenApp -Name "json" -WarningAction "SilentlyContinue" } |
                Should -Throw -ErrorId "ApplicationNotFound,Find-EvergreenApp"
        }
    }

    Context "Validate Find-EvergreenApp fails gracefully" {
        It "Should Throw with invalid app" {
            { Find-EvergreenApp -Name "NonExistentApplication" -WarningAction "SilentlyContinue" } | Should -Throw
        }

        It "Should throw a typed ItemNotFoundException with invalid app" {
            { Find-EvergreenApp -Name "NonExistentApplication" -WarningAction "SilentlyContinue" } |
                Should -Throw -ErrorId "ApplicationNotFound,Find-EvergreenApp" -ExceptionType ([System.Management.Automation.ItemNotFoundException])
        }

        It "Should write warnings with invalid app" {
            try {
                Find-EvergreenApp -Name "NonExistentApplication" -WarningAction "SilentlyContinue" -WarningVariable "Warnings"
            }
            catch {
                # Expected - the function throws after writing warnings
            }
            ($Warnings | Measure-Object).Count | Should -BeGreaterThan 0
        }

        It "Should throw with an empty -Name value" {
            { Find-EvergreenApp -Name "" } | Should -Throw
        }
    }
}
