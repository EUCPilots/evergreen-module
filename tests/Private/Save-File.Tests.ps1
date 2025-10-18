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

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Save-File" {
        Context "Ensure Save-File works as expected" {
            It "Returns a string if the file is downloaded" {
                $Uri = "https://raw.githubusercontent.com/aaronparker/evergreen/main/Evergreen/Evergreen.json"
                (Save-File -Uri $Uri) | Should -BeOfType [System.IO.FileInfo]
            }

            It "Should throw an error with an invalid URL" {
                { Save-File -Uri "https://nonsense.git" } | Should -Throw
            }
        }
    }
}
