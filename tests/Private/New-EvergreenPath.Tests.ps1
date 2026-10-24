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

        It "Requires an input object and a non-empty path" {
            InModuleScope -ModuleName "Evergreen" {
                { New-EvergreenPath -Path $env:RUNNER_TEMP } | Should -Throw
                { New-EvergreenPath -InputObject ([PSCustomObject]@{}) -Path "" } | Should -Throw
                { New-EvergreenPath -InputObject ([PSCustomObject]@{}) -Path "   " } | Should -Throw "*Path cannot contain only whitespace*"
            }
        }

        It "Rejects property values that are not a single path segment" {
            InModuleScope -ModuleName "Evergreen" {
                $Object = [PSCustomObject]@{
                    Product = ".."
                }

                { New-EvergreenPath -InputObject $Object -Path $env:RUNNER_TEMP } | Should -Throw "*Product*not a valid path segment*"
            }
        }

        It "Returns the planned path without creating directories when WhatIf is specified" {
            InModuleScope -ModuleName "Evergreen" {
                $Object = [PSCustomObject]@{
                    Product = "EvergreenWhatIf"
                }
                $BasePath = [System.IO.Path]::Combine($env:RUNNER_TEMP, [System.Guid]::NewGuid().ToString())

                $Result = New-EvergreenPath -InputObject $Object -Path $BasePath -WhatIf

                $Result | Should -Be ([System.IO.Path]::Combine($BasePath, "EvergreenWhatIf"))
                (Test-Path -LiteralPath $BasePath) | Should -BeFalse
            }
        }

        It "Surfaces directory creation failures" {
            InModuleScope -ModuleName "Evergreen" {
                $Object = [PSCustomObject]@{
                    Product = "App"
                }
                Mock -CommandName New-Item -MockWith {
                    throw "Expected creation failure"
                }

                { New-EvergreenPath -InputObject $Object -Path $env:RUNNER_TEMP } | Should -Throw "*Expected creation failure*"
                Should -Invoke New-Item -Times 1 -Exactly
            }
        }
    }
}
