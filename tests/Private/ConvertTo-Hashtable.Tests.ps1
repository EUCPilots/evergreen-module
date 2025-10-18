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

        It "Returns Null if sent Null" {
            InModuleScope -ModuleName "Evergreen" {
                ConvertTo-Hashtable | Should -BeNullOrEmpty
            }
        }
    }
}
