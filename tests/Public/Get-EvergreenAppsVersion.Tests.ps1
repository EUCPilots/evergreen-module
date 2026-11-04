<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe "Get-EvergreenAppsVersion" {
        It "Returns the release version from the configured apps repository" {
            Mock Get-GitHubRepoRelease {
                [PSCustomObject]@{ Version = "26.11.03.146" }
            }

            Get-EvergreenAppsVersion | Should -Be "26.11.03.146"
            Should -Invoke Get-GitHubRepoRelease -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "https://api.github.com/repos/eucpilots/evergreen-apps/releases/latest"
            }
        }

        It "Propagates errors retrieving the release version" {
            Mock Get-GitHubRepoRelease { throw "GitHub unavailable" }

            { Get-EvergreenAppsVersion } | Should -Throw "*GitHub unavailable*"
        }
    }
}
