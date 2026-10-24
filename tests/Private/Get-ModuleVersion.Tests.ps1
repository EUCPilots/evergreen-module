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

Describe -Tag "Private" -Name "Get-ModuleVersion" {
    Context "Validate Get-ModuleVersion basic functionality" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-ModuleVersion } | Should -Not -Throw
            }
        }

        It "Should return a System.Version for the module containing the function" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = Get-ModuleVersion
                $Result | Should -BeOfType [System.Version]
                $Result | Should -Be $ExecutionContext.SessionState.Module.Version
            }
        }

        It "Should not select another loaded Evergreen module version" {
            InModuleScope -ModuleName "Evergreen" {
                Mock Get-Module {
                    [pscustomobject]@{
                        Version = [System.Version]"1.2.3"
                    }
                }

                $Result = Get-ModuleVersion
                $Result | Should -Be $ExecutionContext.SessionState.Module.Version
            }
        }

        It "Should return the manifest version when called outside a module" {
            $functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Evergreen\Private\Get-ModuleVersion.ps1"
            $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Evergreen\Evergreen.psd1"
            $expectedVersion = [System.Version](Import-PowerShellDataFile -Path $manifestPath).ModuleVersion
            $result = & {
                . $functionPath
                Get-ModuleVersion
            }

            $result | Should -BeOfType [System.Version]
            $result | Should -Be $expectedVersion
        }
    }
}
