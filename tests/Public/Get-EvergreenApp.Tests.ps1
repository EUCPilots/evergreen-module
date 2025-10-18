<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
    # Get the supported applications and sort randomly
    # Exclude applications that have issues when run from GitHub or fail randomly due to the source server
    #$AppsToSkip = "MicrosoftWvdRtcService|MicrosoftWvdRemoteDesktop|MicrosoftWvdMultimediaRedirection|MicrosoftWvdInfraAgent|MicrosoftWvdBootloader|MestrelabMnova|MozillaFirefox|AWSCLI|OBSStudio|ProgressChefInfraClient|MirantisLens|JetBrainsHub|FileZilla|PDFArranger"

    # $AppsToSkip = "MicrosoftWvdRtcService|MicrosoftWvdRemoteDesktop|MicrosoftWvdMultimediaRedirection|MicrosoftWvdInfraAgent|MicrosoftWvdBootloader|FileZilla|PDFArranger|JetBrainsHub"
    # $Applications = Find-EvergreenApp | `
    #     Where-Object { $_.Name -notmatch $AppsToSkip } | `
    #     Sort-Object { Get-Random } | Select-Object -ExpandProperty "Name"

    # Export the list of apps
    $Applications = Find-EvergreenApp | Select-Object -ExpandProperty "Name" | Sort-Object
    $RandomApplications = Get-Random -InputObject $Applications -Count 50
}

Describe -Tag "Get" -Name "Get-EvergreenApp works with supported application: <application>" -ForEach $RandomApplications {
    BeforeAll {
        # Renaming the automatic $_ variable to $application to make it easier to work with
        $application = $_
        $Output = Get-EvergreenApp -Name $application -WarningAction "SilentlyContinue"

        # RegEx
        $MatchUrl = "(\s*\[+?\s*(\!?)\s*([a-z]*)\s*\|?\s*([a-z0-9\.\-_]*)\s*\]+?)?\s*([^\s]+)\s*"
        $MatchVersions = "(\d+(\.\d+){1,4}).*|(\d+)|^[0-9]{4}$|insider|Latest|Unknown|Preview|Any|jdk*|RateLimited"
    }

    Context "Application function <application> should return something" -ForEach $Output {
        BeforeAll {
            $Item = $_
        }

        It "Output from <application> should not be null" {
            $Item | Should -Not -BeNullOrEmpty
        }

        It "Output from <application> should return the expected output type" {
            $Item | Should -BeOfType "PSCustomObject"
        }

        It "Get-EvergreenApp -Name <application> should return a count of 1 or more" {
            ($Item | Measure-Object).Count | Should -BeGreaterThan 0
        }
    }

    Context "Output from application function <application> returns expected properties" -ForEach $Output {
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

Describe -Tag "Get" -Name "Get-EvergreenApp fail tests" {
    Context "Validate 'Get-EvergreenApp fails gracefully" {
        It "Should throw with invalid app" {
            { Get-EvergreenApp -Name "NonExistentApplication" } | Should -Throw
        }

        It "Should throw with an invalid proxy server " {
            { Get-EvergreenApp -Name "MicrosoftEdge" -Proxy "test.local" } | Should -Throw
        }
    }
}

Describe -Tag "Get" -Name "Get-EvergreenApp works with -SkipCertificateCheck" {
    Context "Validate 'Get-EvergreenApp' with -SkipCertificateCheck" {
        It "Should not throw with an app that uses Invoke-EvergreenRestMethod" {
            { Get-EvergreenApp -Name "MicrosoftEdge" } | Should -Not -Throw
        }

        It "Should not throw with an app that uses Invoke-EvergreenWebRequest" {
            { Get-EvergreenApp -Name "BlueJ" } | Should -Not -Throw
        }
    }
}

Describe -Tag "Get" -Name "Application functions with additional parameters" {
    Context "Validate applications that support additional parameters" {
        It "Get-GitHubRelease should throw with an invalid URL" {
            { Get-EvergreenApp -Name "GitHubRelease" -AppParams @{Uri = "https://github.com" } } | Should -Throw
        }

        # It "Should pass parameters to MozillaFirefox" {
        #     { Get-EvergreenApp -Name "MozillaFirefox" -AppParams @{Language = "en-GB"} } | Should -Not -Throw
        # }

        It "Should pass parameters to MozillaThunderbird" {
            { Get-EvergreenApp -Name "MozillaThunderbird" -AppParams @{Language = "en-GB" } } | Should -Not -Throw
        }
    }
}
