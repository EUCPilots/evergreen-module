<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Private" -Name "Write-AppNotFoundHelp" {
    BeforeAll {
        Mock Find-EvergreenApp -ModuleName "Evergreen" {
            if ($Name -eq "MicrosoftEdg") {
                [PSCustomObject]@{ Name = "MicrosoftEdge" }
            }
        }
    }

    Context "Validate Write-AppNotFoundHelp basic functionality" {
        It "Should not throw when similar applications exist" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-AppNotFoundHelp -Name "MicrosoftEdg" -InformationAction "SilentlyContinue" -WarningAction "SilentlyContinue" } | Should -Not -Throw
            }
        }

        It "Should not throw when no applications match" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-AppNotFoundHelp -Name "ZZZNoSuchApplication" -InformationAction "SilentlyContinue" -WarningAction "SilentlyContinue" } | Should -Not -Throw
            }
        }

        It "Should throw with an empty name" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-AppNotFoundHelp -Name "" } | Should -Throw
            }
        }

        It "Should throw with a null name" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-AppNotFoundHelp -Name $null } | Should -Throw
            }
        }
    }

    Context "Validate Write-AppNotFoundHelp output" {
        It "Should warn to run Update-Evergreen" {
            InModuleScope -ModuleName "Evergreen" {
                $Warnings = @()
                Write-AppNotFoundHelp -Name "ZZZNoSuchApplication" -InformationAction "SilentlyContinue" -WarningVariable "Warnings" -WarningAction "SilentlyContinue"
                $Warnings -join " " | Should -Match "Update-Evergreen"
            }
        }

        It "Should list similar applications when matches exist" {
            InModuleScope -ModuleName "Evergreen" {
                $Records = @()
                Write-AppNotFoundHelp -Name "MicrosoftEdg" -InformationVariable "Records" -InformationAction "SilentlyContinue" -WarningAction "SilentlyContinue"
                ($Records | ForEach-Object { $_.MessageData.ToString() }) -join "`n" | Should -Match "MicrosoftEdge"
            }
        }

        It "Should state that no applications match when there are no matches" {
            InModuleScope -ModuleName "Evergreen" {
                $Records = @()
                Write-AppNotFoundHelp -Name "ZZZNoSuchApplication" -InformationVariable "Records" -InformationAction "SilentlyContinue" -WarningAction "SilentlyContinue"
                ($Records | ForEach-Object { $_.MessageData.ToString() }) -join "`n" | Should -Match "No applications match"
            }
        }

        It "Should not write to the output stream" {
            InModuleScope -ModuleName "Evergreen" {
                $Output = Write-AppNotFoundHelp -Name "MicrosoftEdg" -InformationAction "SilentlyContinue" -WarningAction "SilentlyContinue"
                $Output | Should -BeNullOrEmpty
            }
        }
    }
}
