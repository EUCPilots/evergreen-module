<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Name "New-EvergreenPath" {
    Context "Ensure New-EvergreenPath works as expected" {
        It "Does not throw when creating a directory" {
            InModuleScope -ModuleName "Evergreen" {
                $Object = [PSCustomObject] @{
                    "Product"      = "App"
                    "Track"        = "Current"
                    "Channel"      = "Stable"
                    "Release"      = "Prod"
                    "Ring"         = "Prod"
                    "Version"      = "1.0.0"
                    "Language"     = "English"
                    "Architecture" = "x64"
                }
                { New-EvergreenPath -InputObject $Object -Path $([System.IO.Path]::Combine($env:RUNNER_TEMP, "test")) } | Should -Not -Throw
            }
        }

        It "Returns a string when creating a directory" {
            InModuleScope -ModuleName "Evergreen" {
                $Object = [PSCustomObject] @{
                    "Product"      = "App"
                    "Track"        = "Current"
                    "Channel"      = "Stable"
                    "Release"      = "Prod"
                    "Ring"         = "Prod"
                    "Version"      = "1.0.0"
                    "Language"     = "English"
                    "Architecture" = "x64"
                }
                (New-EvergreenPath -InputObject $Object -Path $([System.IO.Path]::Combine($env:RUNNER_TEMP, "test"))) | Should -BeOfType [System.String]
            }
        }
    }
}
