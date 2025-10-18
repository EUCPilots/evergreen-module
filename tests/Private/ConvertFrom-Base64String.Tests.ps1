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

Describe -Tag "Private" -Name "ConvertFrom-Base64String" {
    Context "Validate ConvertFrom-Base64String basic functionality" {
        BeforeAll {
            # Create test base64 strings
            $script:PlainText = "Hello, Evergreen!"
            $script:Base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($script:PlainText))
        }

        It "Should not throw with valid base64 string" {
            InModuleScope -ModuleName "Evergreen" {
                $Base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("Hello, Evergreen!"))
                { ConvertFrom-Base64String -Base64String $Base64 } | Should -Not -Throw
            }
        }

        # It "Should decode base64 string correctly" {
        #     InModuleScope -ModuleName "Evergreen" {
        #         $PlainText = "Hello, Evergreen!"
        #         $Base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($PlainText))
        #         $Result = ConvertFrom-Base64String -Base64String $Base64
        #         $Result | Should -Be $PlainText
        #     }
        # }

        It "Should return a string" {
            InModuleScope -ModuleName "Evergreen" {
                $Base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("Hello, Evergreen!"))
                $Result = ConvertFrom-Base64String -Base64String $Base64
                $Result | Should -BeOfType [string]
            }
        }
    }

    Context "Validate ConvertFrom-Base64String with invalid input" {
        It "Should throw with null value" {
            { ConvertFrom-Base64String -Base64String $null } | Should -Throw
        }

        It "Should throw with invalid base64 string" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertFrom-Base64String -Base64String "Not-A-Valid-Base64!" -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
