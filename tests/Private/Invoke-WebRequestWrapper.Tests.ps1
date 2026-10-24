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
    Describe -Name "Invoke-EvergreenWebRequest" {
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

            It "Returns data from a URL" {
                $params = @{
                    ContentType          = "text/html"
                    ErrorAction          = "SilentlyContinue"
                    #Headers
                    #Raw
                    #ReturnObject = "Content"
                    Method               = "Default"
                    SkipCertificateCheck = $True
                    SslProtocol          = "Tls12"
                    UserAgent            = [Microsoft.PowerShell.Commands.PSUserAgent]::Safari
                    Uri                  = "https://github.com"
                }
                Invoke-EvergreenWebRequest @params | Should -BeOfType [System.String]
            }

            It "Should throw with an invalid URL" {
                { Invoke-EvergreenWebRequest -Uri "https://nonsense.git" -WarningAction "SilentlyIgnore" } | Should -Throw
            }

            It "Should throw with an invalid proxy server " {
                Set-ProxyEnv -Proxy "test.local"
                { Invoke-EvergreenWebRequest -Uri "https://example.com" -WarningAction "SilentlyIgnore" } | Should -Throw
                Remove-ProxyEnv
            }
        }
    }
}
