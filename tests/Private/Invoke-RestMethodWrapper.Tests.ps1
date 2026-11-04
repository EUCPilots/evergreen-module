<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Invoke-EvergreenRestMethod" {
        Context "Ensure Invoke-EvergreenRestMethod works as expected" {
            It "Allows insecure redirects on Windows PowerShell without an unsupported parameter" {
                Mock Test-PSCore { $false }
                Mock Invoke-RestMethod { "mock response" }

                Invoke-EvergreenRestMethod -Uri "https://example.com" -AllowInsecureRedirect |
                    Should -Be "mock response"
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                    -not $PSBoundParameters.ContainsKey("AllowInsecureRedirect")
                }
            }

            It "Rejects insecure redirects on PowerShell Core when the parameter is unavailable" {
                Mock Test-PSCore { $true }
                Mock Get-Command { [PSCustomObject]@{ Parameters = @{} } } -ParameterFilter {
                    $Name -eq "Invoke-RestMethod"
                }
                Mock Invoke-RestMethod { "mock response" }

                { Invoke-EvergreenRestMethod -Uri "https://example.com" -AllowInsecureRedirect } |
                    Should -Throw "*AllowInsecureRedirect is not supported*"
                Should -Invoke Invoke-RestMethod -Times 0 -Exactly
            }

            It "Passes insecure redirect opt-in to PowerShell Core when supported" -Skip:(-not (Get-Command Invoke-RestMethod).Parameters.ContainsKey("AllowInsecureRedirect")) {
                Mock Test-PSCore { $true }
                Mock Invoke-RestMethod { "mock response" }

                Invoke-EvergreenRestMethod -Uri "https://example.com" -AllowInsecureRedirect |
                    Should -Be "mock response"
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                    $AllowInsecureRedirect -eq $true
                }
            }

            It "Does not enable insecure redirects when explicitly passed false" {
                Mock Invoke-RestMethod { "mock response" }

                Invoke-EvergreenRestMethod -Uri "https://example.com" -AllowInsecureRedirect:$false |
                    Should -Be "mock response"
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                    -not $PSBoundParameters.ContainsKey("AllowInsecureRedirect")
                }
            }

            It "Does not disable certificate validation when explicitly passed false" {
                Mock Invoke-RestMethod { "mock response" }

                Invoke-EvergreenRestMethod -Uri "https://example.com" -SkipCertificateCheck:$false |
                    Should -Be "mock response"
                Should -Invoke Invoke-RestMethod -ParameterFilter {
                    $PSBoundParameters.ContainsKey("SkipCertificateCheck")
                } -Times 0 -Exactly
            }

            It "Returns data from a proper URL" {
                $params = @{
                    ContentType          = "application/vnd.github.v3+json"
                    ErrorAction          = "SilentlyContinue"
                    Method               = "Default"
                    SkipCertificateCheck = $True
                    SslProtocol          = "Tls12"
                    UserAgent            = [Microsoft.PowerShell.Commands.PSUserAgent]::Safari
                    Uri                  = "https://api.github.com/rate_limit"
                }
                Invoke-EvergreenRestMethod @params | Should -BeOfType [System.Object]
            }

            It "Should throw with an invalid URL" {
                { Invoke-EvergreenRestMethod -Uri "https://nonsense.git" -WarningAction "SilentlyIgnore" } | Should -Throw
            }

            It "Should throw with an invalid proxy server " {
                Set-ProxyEnv -Proxy "test.local"
                { Invoke-EvergreenRestMethod -Uri "https://example.com" -WarningAction "SilentlyIgnore" } | Should -Throw
                Remove-ProxyEnv
            }
        }
    }
}
