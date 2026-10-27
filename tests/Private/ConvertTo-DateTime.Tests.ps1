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

Describe -Name "ConvertTo-DateTime" {
    Context "Convert a date/time string to a formatted date string" {
        It "Formats the parsed date as yyyy-MM-dd" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = ConvertTo-DateTime -DateTime "2000/14/2 16:35:42" -Pattern "yyyy/d/M HH:mm:ss"

                $Result | Should -BeOfType [System.String]
                $Result | Should -Be "2000-02-14"
            }
        }

        It "Parses the specified US format independently of local culture" {
            InModuleScope -ModuleName "Evergreen" {
                $OriginalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
                $OriginalUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
                $LocalCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-AU")

                try {
                    [System.Threading.Thread]::CurrentThread.CurrentCulture = $LocalCulture
                    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $LocalCulture
                    $Result = ConvertTo-DateTime -DateTime "12/31/2024 11:45:32 PM" -Pattern "MM/dd/yyyy hh:mm:ss tt"

                    $Result | Should -BeOfType [System.String]
                    $Result | Should -Be "2024-12-31"
                }
                finally {
                    [System.Threading.Thread]::CurrentThread.CurrentCulture = $OriginalCulture
                    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $OriginalUICulture
                }
            }
        }

        It "Throws when automatic parsing and the fallback pattern both fail" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertTo-DateTime -DateTime "not a date" -Pattern "yyyy-MM-dd" } |
                    Should -Throw "*Failed to parse date*"
                { ConvertTo-DateTime -DateTime "2024|31|12" -Pattern "yyyy-MM-dd" } |
                    Should -Throw "*using pattern*yyyy-MM-dd*"
            }
        }

        It "Automatically parses dates by default" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = ConvertTo-DateTime -DateTime "12/31/2024"

                $Result | Should -BeOfType [System.String]
                $Result | Should -Be "2024-12-31"
                ConvertTo-DateTime -DateTime "December 31, 2024 11:45 PM" |
                    Should -Be "2024-12-31"
            }
        }
    }

    Context "Default automatic parsing" {
        It "Parses the known vendor format in <InputDate>" -TestCases @(
            @{ InputDate = "12/31/2024"; Expected = [System.DateTime]::new(2024, 12, 31) }
            @{ InputDate = "12/31/2024 23:45:32"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "12/31/2024 11:45 PM"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 0) }
            @{ InputDate = "12/31/2024 11:45:32 PM"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "12-31-2024"; Expected = [System.DateTime]::new(2024, 12, 31) }
            @{ InputDate = "2024-12-31 23:45:32"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "Tue, 31 Dec 2024 23:45:32 GMT"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32, [System.DateTimeKind]::Utc).ToLocalTime() }
            @{ InputDate = "Tue, 31 Dec 2024 23:45:32 +02:00"; Expected = [System.DateTime]::new(2024, 12, 31, 21, 45, 32, [System.DateTimeKind]::Utc).ToLocalTime() }
            @{ InputDate = "31/12/2024"; Expected = [System.DateTime]::new(2024, 12, 31) }
            @{ InputDate = "31/12/2024 11:45 PM"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 0) }
            @{ InputDate = "31/12/2024 11:45:32 PM"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "31/12/2024 23:45:32"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "2024-12-31"; Expected = [System.DateTime]::new(2024, 12, 31) }
            @{ InputDate = "2024-12-31T23:45:32"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "2024-12-31T23:45:32.1234567"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32).AddTicks(1234567) }
            @{ InputDate = "2024-12-31T23:45:32.1234567Z"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32, [System.DateTimeKind]::Utc).AddTicks(1234567).ToLocalTime() }
        ) {
            param ($InputDate, $Expected)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ InputDate = $InputDate; Expected = $Expected } {
                $Result = ConvertTo-DateTime -DateTime $InputDate

                $Result | Should -BeOfType [System.String]
                $Result | Should -Be $Expected.ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
            }
        }

        It "Parses common US formats and ambiguous dates independently of local culture" {
            InModuleScope -ModuleName "Evergreen" {
                $OriginalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
                $OriginalUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
                try {
                    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-AU")
                    [System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo("de-DE")

                    foreach ($InputDate in @("December 31, 2024 11:45 PM", "12/31/2024 23:45:00", "2024-12-31T23:45:00")) {
                        $Result = ConvertTo-DateTime -DateTime $InputDate

                        $Result | Should -BeOfType [System.String]
                        $Result | Should -Be "2024-12-31"
                    }
                    $AmbiguousResult = ConvertTo-DateTime -DateTime "04/05/2024"
                    $AmbiguousResult | Should -Be "2024-04-05"
                    foreach ($InputDate in @("04/05/2024 11:45 PM", "04/05/2024 11:45:00 PM", "04/05/2024 23:45:00")) {
                        ConvertTo-DateTime -DateTime $InputDate |
                            Should -Be "2024-04-05"
                    }
                }
                finally {
                    [System.Threading.Thread]::CurrentThread.CurrentCulture = $OriginalCulture
                    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $OriginalUICulture
                }
            }
        }

        It "Throws on invalid input instead of returning a default date" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertTo-DateTime -DateTime "not a date" -AutoDetect } |
                    Should -Throw "*Failed to parse date*"
            }
        }

        It "Prefers automatic parsing over an explicit pattern" {
            InModuleScope -ModuleName "Evergreen" {
                ConvertTo-DateTime -DateTime "04/05/2024" -Pattern "dd/MM/yyyy" |
                    Should -Be "2024-04-05"
            }
        }

        It "Falls back to an explicit pattern when automatic parsing fails" {
            InModuleScope -ModuleName "Evergreen" {
                ConvertTo-DateTime -DateTime "2024|31|12" -Pattern "yyyy|dd|MM" -AutoDetect |
                    Should -Be "2024-12-31"
            }
        }

        It "Allows automatic parsing to be explicitly disabled" {
            InModuleScope -ModuleName "Evergreen" {
                ConvertTo-DateTime -DateTime "04/05/2024" -Pattern "dd/MM/yyyy" -AutoDetect:$false |
                    Should -Be "2024-05-04"
                { ConvertTo-DateTime -DateTime "December 31, 2024" -AutoDetect:$false } |
                    Should -Throw "*Failed to parse date*"
            }
        }
    }
}
