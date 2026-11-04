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
    Describe -Name "Invoke-EvergreenWebRequest" {
        AfterEach {
            # Module-scoped proxy settings outlive Pester's per-test mocks.
            Remove-ProxyEnv
        }

        Context "Ensure Invoke-EvergreenWebRequest works as expected" {
            It "Does not disable certificate validation when explicitly passed false" {
                Mock Invoke-WebRequest {
                    [PSCustomObject]@{
                        StatusCode = 200
                        Headers    = @{ "Content-Type" = "text/plain" }
                        Content    = "mock response"
                        RawContent = "HTTP/1.1 200 OK`r`n`r`nmock response"
                    }
                }

                Invoke-EvergreenWebRequest -Uri "https://example.com" -SkipCertificateCheck:$false |
                    Should -Be "mock response"
                Should -Invoke Invoke-WebRequest -ParameterFilter {
                    $PSBoundParameters.ContainsKey("SkipCertificateCheck")
                } -Times 0 -Exactly
            }

            It "Removes the temporary file after returning raw text" {
                $script:RawResponseFile = $null
                Mock Invoke-WebRequest {
                    $script:RawResponseFile = $OutFile
                    [System.IO.File]::WriteAllText($OutFile, "checksum")
                    [PSCustomObject]@{
                        StatusCode = 200
                        Headers    = @{ "Content-Type" = "text/plain" }
                        Content    = "checksum"
                        RawContent = "HTTP/1.1 200 OK`r`n`r`nchecksum"
                    }
                }

                Invoke-EvergreenWebRequest -Uri "https://example.com" -Raw |
                    Should -Be "checksum"
                Test-Path -LiteralPath $script:RawResponseFile | Should -BeFalse
            }

            It "Returns requested response objects" -TestCases @(
                @{ ReturnObject = "Headers"; Expected = "text/plain" }
                @{ ReturnObject = "RawContent"; Expected = "HTTP/1.1 200 OK`r`n`r`nmock response" }
                @{ ReturnObject = "All"; Expected = "response" }
            ) {
                param ($ReturnObject, $Expected)

                $response = [PSCustomObject]@{
                    StatusCode = 200
                    Headers    = @{ "Content-Type" = "text/plain" }
                    Content    = "mock response"
                    RawContent = "HTTP/1.1 200 OK`r`n`r`nmock response"
                    Marker     = "response"
                }
                Mock Invoke-WebRequest { $response }

                $result = Invoke-EvergreenWebRequest -Uri "https://example.com" -ReturnObject $ReturnObject

                if ($ReturnObject -eq "Headers") {
                    $result["Content-Type"] | Should -Be $Expected
                }
                elseif ($ReturnObject -eq "RawContent") {
                    $result | Should -Be $Expected
                }
                else {
                    $result.Marker | Should -Be $Expected
                }
            }

            It "Passes optional request and proxy settings to PowerShell Core" {
                $script:EvergreenProxy = "http://proxy.example.com"
                $script:EvergreenProxyCreds = [System.Management.Automation.PSCredential]::new(
                    "proxy-user",
                    (ConvertTo-SecureString "proxy-password" -AsPlainText -Force)
                )
                function script:Invoke-WebRequest {
                    param (
                        [System.String] $Uri,
                        [System.String] $Method,
                        [System.String] $UserAgent,
                        [System.Boolean] $UseBasicParsing,
                        [System.String] $ContentType,
                        [System.Collections.Hashtable] $Headers,
                        [System.Management.Automation.SwitchParameter] $SkipCertificateCheck,
                        [System.String] $SslProtocol,
                        [System.String] $OutFile,
                        [System.Management.Automation.SwitchParameter] $PassThru,
                        [System.String] $Proxy,
                        [System.Management.Automation.PSCredential] $ProxyCredential
                    )
                    $script:CapturedWebParams = $PSBoundParameters
                    [PSCustomObject]@{
                        StatusCode = 200
                        Headers    = @{ "Content-Type" = "text/plain" }
                        Content    = "mock response"
                        RawContent = "HTTP/1.1 200 OK`r`n`r`nmock response"
                    }
                }
                Mock Test-PSCore { $true }
                Mock Test-ProxyEnv { $true }
                try {
                    Invoke-EvergreenWebRequest -Uri "https://example.com" -ContentType "text/plain" `
                        -Headers @{ Accept = "text/plain" } -SkipCertificateCheck -SslProtocol Tls12 -Verbose |
                        Should -Be "mock response"

                    $script:CapturedWebParams.ContentType | Should -Be "text/plain"
                    $script:CapturedWebParams.Headers.Accept | Should -Be "text/plain"
                    $script:CapturedWebParams.SkipCertificateCheck | Should -BeTrue
                    $script:CapturedWebParams.SslProtocol | Should -Be "Tls12"
                    $script:CapturedWebParams.Proxy | Should -Be "http://proxy.example.com"
                    $script:CapturedWebParams.ProxyCredential.UserName | Should -Be "proxy-user"
                }
                finally {
                    Remove-Item -Path "Function:Invoke-WebRequest" -Force
                    Remove-Variable -Name CapturedWebParams -Scope Script -ErrorAction SilentlyContinue
                }
            }

            It "Does not leak proxy settings or credentials into subsequent requests" {
                Test-ProxyEnv | Should -BeFalse
                Test-ProxyEnv -Creds | Should -BeFalse
                Mock Invoke-WebRequest {
                    [PSCustomObject]@{
                        StatusCode = 200
                        Headers    = @{ "Content-Type" = "text/plain" }
                        Content    = "mock response"
                        RawContent = "HTTP/1.1 200 OK`r`n`r`nmock response"
                    }
                }

                Invoke-EvergreenWebRequest -Uri "https://example.com" | Should -Be "mock response"

                Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                    -not $PSBoundParameters.ContainsKey("Proxy") -and
                    -not $PSBoundParameters.ContainsKey("ProxyCredential")
                }
            }

            It "Honors WhatIf without issuing a request" {
                Mock Invoke-WebRequest {}

                Invoke-EvergreenWebRequest -Uri "https://example.com" -WhatIf | Should -BeNullOrEmpty

                Should -Invoke Invoke-WebRequest -Times 0 -Exactly
            }

            It "Returns no content for an empty response" {
                Mock Invoke-WebRequest { $null }

                Invoke-EvergreenWebRequest -Uri "https://example.com" | Should -BeNullOrEmpty
            }

            It "Applies and restores an explicit legacy TLS protocol" {
                $originalProtocol = [System.Net.ServicePointManager]::SecurityProtocol
                Mock Test-PSCore { $false }
                Mock Invoke-WebRequest {
                    [PSCustomObject]@{
                        StatusCode = 200
                        Headers    = @{ "Content-Type" = "text/plain" }
                        Content    = "mock response"
                        RawContent = "HTTP/1.1 200 OK`r`n`r`nmock response"
                    }
                }
                try {
                    Invoke-EvergreenWebRequest -Uri "https://example.com" -SslProtocol Tls |
                        Should -Be "mock response"
                    [System.Net.ServicePointManager]::SecurityProtocol | Should -Be $originalProtocol
                }
                finally {
                    [System.Net.ServicePointManager]::SecurityProtocol = $originalProtocol
                }
            }

            It "Warns and rethrows request failures" {
                Mock Invoke-WebRequest { throw "request failed" }

                { Invoke-EvergreenWebRequest -Uri "https://example.com" -WarningAction SilentlyContinue } |
                    Should -Throw "*request failed*"
            }

            It "Rejects TLS 1.3 on Windows PowerShell and restores the prior protocol" {
                $originalProtocol = [System.Net.ServicePointManager]::SecurityProtocol
                Mock Test-PSCore { $false }

                try {
                    { Invoke-EvergreenWebRequest -Uri "https://example.com" -SslProtocol Tls13 } |
                        Should -Throw "*TLS 1.3 is not supported*"
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
                    Mock Invoke-WebRequest {
                        [PSCustomObject]@{
                            StatusCode = 200
                            Headers    = @{ "Content-Type" = "text/plain" }
                            Content    = "mock response"
                            RawContent = "HTTP/1.1 200 OK`r`n`r`nmock response"
                        }
                    }
                    try {
                        Invoke-EvergreenWebRequest -Uri "https://example.com" -SkipCertificateCheck |
                            Should -Be "mock response"
                        [System.Net.ServicePointManager]::CertificatePolicy | Should -Be $originalPolicy
                    }
                    finally {
                        [System.Net.ServicePointManager]::CertificatePolicy = $originalPolicy
                    }
                }
            }

            It "Returns data from a URL" -Tag "Integration" {
                $params = @{
                    ContentType          = "text/html"
                    ErrorAction          = "SilentlyContinue"
                    #Headers
                    #Raw
                    #ReturnObject = "Content"
                    Method               = "Default"
                    SkipCertificateCheck = $true
                    SslProtocol          = "Tls12"
                    UserAgent            = [Microsoft.PowerShell.Commands.PSUserAgent]::Safari
                    Uri                  = "https://github.com"
                }
                Invoke-EvergreenWebRequest @params | Should -BeOfType [System.String]
            }

            It "Should throw with an invalid URL" -Tag "Integration" {
                { Invoke-EvergreenWebRequest -Uri "https://nonsense.git" -WarningAction "SilentlyIgnore" } | Should -Throw
            }

            It "Should throw with an invalid proxy server " -Tag "Integration" {
                Set-ProxyEnv -Proxy "test.local"
                { Invoke-EvergreenWebRequest -Uri "https://example.com" -WarningAction "SilentlyIgnore" } | Should -Throw
                Remove-ProxyEnv
            }
        }
    }
}
