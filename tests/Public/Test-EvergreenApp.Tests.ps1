<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs to log host.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "This is OK for tests.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Test", "Integration" -Name "Test-EvergreenApp" {
    BeforeAll {
        $App = Get-EvergreenApp -Name "MicrosoftOneDrive"
        $Result = Test-EvergreenApp -InputObject $App
    }

    It "Should not throw with valid input" {
        $params = @{
            InputObject = $App
            UserAgent   = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
            NoProgress  = $true
        }
        { Test-EvergreenApp @params } | Should -Not -Throw
    }

    It "Should return an object with valid Result property" {
        $Result[0].Result | Should -BeOfType [System.Boolean]
    }

    It "Should return an object with valid URI property" {
        $Result[0].URI | Should -BeOfType [System.String]
    }

    It "Should return an HTTP status code" {
        $Result[0].StatusCode | Should -BeOfType [System.Int32]
    }

    It "Should throw if ProxyCredential is provided without Proxy" {
        $Creds = [System.Management.Automation.PSCredential]::new(
            "proxy-user",
            (ConvertTo-SecureString -String "proxy-pass" -AsPlainText -Force)
        )
        { Test-EvergreenApp -InputObject $App -ProxyCredential $Creds -NoProgress } | Should -Throw
    }
}

InModuleScope -ModuleName "Evergreen" {
    Describe -Tag "Test" -Name "Test-EvergreenApp request handling" {
        BeforeAll {
            $testApp = [PSCustomObject]@{
                URI = "https://example.com/installer.msi"
            }
        }

        It "Uses HEAD first and returns its status code" {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{ StatusCode = 200 }
            }

            $result = Test-EvergreenApp -InputObject $testApp -ConnectionTimeoutSeconds 15

            $result.Result | Should -BeTrue
            $result.StatusCode | Should -Be 200
            Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq "HEAD" -and $TimeoutSec -eq 15 -and $ErrorAction -eq "Stop"
            }
        }

        It "Passes proxy credentials and a custom user agent while allowing verbose progress" {
            $Credential = [PSCredential]::new("proxy-user", [System.Security.SecureString]::new())
            Mock Invoke-WebRequest { [PSCustomObject]@{ StatusCode = 200 } }

            $Result = Test-EvergreenApp -InputObject $testApp -Proxy "http://proxy.test:8080" -ProxyCredential $Credential -UserAgent "FixtureAgent" -Verbose

            $Result.Result | Should -BeTrue
            Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                $Proxy -eq "http://proxy.test:8080" -and $ProxyCredential.UserName -eq "proxy-user" -and $UserAgent -eq "FixtureAgent"
            }
        }

        It "Rejects proxy credentials without a proxy without sending a request" {
            Mock Invoke-WebRequest {}
            { Test-EvergreenApp -InputObject $testApp -ProxyCredential ([PSCredential]::Empty) -NoProgress } |
                Should -Throw "*ProxyCredential requires Proxy*"
            Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        }

        It "Handles nonnumeric HTTP statuses from failed HEAD and GET requests" {
            Mock Invoke-WebRequest {
                $Exception = [System.Exception]::new("Invalid status")
                $Exception | Add-Member -MemberType NoteProperty -Name Response -Value ([PSCustomObject]@{ StatusCode = "invalid" })
                throw $Exception
            }

            $Result = Test-EvergreenApp -InputObject $testApp -NoProgress

            $Result.Result | Should -BeFalse
            $Result.StatusCode | Should -BeNullOrEmpty
            Should -Invoke Invoke-WebRequest -Times 2 -Exactly
        }

        It "Falls back to a ranged GET when HEAD fails" {
            Mock Invoke-WebRequest {
                param ($Method)
                if ($Method -eq "HEAD") {
                    throw "HEAD is not supported."
                }
                [PSCustomObject]@{ StatusCode = 206 }
            }

            $result = Test-EvergreenApp -InputObject $testApp

            $result.Result | Should -BeTrue
            $result.StatusCode | Should -Be 206
            Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq "Get" -and $Headers["Range"] -eq "bytes=0-0"
            }
        }

        It "Returns false and the fallback HTTP status when both requests fail" {
            Mock Invoke-WebRequest {
                param ($Method)
                $statusCode = if ($Method -eq "HEAD") { 405 } else { 404 }
                $exception = [System.Exception]::new("HTTP $statusCode")
                $exception | Add-Member -MemberType NoteProperty -Name "Response" -Value ([PSCustomObject]@{ StatusCode = $statusCode })
                throw $exception
            }

            $result = Test-EvergreenApp -InputObject $testApp

            $result.Result | Should -BeFalse
            $result.StatusCode | Should -Be 404
        }

        It "Leaves the status code empty when the request fails before receiving an HTTP response" {
            Mock Invoke-WebRequest {
                throw "Connection failed."
            }

            $result = Test-EvergreenApp -InputObject $testApp

            $result.Result | Should -BeFalse
            $result.StatusCode | Should -BeNullOrEmpty
        }

        It "Warns and continues when an input object has no URI" {
            $objects = @(
                [PSCustomObject]@{ Name = "missing URI" }
                $testApp
            )
            Mock Invoke-WebRequest {
                [PSCustomObject]@{ StatusCode = 200 }
            }

            $results = $objects | Test-EvergreenApp -WarningVariable warnings

            $results[0].Result | Should -BeFalse
            $results[0].URI | Should -BeNullOrEmpty
            $warnings | Should -Not -BeNullOrEmpty
            $results[1].Result | Should -BeTrue
            Should -Invoke Invoke-WebRequest -Times 1 -Exactly
        }
    }
}
