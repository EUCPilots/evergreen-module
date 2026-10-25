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

Describe -Name "ConvertFrom-IniFile" {
    Context "Ensure ConvertFrom-IniFile works as expected" {
        It "Should not throw" {
            InModuleScope -ModuleName "Evergreen" {
                $Ini = Get-Content -Path "$env:GITHUB_WORKSPACE\tests\Test.ini"
                { ConvertFrom-IniFile -InputObject $Ini } | Should -Not -Throw
            }
        }

        It "Returns a single hashtable keyed by section name" {
            InModuleScope -ModuleName "Evergreen" {
                $Ini = Get-Content -Path "$env:GITHUB_WORKSPACE\tests\Test.ini"
                $Result = @(ConvertFrom-IniFile -InputObject $Ini)

                $Result.Count | Should -Be 1
                $Result[0] | Should -BeOfType [Hashtable]
                $Result[0].Count | Should -Be 2
                $Result[0].ContainsKey("") | Should -BeFalse
                $Result[0]["One"]["Abc"] | Should -Be "Xyz"
                $Result[0]["Two"]["Abc"] | Should -Be "Xyz"
                $Result[0].Values.GetType().FullName | Should -Be "System.Collections.Hashtable+ValueCollection"
                foreach ($Section in $Result[0].Values) {
                    $Section | Should -BeOfType [Hashtable]
                }
            }
        }

        It "Parses content piped one line at a time" {
            InModuleScope -ModuleName "Evergreen" {
                $Ini = @(
                    "[Section]"
                    "Key=Value"
                ) | ConvertFrom-IniFile

                $Ini | Should -BeOfType [Hashtable]
                $Ini["Section"]["Key"] | Should -Be "Value"
            }
        }

        It "Stores keys before the first section in the empty section" {
            InModuleScope -ModuleName "Evergreen" {
                $Ini = ConvertFrom-IniFile -InputObject @(
                    "GlobalKey=GlobalValue"
                    "[Section]"
                    "Key=Value"
                )

                $Ini.Count | Should -Be 2
                $Ini[""]["GlobalKey"] | Should -Be "GlobalValue"
                $Ini["Section"]["Key"] | Should -Be "Value"
            }
        }

        It "Preserves every section and value in a multiline string with <Name> line endings" -TestCases @(
            @{ Name = "LF"; NewLine = "`n" }
            @{ Name = "CRLF"; NewLine = "`r`n" }
            @{ Name = "CR"; NewLine = "`r" }
        ) {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ NewLine = $NewLine } {
                param ($NewLine)

                $Content = @(
                    "GlobalKey=GlobalValue"
                    "[First]"
                    "Name=First"
                    "Version=1.0"
                    "URL=https://example.com/download?a=1&b=2"
                    "[Second]"
                    "Name=Second"
                    "Version=2.0"
                    "LastKey=LastValue"
                ) -join $NewLine

                foreach ($UsePipeline in @($false, $true)) {
                    $Ini = if ($UsePipeline) {
                        $Content | ConvertFrom-IniFile
                    }
                    else {
                        ConvertFrom-IniFile -InputObject $Content
                    }

                    $Ini | Should -BeOfType [Hashtable]
                    $Ini.Count | Should -Be 3
                    $GlobalSection = $Ini[""]
                    $FirstSection = $Ini["First"]
                    $SecondSection = $Ini["Second"]
                    $GlobalSection.Count | Should -Be 1
                    $GlobalSection["GlobalKey"] | Should -Be "GlobalValue"
                    $FirstSection.Count | Should -Be 3
                    $FirstSection["Version"] | Should -Be "1.0"
                    $FirstSection["URL"] | Should -Be "https://example.com/download?a=1&b=2"
                    $SecondSection.Count | Should -Be 3
                    $SecondSection["Version"] | Should -Be "2.0"
                    $SecondSection["LastKey"] | Should -Be "LastValue"
                }
            }

        }

        It "Replaces a repeated section as in the original parser" {
            InModuleScope -ModuleName "Evergreen" {
                $Ini = ConvertFrom-IniFile -InputObject @(
                    "[Section]"
                    "; Old comment"
                    "OldKey=OldValue"
                    "[Section]"
                    "; New comment"
                    "NewKey=NewValue"
                )

                $Ini.Count | Should -Be 1
                $Ini["Section"].Count | Should -Be 2
                $Ini["Section"].ContainsKey("OldKey") | Should -BeFalse
                $Ini["Section"]["Comment1"] | Should -Be "; New comment"
                $Ini["Section"]["NewKey"] | Should -Be "NewValue"
            }
        }
    }
}
