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
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message "Test message" -InformationAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "Should not throw with MessageType parameter" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message "Test message" -MessageType "Pass" } | Should -Not -Throw
            }
        }

        It "Should handle Pass message type" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message "Test passed" -MessageType "Pass" } | Should -Not -Throw
            }
        }

        It "Should handle Fail message type" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message "Test failed" -MessageType "Fail" } | Should -Not -Throw
            }
        }

        It "Should handle Warning message type" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message "Test warning" -MessageType "Warning" } | Should -Not -Throw
            }
        }

        # It "Should handle Error message type" {
        #     InModuleScope -ModuleName "Evergreen" {
        #         { Write-Message -Message "Test error" -MessageType "Error" } | Should -Not -Throw
        #     }
        # }

        It "Should handle Info message type (default)" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message "Test info" -MessageType "Information" -InformationAction SilentlyContinue } | Should -Not -Throw
            }
        }
    }

    Context "Validate information stream output" {
        It "Should write unpadded message data and the Evergreen tag" {
            InModuleScope -ModuleName "Evergreen" {
                $records = @()
                Write-Message -Message "Test message" -InformationVariable records -InformationAction SilentlyContinue

                $records.Count | Should -Be 1
                $records[0].MessageData.Message | Should -Be "[i] Test message"
                $records[0].Tags | Should -Contain "Evergreen"
            }
        }

        It "Should continue writing by default when InformationPreference suppresses information" {
            InModuleScope -ModuleName "Evergreen" {
                Mock -CommandName Write-Information {}
                $InformationPreference = "SilentlyContinue"
                Write-Message -Message "Test message"

                Should -Invoke -CommandName Write-Information -Exactly 1 -ParameterFilter {
                    $InformationAction -eq "Continue"
                }
            }
        }

        It "Should allow the caller to suppress information output" {
            InModuleScope -ModuleName "Evergreen" {
                Mock -CommandName Write-Information {}
                Write-Message -Message "Test message" -InformationAction SilentlyContinue

                Should -Invoke -CommandName Write-Information -Exactly 1 -ParameterFilter {
                    $InformationAction -eq "SilentlyContinue"
                }
            }
        }
    }

    Context "Validate Write-Message with empty or null input" {
        It "Should handle empty message string" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message "" -InformationAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "Should throw with null message" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-Message -Message $null -InformationAction SilentlyContinue } | Should -Throw
            }
        }
    }
}
