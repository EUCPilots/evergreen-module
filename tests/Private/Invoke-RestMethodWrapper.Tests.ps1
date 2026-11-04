<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "This is OK for tests.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Invoke-EvergreenRestMethod" {
        AfterEach {
            # Module-scoped proxy settings outlive Pester's per-test mocks.
            Remove-ProxyEnv
        }

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

                Invoke-EvergreenRestMethod -Uri "https://example.com" -SkipCertificateCheck:$false `
                    -ErrorAction SilentlyContinue |
                    Should -Be "mock response"
                Should -Invoke Invoke-RestMethod -ParameterFilter {
                    $PSBoundParameters.ContainsKey("SkipCertificateCheck")
                } -Times 0 -Exactly
            }

            It "Passes request options, proxy settings, and credentials to PowerShell Core" {
                $script:EvergreenProxy = "http://proxy.example.com"
                $script:EvergreenProxyCreds = [System.Management.Automation.PSCredential]::new(
                    "proxy-user",
                    (ConvertTo-SecureString "proxy-password" -AsPlainText -Force)
                )
                $headers = @{ Authorization = "Bearer token" }
                $body = @{ name = "test" }
                function script:Invoke-RestMethod {
                    param (
                        [System.String] $Uri,
                        [System.String] $ContentType,
                        [System.Collections.Hashtable] $Headers,
                        [System.Object] $Body,
                        [System.String] $Method,
                        [System.Int32] $MaximumRedirection,
                        [System.Boolean] $UseBasicParsing,
                        [System.String] $UserAgent,
                        [System.Management.Automation.SwitchParameter] $SkipCertificateCheck,
                        [System.String] $SslProtocol,
                        [System.Management.Automation.SwitchParameter] $AllowInsecureRedirect,
                        [System.String] $Proxy,
                        [System.Management.Automation.PSCredential] $ProxyCredential
                    )
                    $script:CapturedRestParams = $PSBoundParameters
                    "mock response"
                }
                Mock Test-PSCore { $true }
                Mock Test-ProxyEnv { $true }
                try {
                    Invoke-EvergreenRestMethod -Uri "https://example.com" -Headers $headers -Body $body `
                        -SkipCertificateCheck -SslProtocol Tls12 -AllowInsecureRedirect -ErrorAction SilentlyContinue |
                        Should -Be "mock response"

                    $script:CapturedRestParams.Headers.Authorization | Should -Be "Bearer token"
                    $script:CapturedRestParams.Body.name | Should -Be "test"
                    $script:CapturedRestParams.SkipCertificateCheck | Should -BeTrue
                    $script:CapturedRestParams.SslProtocol | Should -Be "Tls12"
                    $script:CapturedRestParams.AllowInsecureRedirect | Should -BeTrue
                    $script:CapturedRestParams.Proxy | Should -Be "http://proxy.example.com"
                    $script:CapturedRestParams.ProxyCredential.UserName | Should -Be "proxy-user"
                }
                finally {
                    Remove-Item -Path "Function:Invoke-RestMethod" -Force
                    Remove-Variable -Name CapturedRestParams -Scope Script -ErrorAction SilentlyContinue
                }
            }

            It "Does not leak proxy settings or credentials into subsequent requests" {
                Test-ProxyEnv | Should -BeFalse
                Test-ProxyEnv -Creds | Should -BeFalse
                Mock Invoke-RestMethod { "mock response" }

                Invoke-EvergreenRestMethod -Uri "https://example.com" | Should -Be "mock response"

                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                    -not $PSBoundParameters.ContainsKey("Proxy") -and
                    -not $PSBoundParameters.ContainsKey("ProxyCredential")
                }
            }

            It "Applies and restores the requested legacy TLS protocol" {
                $originalProtocol = [System.Net.ServicePointManager]::SecurityProtocol
                Mock Test-PSCore { $false }
                Mock Invoke-RestMethod { "mock response" }
                try {
                    Invoke-EvergreenRestMethod -Uri "https://example.com" -SslProtocol Tls |
                        Should -Be "mock response"
                    [System.Net.ServicePointManager]::SecurityProtocol | Should -Be $originalProtocol
                }
                finally {
                    [System.Net.ServicePointManager]::SecurityProtocol = $originalProtocol
                }
            }

            if ($PSVersionTable.PSVersion.Major -lt 6) {
                It "Temporarily trusts certificates in Windows PowerShell and restores the prior policy" {
                    $originalPolicy = [System.Net.ServicePointManager]::CertificatePolicy
                    Mock Test-PSCore { $false }
                    Mock Invoke-RestMethod { "mock response" }
                    try {
                        Invoke-EvergreenRestMethod -Uri "https://example.com" -SkipCertificateCheck |
                            Should -Be "mock response"
                        [System.Net.ServicePointManager]::CertificatePolicy | Should -Be $originalPolicy
                    }
                    finally {
                        [System.Net.ServicePointManager]::CertificatePolicy = $originalPolicy
                    }
                }
            }

            It "Rejects TLS 1.3 on Windows PowerShell and restores the prior protocol" {
                $originalProtocol = [System.Net.ServicePointManager]::SecurityProtocol
                Mock Test-PSCore { $false }

                try {
                    { Invoke-EvergreenRestMethod -Uri "https://example.com" -SslProtocol Tls13 } |
                        Should -Throw "*TLS 1.3 is not supported*"
                    [System.Net.ServicePointManager]::SecurityProtocol | Should -Be $originalProtocol
                }
                finally {
                    [System.Net.ServicePointManager]::SecurityProtocol = $originalProtocol
                }
            }

            It "Warns and rethrows request failures" {
                Mock Invoke-RestMethod { throw "request failed" }

                { Invoke-EvergreenRestMethod -Uri "https://example.com" -WarningAction SilentlyContinue } |
                    Should -Throw "*request failed*"
            }

            It "Returns data from a proper URL" -Tag "Integration" {
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

            It "Should throw with an invalid URL" -Tag "Integration" {
                { Invoke-EvergreenRestMethod -Uri "https://nonsense.git" -WarningAction "SilentlyIgnore" } | Should -Throw
            }

            It "Should throw with an invalid proxy server " -Tag "Integration" {
                Set-ProxyEnv -Proxy "test.local"
                { Invoke-EvergreenRestMethod -Uri "https://example.com" -WarningAction "SilentlyIgnore" } | Should -Throw
                Remove-ProxyEnv
            }
        }
    }
}
