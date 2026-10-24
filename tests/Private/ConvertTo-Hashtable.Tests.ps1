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
                    EmptyArray = @()
                }

                $object = ConvertTo-Hashtable -InputObject $inputObject
                $object.Child | Should -BeOfType "Hashtable"
                $object.Child.Name | Should -Be "Nested"
                $object.Items | Should -HaveCount 2
                $object.Items[0] | Should -BeOfType "Hashtable"
                $object.Items[1].Name | Should -Be "Second"
                ($object["EmptyArray"] -is [System.Object[]]) | Should -BeTrue
                $object["EmptyArray"].Count | Should -Be 0
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

                $emptyObject = ConvertTo-Hashtable -InputObject ([System.Object[]]@())
                ($emptyObject -is [System.Object[]]) | Should -BeTrue
                $emptyObject.Count | Should -Be 0
            }
        }

        It "Preserves single-item and nested arrays" {
            InModuleScope -ModuleName "Evergreen" {
                $inputObject = [PSCustomObject]@{
                    Single = @([PSCustomObject]@{ Name = "Only" })
                    Nested = @(
                        ,@()
                        ,@([PSCustomObject]@{ Name = "Nested" })
                    )
                }

                $object = ConvertTo-Hashtable -InputObject $inputObject

                ($object.Single -is [System.Object[]]) | Should -BeTrue
                $object.Single.Count | Should -Be 1
                $object.Single[0] | Should -BeOfType "Hashtable"
                $object.Single[0].Name | Should -Be "Only"
                $object.Nested.Count | Should -Be 2
                ($object.Nested[0] -is [System.Object[]]) | Should -BeTrue
                $object.Nested[0].Count | Should -Be 0
                ($object.Nested[1] -is [System.Object[]]) | Should -BeTrue
                $object.Nested[1].Count | Should -Be 1
                $object.Nested[1][0].Name | Should -Be "Nested"
            }
        }

        It "Returns Null if sent Null" {
            InModuleScope -ModuleName "Evergreen" {
                ConvertTo-Hashtable | Should -BeNullOrEmpty
            }
        }
    }
}
