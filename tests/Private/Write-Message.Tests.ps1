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

Describe -Tag "Private" -Name "Write-Message" {
    Context "Validate Write-Message basic functionality" {
        It "Should not throw with Message parameter" {
            { Write-Message -Message "Test message" } | Should -Not -Throw
        }

        It "Should not throw with MessageType parameter" {
            { Write-Message -Message "Test message" -MessageType "Pass" } | Should -Not -Throw
        }

        It "Should handle Pass message type" {
            { Write-Message -Message "Test passed" -MessageType "Pass" } | Should -Not -Throw
        }

        It "Should handle Fail message type" {
            { Write-Message -Message "Test failed" -MessageType "Fail" } | Should -Not -Throw
        }

        It "Should handle Warning message type" {
            { Write-Message -Message "Test warning" -MessageType "Warning" } | Should -Not -Throw
        }

        It "Should handle Error message type" {
            { Write-Message -Message "Test error" -MessageType "Error" } | Should -Not -Throw
        }

        It "Should handle Info message type (default)" {
            { Write-Message -Message "Test info" -MessageType "Info" } | Should -Not -Throw
        }
    }

    Context "Validate Write-Message with empty or null input" {
        It "Should handle empty message string" {
            { Write-Message -Message "" } | Should -Not -Throw
        }

        It "Should throw with null message" {
            { Write-Message -Message $null } | Should -Throw
        }
    }
}
