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
            InModuleScope -ModuleName "Evergreen" {
                { ConvertFrom-Jwt -Token "" } | Should -Throw
            }
        }

        It "Should throw when Token parameter is null" {
            InModuleScope -ModuleName "Evergreen" {
                { ConvertFrom-Jwt -Token $null } | Should -Throw
            }
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

        It "Should terminate on invalid Base64 encoding in the header" {
            InModuleScope -ModuleName "Evergreen" {
                # Invalid base64 in header
                $Token = "invalid!!!.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature"
                { ConvertFrom-Jwt -Token $Token -ErrorAction "Continue" } |
                    Should -Throw "*ConvertFrom-Jwt: Failed to decode Header:*"
            }
        }

        It "Should terminate on invalid JSON in the payload" {
            InModuleScope -ModuleName "Evergreen" {
                # Valid base64 but invalid JSON
                $InvalidJson = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("not valid json"))
                $Token = "eyJhbGciOiJIUzI1NiJ9.$InvalidJson.signature"
                { ConvertFrom-Jwt -Token $Token -ErrorAction "Continue" } |
                    Should -Throw "*ConvertFrom-Jwt: Failed to decode Payload:*"
            }
        }

        It "Should reject <Token> with more than three segments" -ForEach @(
            @{ Token = "e30.e30.signature.extra" }
            @{ Token = "e30.e30.signature." }
            @{ Token = "e30.e30.signature.extra.more" }
        ) {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ Token = $Token } {
                { ConvertFrom-Jwt -Token $Token } |
                    Should -Throw "*Invalid JWT: must contain exactly two or three parts*"
            }
        }

        It "Should terminate on <Reason> in <Part> without emitting a partial result" -ForEach @(
            @{ Part = "Header"; Reason = "invalid Base64"; Value = "invalid!!!" }
            @{ Part = "Payload"; Reason = "invalid Base64"; Value = "invalid!!!" }
            @{ Part = "Header"; Reason = "invalid JSON"; Value = "bm90IHZhbGlkIGpzb24" }
            @{ Part = "Payload"; Reason = "invalid JSON"; Value = "bm90IHZhbGlkIGpzb24" }
            @{ Part = "Header"; Reason = "an empty segment"; Value = "" }
            @{ Part = "Payload"; Reason = "an empty segment"; Value = "" }
            @{ Part = "Header"; Reason = "JSON null"; Value = "bnVsbA" }
            @{ Part = "Payload"; Reason = "JSON null"; Value = "bnVsbA" }
        ) {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ Part = $Part; Value = $Value } {
                $Token = if ($Part -eq "Header") { "$Value.e30.signature" } else { "e30.$Value.signature" }
                $Output = [System.Collections.Generic.List[object]]::new()
                {
                    ConvertFrom-Jwt -Token $Token -ErrorAction "Continue" |
                        ForEach-Object { $Output.Add($_) }
                } | Should -Throw "*ConvertFrom-Jwt: Failed to decode ${Part}:*"
                $Output.Count | Should -Be 0
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
        It "Should accept exactly two segments and return a null signature" {
            InModuleScope -ModuleName "Evergreen" {
                $Result = ConvertFrom-Jwt -Token "eyJhbGciOiJub25lIn0.eyJzdWIiOiJ0ZXN0In0"
                $Result.Header.alg | Should -Be "none"
                $Result.Payload.sub | Should -Be "test"
                ($null -eq $Result.Signature) | Should -Be $true
            }
        }

        It "Should preserve an empty signature in a three-part JWT" {
            InModuleScope -ModuleName "Evergreen" {
                # JWT with empty signature part
                $Token = "eyJhbGciOiJub25lIn0.eyJzdWIiOiJ0ZXN0In0."
                $Result = ConvertFrom-Jwt -Token $Token
                $Result.Header | Should -Not -BeNullOrEmpty
                $Result.Payload | Should -Not -BeNullOrEmpty
                $Result.Signature | Should -Be ""
                $Result.Signature | Should -BeOfType [System.String]
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

    Context "Validate ConvertFrom-Jwt with a production-shaped release manifest" {
        It "Should preserve the release manifest structure and separate signatures" {
            InModuleScope -ModuleName "Evergreen" {
                $HeaderJson = '{"alg":"RS256","cty":"json"}'
                $PayloadJson = @'
{
    "iat": 1792754864,
    "exp": 1792758464,
    "iss": "Trimble, Inc.",
    "versions": [
        {
            "operatingSystem": "windows",
            "versionNumber": "27.0.264",
            "fileName": "SketchUp-2027-0-264-170.exe",
            "installerUrl": "https://download.sketchup.com/SketchUp-2027-0-264-170.exe",
            "title": "SketchUp for Windows",
            "releaseDate": "2026-10-21",
            "releaseNotes": {
                "en": "https://help.sketchup.com/en/current-release-notes"
            },
            "generallyAvailable": false,
            "signature": "5df77bfac25564ce7929974bbb4956de69287cf13ad860ff32774f35f411c213"
        }
    ]
}
'@
                $Header = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($HeaderJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
                $Payload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($PayloadJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
                # A synthetic signature keeps this fixture focused on decoding, not verification.
                $Result = ConvertFrom-Jwt -Token "$Header.$Payload.jwt-signature"

                $Result.Header.alg | Should -Be "RS256"
                $Result.Header.cty | Should -Be "json"
                $Result.Header.PSObject.Properties.Name | Should -Not -Contain "typ"
                $Result.Payload.iat | Should -Be 1792754864
                $Result.Payload.exp | Should -Be 1792758464
                $Result.Payload.iss | Should -Be "Trimble, Inc."
                ($Result.Payload.versions -is [System.Array]) | Should -Be $true
                $Result.Payload.versions.Count | Should -Be 1
                $Release = $Result.Payload.versions[0]
                $Release.operatingSystem | Should -Be "windows"
                $Release.versionNumber | Should -Be "27.0.264"
                $Release.fileName | Should -Be "SketchUp-2027-0-264-170.exe"
                $Release.installerUrl | Should -Be "https://download.sketchup.com/SketchUp-2027-0-264-170.exe"
                $Release.title | Should -Be "SketchUp for Windows"
                $Release.releaseNotes.en | Should -Be "https://help.sketchup.com/en/current-release-notes"
                $Release.generallyAvailable | Should -BeOfType [System.Boolean]
                $Release.generallyAvailable | Should -Be $false
                $Release.signature | Should -Be "5df77bfac25564ce7929974bbb4956de69287cf13ad860ff32774f35f411c213"
                $Result.Signature | Should -Be "jwt-signature"
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
