<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Name "Resolve-DnsNameWrapper" {
    Context "Windows resolver output" {
        It "Returns data from address records" -Skip:($PSVersionTable.Platform -ne "Win32NT" -and $PSVersionTable.PSEdition -ne "Desktop") {
            InModuleScope -ModuleName "Evergreen" {
                Mock Import-Module {}
                Mock Resolve-DnsName {
                    [PSCustomObject]@{ Type = "A"; IPAddress = "192.0.2.10" }
                    [PSCustomObject]@{ Type = "AAAA"; IPAddress = "2001:db8::10" }
                }

                $Result = Resolve-DnsNameWrapper -Name "example.com" -Type "a"
                $Result | Should -Be "192.0.2.10"
                Should -Invoke Resolve-DnsName -Times 1 -ParameterFilter { $Type -eq "A" -and $ErrorAction -eq "Stop" }
            }
        }

        It "Returns strings from TXT records" -Skip:($PSVersionTable.Platform -ne "Win32NT" -and $PSVersionTable.PSEdition -ne "Desktop") {
            InModuleScope -ModuleName "Evergreen" {
                Mock Import-Module {}
                Mock Resolve-DnsName {
                    [PSCustomObject]@{ Type = "TXT"; Strings = @("first", "second") }
                }

                $Result = Resolve-DnsNameWrapper -Name "example.com" -Type "TXT"
                $Result | Should -Be @("first", "second")
            }
        }

        It "Preserves the underlying DNS query error" -Skip:($PSVersionTable.Platform -ne "Win32NT" -and $PSVersionTable.PSEdition -ne "Desktop") {
            InModuleScope -ModuleName "Evergreen" {
                Mock Import-Module {}
                Mock Resolve-DnsName { throw "DNS query failed" }

                { Resolve-DnsNameWrapper -Name "example.com" } | Should -Throw "*DNS query failed*"
            }
        }

        It "Reports when the resolver returns no matching records" -Skip:($PSVersionTable.Platform -ne "Win32NT" -and $PSVersionTable.PSEdition -ne "Desktop") {
            InModuleScope -ModuleName "Evergreen" {
                Mock Import-Module {}
                Mock Resolve-DnsName { }

                { Resolve-DnsNameWrapper -Name "example.com" } | Should -Throw "*returned no A records*"
            }
        }
    }

    It "Rejects whitespace-only names and invalid record-type tokens" {
        InModuleScope -ModuleName "Evergreen" {
            { Resolve-DnsNameWrapper -Name " " } | Should -Throw
            { Resolve-DnsNameWrapper -Name "example.com" -Type "A TXT" } | Should -Throw
        }
    }
}
