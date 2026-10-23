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
    Context "Convert a date/time string to a DateTime object" {
        It "Preserves the date and time from the provided format" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = ConvertTo-DateTime -DateTime "2000/14/2 16:35:42" -Pattern "yyyy/d/M HH:mm:ss"

                $Result | Should -BeOfType [System.DateTime]
                $Result | Should -Be ([System.DateTime]::new(2000, 2, 14, 16, 35, 42))
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

                    $Result | Should -BeOfType [System.DateTime]
                    $Result | Should -Be ([System.DateTime]::new(2024, 12, 31, 23, 45, 32))
                    $Result.ToString("d", $LocalCulture) | Should -Be "31/12/2024"
                }
                finally {
                    [System.Threading.Thread]::CurrentThread.CurrentCulture = $OriginalCulture
                    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $OriginalUICulture
                }
            }
        }

        It "Throws when the input does not match the specified pattern" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertTo-DateTime -DateTime "not a date" -Pattern "yyyy-MM-dd" } |
                    Should -Throw "*Failed to parse date*"
                { ConvertTo-DateTime -DateTime "12/31/2024" -Pattern "dd/MM/yyyy" } |
                    Should -Throw "*Failed to parse date*"
            }
        }

        It "Keeps the default pattern unless automatic parsing is requested" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = ConvertTo-DateTime -DateTime "12/31/2024"

                $Result | Should -BeOfType [System.DateTime]
                $Result | Should -Be ([System.DateTime]::new(2024, 12, 31))
                { ConvertTo-DateTime -DateTime "December 31, 2024 11:45 PM" } |
                    Should -Throw "*Failed to parse date*"
            }
        }
    }

    Context "Opt-in automatic parsing" {
        It "Parses the known vendor format in <InputDate>" -TestCases @(
            @{ InputDate = "12/31/2024"; Expected = [System.DateTime]::new(2024, 12, 31) }
            @{ InputDate = "12/31/2024 23:45:32"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "2024-12-31"; Expected = [System.DateTime]::new(2024, 12, 31) }
            @{ InputDate = "2024-12-31T23:45:32"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32) }
            @{ InputDate = "2024-12-31T23:45:32.1234567"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32).AddTicks(1234567) }
            @{ InputDate = "2024-12-31T23:45:32.1234567Z"; Expected = [System.DateTime]::new(2024, 12, 31, 23, 45, 32, [System.DateTimeKind]::Utc).AddTicks(1234567).ToLocalTime() }
        ) {
            param ($InputDate, $Expected)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ InputDate = $InputDate; Expected = $Expected } {
                $Result = ConvertTo-DateTime -DateTime $InputDate -AutoDetect

                $Result | Should -BeOfType [System.DateTime]
                $Result.Ticks | Should -Be $Expected.Ticks
                $Result.Kind | Should -Be $Expected.Kind
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
                        $Result = ConvertTo-DateTime -DateTime $InputDate -AutoDetect

                        $Result | Should -BeOfType [System.DateTime]
                        $Result | Should -Be ([System.DateTime]::new(2024, 12, 31, 23, 45, 0))
                    }
                    $AmbiguousResult = ConvertTo-DateTime -DateTime "04/05/2024" -AutoDetect
                    $AmbiguousResult | Should -Be ([System.DateTime]::new(2024, 4, 5))
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

        It "Does not allow automatic parsing alongside an explicit pattern" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertTo-DateTime -DateTime "12/31/2024" -Pattern "dd/MM/yyyy" -AutoDetect } |
                    Should -Throw
            }
        }
    }
}
