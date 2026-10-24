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
    $HadEvergreenAppsPath = Test-Path -Path Env:EVERGREEN_APPS_PATH
    $OriginalEvergreenAppsPath = $env:EVERGREEN_APPS_PATH
    $env:EVERGREEN_APPS_PATH = $TestDrive

    $ManifestPath = Join-Path -Path $TestDrive -ChildPath "Manifests"
    New-Item -ItemType Directory -Path $ManifestPath -Force | Out-Null
    Set-Content -LiteralPath (Join-Path -Path $ManifestPath -ChildPath "MicrosoftEdge.json") -Value '{"Name":"Microsoft Edge"}' -Encoding UTF8
}

AfterAll {
    if ($HadEvergreenAppsPath) {
        $env:EVERGREEN_APPS_PATH = $OriginalEvergreenAppsPath
    }
    else {
        Remove-Item -Path Env:EVERGREEN_APPS_PATH -ErrorAction SilentlyContinue
    }
}

Describe -Name "Get-FunctionResource" {
    Context "Ensure function resources are returned" {
        It "Given a valid app it returns valid data" {
            InModuleScope -ModuleName "Evergreen" {
                Get-FunctionResource -AppName "MicrosoftEdge" | Should -BeOfType [System.Collections.IDictionary]
            }
        }

        It "Given an invalid application, it throws" {
            InModuleScope -ModuleName "Evergreen" {
                { Get-FunctionResource -AppName "DoesNotExist" } | Should -Throw
            }
        }

        It "Rejects empty, path-like, and wildcard application names" {
            InModuleScope -ModuleName "Evergreen" {
                foreach ($AppName in @("", " ", "../MicrosoftEdge", "..\MicrosoftEdge", "Microsoft*")) {
                    { Get-FunctionResource -AppName $AppName } | Should -Throw
                }
            }
        }

        It "Throws when the manifest contains invalid JSON" {
            Set-Content -LiteralPath (Join-Path -Path $ManifestPath -ChildPath "InvalidJson.json") -Value '{"Name":' -Encoding UTF8
            InModuleScope -ModuleName "Evergreen" {
                { Get-FunctionResource -AppName "InvalidJson" } | Should -Throw
            }
        }

        It "Throws when the JSON root is not an object" {
            foreach ($Json in @("null", "[]", '"text"')) {
                Set-Content -LiteralPath (Join-Path -Path $ManifestPath -ChildPath "InvalidRoot.json") -Value $Json -Encoding UTF8
                InModuleScope -ModuleName "Evergreen" {
                    { Get-FunctionResource -AppName "InvalidRoot" } | Should -Throw
                }
            }
        }

        It "Reads UTF-8 manifest content correctly" {
            $UnicodeValue = "M" + [char]0x00FC + "nchen"
            $Content = "{`"Publisher`":`"$UnicodeValue`"}"
            [System.IO.File]::WriteAllText(
                (Join-Path -Path $ManifestPath -ChildPath "Unicode.json"),
                $Content,
                [System.Text.UTF8Encoding]::new($false)
            )

            InModuleScope -ModuleName "Evergreen" -Parameters @{ ExpectedValue = $UnicodeValue } {
                param ($ExpectedValue)
                (Get-FunctionResource -AppName "Unicode").Publisher | Should -Be $ExpectedValue
            }
        }
    }
}
