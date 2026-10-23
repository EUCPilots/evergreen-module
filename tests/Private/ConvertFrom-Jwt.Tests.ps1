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
    # Create test JWT tokens
    # Valid JWT token structure: header.payload.signature
    # Example JWT token (standard format)
    $script:ValidJwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    
    # JWT with additional claims
    $script:JwtWithClaims = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwibmFtZSI6IkphbmUgU21pdGgiLCJlbWFpbCI6ImphbmVAZXhhbXBsZS5jb20iLCJyb2xlIjoiYWRtaW4iLCJleHAiOjE3MDAwMDAwMDAsImlhdCI6MTcwMDAwMDAwMH0.signature"
}

Describe -Tag "Private" -Name "ConvertFrom-Jwt" {
    Context "Validate ConvertFrom-Jwt with valid JWT tokens" {
        It "Should not throw with valid JWT token" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                { ConvertFrom-Jwt -Token $Token } | Should -Not -Throw
            }
        }

        It "Should return an object with Header, Payload, and Signature properties" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.PSObject.Properties.Name | Should -Contain "Header"
                $Result.PSObject.Properties.Name | Should -Contain "Payload"
                $Result.PSObject.Properties.Name | Should -Contain "Signature"
            }
        }

        It "Should decode header correctly" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Header | Should -Not -BeNullOrEmpty
                $Result.Header.alg | Should -Be "HS256"
                $Result.Header.typ | Should -Be "JWT"
            }
        }

        It "Should decode payload correctly" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Payload | Should -Not -BeNullOrEmpty
                $Result.Payload.sub | Should -Be "1234567890"
                $Result.Payload.name | Should -Be "John Doe"
                $Result.Payload.iat | Should -Be 1516239022
            }
        }

        It "Should return signature as string" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Signature | Should -Not -BeNullOrEmpty
                $Result.Signature | Should -BeOfType [string]
                $Result.Signature | Should -Be "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
            }
        }

        It "Should handle JWT with multiple claims in payload" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwibmFtZSI6IkphbmUgU21pdGgiLCJlbWFpbCI6ImphbmVAZXhhbXBsZS5jb20iLCJyb2xlIjoiYWRtaW4iLCJleHAiOjE3MDAwMDAwMDAsImlhdCI6MTcwMDAwMDAwMH0.signature"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Payload.sub | Should -Be "user123"
                $Result.Payload.name | Should -Be "Jane Smith"
                $Result.Payload.email | Should -Be "jane@example.com"
                $Result.Payload.role | Should -Be "admin"
            }
        }

        It "Should handle JWT with RS256 algorithm" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwibmFtZSI6IkphbmUgU21pdGgiLCJlbWFpbCI6ImphbmVAZXhhbXBsZS5jb20iLCJyb2xlIjoiYWRtaW4iLCJleHAiOjE3MDAwMDAwMDAsImlhdCI6MTcwMDAwMDAwMH0.signature"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Header.alg | Should -Be "RS256"
                $Result.Header.typ | Should -Be "JWT"
            }
        }
    }

    Context "Validate ConvertFrom-Jwt with Base64URL encoding edge cases" {
        It "Should handle padding correctly for tokens that need padding" {
            InModuleScope -ModuleName "Evergreen" {
                # This token requires padding adjustment
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                { ConvertFrom-Jwt -Token $Token } | Should -Not -Throw
            }
        }

        It "Should handle Base64URL characters (- and _) correctly" {
            InModuleScope -ModuleName "Evergreen" {
                # JWT tokens use Base64URL encoding which replaces + with - and / with _
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZXN0Ijoid2l0aC1oeXBoZW4iLCJ0ZXN0MiI6IndpdGhfdW5kZXJzY29yZSJ9.signature"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Payload | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Validate ConvertFrom-Jwt with invalid JWT tokens" {
        It "Should throw when Token parameter is null or empty" {
            { ConvertFrom-Jwt -Token "" } | Should -Throw
        }

        It "Should throw when Token parameter is null" {
            { ConvertFrom-Jwt -Token $null } | Should -Throw
        }

        It "Should throw when JWT has only one part" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertFrom-Jwt -Token "onlyonepart" } | Should -Throw "*Invalid JWT*"
            }
        }

        It "Should throw when JWT has no separator" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertFrom-Jwt -Token "noseparatortoken" } | Should -Throw "*Invalid JWT*"
            }
        }

        It "Should handle invalid Base64 encoding gracefully" {
            InModuleScope -ModuleName "Evergreen" {
                # Invalid base64 in header
                $Token = "invalid!!!.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature"
                $Result = ConvertFrom-Jwt -Token $Token -WarningAction SilentlyContinue
                $Result.Header | Should -BeNullOrEmpty
            }
        }

        It "Should handle invalid JSON in payload gracefully" {
            InModuleScope -ModuleName "Evergreen" {
                # Valid base64 but invalid JSON
                $InvalidJson = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("not valid json"))
                $Token = "eyJhbGciOiJIUzI1NiJ9.$InvalidJson.signature"
                $Result = ConvertFrom-Jwt -Token $Token -WarningAction SilentlyContinue
                $Result.Payload | Should -BeNullOrEmpty
            }
        }
    }

    Context "Validate ConvertFrom-Jwt output structure" {
        It "Should return PSCustomObject" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result | Should -BeOfType [PSCustomObject]
            }
        }

        It "Should have exactly 3 properties (Header, Payload, Signature)" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                ($Result.PSObject.Properties | Measure-Object).Count | Should -Be 3
            }
        }

        It "Should decode Header as PSCustomObject" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Header | Should -BeOfType [PSCustomObject]
            }
        }

        It "Should decode Payload as PSCustomObject" {
            InModuleScope -ModuleName "Evergreen" {
                $Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Payload | Should -BeOfType [PSCustomObject]
            }
        }
    }

    Context "Validate ConvertFrom-Jwt with minimal JWT" {
        It "Should handle JWT with only header and payload (no signature)" {
            InModuleScope -ModuleName "Evergreen" {
                # JWT with empty signature part
                $Token = "eyJhbGciOiJub25lIn0.eyJzdWIiOiJ0ZXN0In0."
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Header | Should -Not -BeNullOrEmpty
                $Result.Payload | Should -Not -BeNullOrEmpty
                $Result.Signature | Should -Be ""
            }
        }

        It "Should handle JWT with minimal header" {
            InModuleScope -ModuleName "Evergreen" {
                # Minimal JWT header with just algorithm
                $Token = "eyJhbGciOiJub25lIn0.eyJzdWIiOiJ0ZXN0In0.sig"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Header.alg | Should -Be "none"
            }
        }

        It "Should handle JWT with minimal payload" {
            InModuleScope -ModuleName "Evergreen" {
                # Minimal payload
                $Token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0.sig"
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Payload.sub | Should -Be "test"
            }
        }
    }

    Context "Validate ConvertFrom-Jwt parameter validation" {
        It "Should have Token parameter marked as Mandatory" {
            InModuleScope -ModuleName "Evergreen" {
                $Command = Get-Command ConvertFrom-Jwt
                $TokenParam = $Command.Parameters['Token']
                $TokenParam.Attributes.Where({ $_ -is [Parameter] }).Mandatory | Should -Be $true
            }
        }

        It "Should accept Token parameter as string" {
            InModuleScope -ModuleName "Evergreen" {
                $Command = Get-Command ConvertFrom-Jwt
                $TokenParam = $Command.Parameters['Token']
                $TokenParam.ParameterType | Should -Be ([System.String])
            }
        }
    }
}
