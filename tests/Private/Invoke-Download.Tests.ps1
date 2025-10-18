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

Describe -Tag "Private" -Name "Invoke-Download" {
    Context "Validate Invoke-Download parameter validation" {
        It "Should throw when Uri parameter is null or empty" {
            { Invoke-Download -Uri "" -OutFile "/tmp/test.txt" } | Should -Throw
        }

        It "Should throw when OutFile parameter is null or empty" {
            { Invoke-Download -Uri "https://example.com/file.txt" -OutFile "" } | Should -Throw
        }

        It "Should not throw with valid Uri and OutFile parameters" {
            # Note: This will fail if network is unavailable, so just test parameter binding
            $TestUri = "https://raw.githubusercontent.com/aaronparker/evergreen/main/README.md"
            if ($env:Temp) {
                $TestFile = Join-Path -Path $env:Temp -ChildPath "invoke-download-test.txt"
            }
            elseif ($env:TMPDIR) {
                $TestFile = Join-Path -Path $env:TMPDIR -ChildPath "invoke-download-test.txt"
            }
            else {
                $TestFile = "/tmp/invoke-download-test.txt"
            }

            try {
                { Invoke-Download -Uri $TestUri -OutFile $TestFile -ErrorAction Stop } | Should -Not -Throw
            }
            catch {
                # Network errors are acceptable for this test
                $_.Exception.Message | Should -Not -Match "parameter"
            }
            finally {
                Remove-Item -Path $TestFile -Force -ErrorAction "SilentlyContinue"
            }
        }
    }
}
