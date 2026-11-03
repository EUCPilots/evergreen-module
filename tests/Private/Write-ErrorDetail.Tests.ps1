<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Private" -Name "Write-ErrorDetail" {
    Context "Validate Write-ErrorDetail basic functionality" {
        It "Should not throw with an ErrorRecord" {
            InModuleScope -ModuleName "Evergreen" {
                try { throw "Test error" } catch { $Record = $_ }
                { Write-ErrorDetail -ErrorRecord $Record -WarningAction "SilentlyContinue" } | Should -Not -Throw
            }
        }

        It "Should throw with a null ErrorRecord" {
            InModuleScope -ModuleName "Evergreen" {
                { Write-ErrorDetail -ErrorRecord $null } | Should -Throw
            }
        }

        It "Should accept an ErrorRecord from the pipeline" {
            InModuleScope -ModuleName "Evergreen" {
                try { throw "Test error" } catch { $Record = $_ }
                { $Record | Write-ErrorDetail -WarningAction "SilentlyContinue" } | Should -Not -Throw
            }
        }
    }

    Context "Validate warning stream output" {
        It "Should write the exception type and message to the warning stream" {
            InModuleScope -ModuleName "Evergreen" {
                try { throw [System.IO.FileNotFoundException]::New("Test error message") } catch { $Record = $_ }
                Write-ErrorDetail -ErrorRecord $Record -WarningVariable Warnings -WarningAction "SilentlyContinue"
                $Warnings -join "`n" | Should -Match "System\.IO\.FileNotFoundException"
                $Warnings -join "`n" | Should -Match "Test error message"
            }
        }

        It "Should write the function name and line number of the error source" {
            InModuleScope -ModuleName "Evergreen" {
                function Test-ErrorDetailSource {
                    throw "Error from a nested function"
                }
                try { Test-ErrorDetailSource } catch { $Record = $_ }
                Write-ErrorDetail -ErrorRecord $Record -WarningVariable Warnings -WarningAction "SilentlyContinue"
                $Warnings -join "`n" | Should -Match "Test-ErrorDetailSource"
                $Warnings -join "`n" | Should -Match "at line \d+"
            }
        }

        It "Should write the script stack trace" {
            InModuleScope -ModuleName "Evergreen" {
                try { throw "Test error" } catch { $Record = $_ }
                Write-ErrorDetail -ErrorRecord $Record -WarningVariable Warnings -WarningAction "SilentlyContinue"
                $Warnings -join "`n" | Should -Match "Stack trace:"
            }
        }

        It "Should truncate the stack trace after the function passed to LastFrame" {
            InModuleScope -ModuleName "Evergreen" {
                function Test-ErrorDetailInner {
                    throw "Error from a nested function"
                }
                function Test-ErrorDetailOuter {
                    Test-ErrorDetailInner
                }
                try { Test-ErrorDetailOuter } catch { $Record = $_ }
                Write-ErrorDetail -ErrorRecord $Record -LastFrame "Test-ErrorDetailOuter" -WarningVariable Warnings -WarningAction "SilentlyContinue"
                $Warnings -join "`n" | Should -Match "at Test-ErrorDetailInner"
                $Warnings -join "`n" | Should -Match "at Test-ErrorDetailOuter"
                $Warnings -join "`n" | Should -Not -Match "at Invoke-Pester"
            }
        }
    }
}
