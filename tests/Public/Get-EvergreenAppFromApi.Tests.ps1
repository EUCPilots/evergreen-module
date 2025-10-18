<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
    $Uri = "https://evergreen-api.stealthpuppy.com/apps"
    $Applications = (Invoke-RestMethod -Uri $Uri -UseBasicParsing -UserAgent "Evergreen/1000.999") | Select-Object -ExpandProperty "Name" | Sort-Object
}

Describe -Tag "Get" -Name "Get-EvergreenAppFromApi works with supported application: <application>" -ForEach $Applications {
    BeforeAll {
        # Renaming the automatic $_ variable to $application to make it easier to work with
        $application = $_
        $Output = Get-EvergreenAppFromApi -Name $application

        # RegEx
        $MatchUrl = "(\s*\[+?\s*(\!?)\s*([a-z]*)\s*\|?\s*([a-z0-9\.\-_]*)\s*\]+?)?\s*([^\s]+)\s*"
        $MatchVersions = "(\d+(\.\d+){1,4}).*|(\d+)|^[0-9]{4}$|insider|Latest|Unknown|Preview|Any|jdk*|RateLimited"
    }

    Context "Output from <application> should return something" {
        It "Output from <application> should not be null" {
            $Output | Should -Not -BeNullOrEmpty
        }

        It "Output from <application> should return the expected output type" {
            $Output | Should -BeOfType "PSCustomObject"
        }

        It "Get-EvergreenAppFromApi -Name <application> should return a count of 1 or more" {
            ($Output | Measure-Object).Count | Should -BeGreaterThan 0
        }
    }

    Context "Validate Get-EvergreenAppFromApi works with <application>." -ForEach $Output {
        BeforeAll {
            $Item = $_
        }

        # Test that the output has a Version property and that property is a string
        It "Output for <application> should have a Version property that is a string" {
            $Item.Version | Should -BeOfType [System.String]
        }

        # Test that output with Version property is valid
        It "Output for <application> should have a valid version number" {
            $Item.Version | Should -Match $MatchVersions
        }

        # Test that the output has a URI property and that property is a string
        It "Output for <application> should have a URI property that is a string" {
            $Item.URI | Should -BeOfType [System.String]
        }
    }
}

Describe -Tag "Get" -Name "Get-EvergreenAppFromApi fail tests" {
    Context "Validate 'Get-EvergreenAppFromApi fails gracefully" {
        It "Should Throw with invalid app" {
            { Get-EvergreenAppFromApi -Name "NonExistentApplication" } | Should -Throw
        }
    }
}
