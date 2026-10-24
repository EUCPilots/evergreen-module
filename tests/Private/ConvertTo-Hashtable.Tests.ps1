<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Name "ConvertTo-Hashtable" {
    Context "Test conversion to hashtable" {
        It "Converts a PSObject into a hashtable" {
            InModuleScope -ModuleName "Evergreen" {
                $ps = [PSCustomObject]@{ Name = "Name1"; Address = "Address1" }
                $object = $ps | ConvertTo-Hashtable
                $object | Should -BeOfType "Hashtable"
            }
        }

        It "Converts nested objects and collections" {
            InModuleScope -ModuleName "Evergreen" {
                $inputObject = [PSCustomObject]@{
                    Child = [PSCustomObject]@{ Name = "Nested" }
                    Items = @(
                        [PSCustomObject]@{ Name = "First" }
                        [PSCustomObject]@{ Name = "Second" }
                    )
                    Empty = @()
                }

                $object = ConvertTo-Hashtable -InputObject $inputObject
                $object.Child | Should -BeOfType "Hashtable"
                $object.Child.Name | Should -Be "Nested"
                $object.Items | Should -HaveCount 2
                $object.Items[0] | Should -BeOfType "Hashtable"
                $object.Items[1].Name | Should -Be "Second"
                $object.Empty | Should -BeOfType "Object[]"
                $object.Empty | Should -BeNullOrEmpty
            }
        }

        It "Converts a hashtable without treating it as a collection" {
            InModuleScope -ModuleName "Evergreen" {
                $inputObject = @{ Child = [PSCustomObject]@{ Name = "Nested" } }
                $object = ConvertTo-Hashtable -InputObject $inputObject

                $object | Should -BeOfType "Hashtable"
                $object.Child | Should -BeOfType "Hashtable"
                $object.Child.Name | Should -Be "Nested"
            }
        }

        It "Preserves a top-level array when passed as an argument" {
            InModuleScope -ModuleName "Evergreen" {
                $inputObject = @(
                    [PSCustomObject]@{ Name = "First" }
                    [PSCustomObject]@{ Name = "Second" }
                )
                $object = ConvertTo-Hashtable -InputObject $inputObject

                $object | Should -HaveCount 2
                $object[0] | Should -BeOfType "Hashtable"
                $object[1].Name | Should -Be "Second"
            }
        }

        It "Returns Null if sent Null" {
            InModuleScope -ModuleName "Evergreen" {
                ConvertTo-Hashtable | Should -BeNullOrEmpty
            }
        }
    }
}
