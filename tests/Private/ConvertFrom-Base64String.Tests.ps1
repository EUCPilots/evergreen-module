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

        It "Should convert a Base64-encoded SHA-256 digest to lowercase hexadecimal" {
            InModuleScope -ModuleName "Evergreen" {
                $Base64 = "K6fIxnNSlK0jmMNxR5JCiLkc17IqyYBmTZkKCPNH08M="
                $Result = ConvertFrom-Base64String -Base64String $Base64

                $Result | Should -Be "2ba7c8c6735294ad2398c37147924288b91cd7b22ac980664d990a08f347d3c3"
                $Result | Should -Match '^[0-9a-f]{64}$'
            }
        }

        It "Should convert Base64 data to lowercase hexadecimal" {
            InModuleScope -ModuleName "Evergreen" {
                $Base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("Hello, Evergreen!"))
                $Result = ConvertFrom-Base64String -Base64String $Base64

                $Result | Should -Be "48656c6c6f2c2045766572677265656e21"
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
