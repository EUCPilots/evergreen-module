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
