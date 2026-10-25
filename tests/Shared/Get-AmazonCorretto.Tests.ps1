<#
    .SYNOPSIS
        Pester tests for Get-AmazonCorretto.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-AmazonCorretto" {
        BeforeEach {
            $res = [PSCustomObject]@{
                Get = [PSCustomObject]@{
                    Download = [PSCustomObject]@{
                        Uri = @(
                            "https://corretto.aws/downloads/latest/amazon-corretto-25-x64-windows-jdk.msi?channel=latest"
                            "https://corretto.aws/downloads/latest/amazon-corretto-25-x64-windows-jdk.zip"
                        )
                        Property      = "ResponseUri.Headers.Location"
                        MatchVersion  = "(\d+(\.\d+){1,4})"
                    }
                }
            }
            $script:TestAmazonCorrettoChecksumUris = @()
            $script:TestAmazonCorrettoVersionlessUri = $false
            $script:TestAmazonCorrettoUnknownArchitecture = $false
            $script:TestAmazonCorrettoNullResponse = $false
            $script:TestAmazonCorrettoChecksum = " 0123456789abcdef0123456789abcdef`r`n"

            Mock Resolve-SystemNetWebRequest {
                param ($Uri)
                if ($script:TestAmazonCorrettoNullResponse) {
                    return
                }
                if ($script:TestAmazonCorrettoVersionlessUri) {
                    $ResolvedUri = "https://corretto.aws/downloads/latest/amazon-corretto-x64-windows-jdk.msi"
                }
                elseif ($script:TestAmazonCorrettoUnknownArchitecture) {
                    $ResolvedUri = "https://corretto.aws/downloads/latest/amazon-corretto-25.0.2.9.1-windows-jdk.msi"
                }
                else {
                    $Extension = [System.IO.Path]::GetExtension(([System.Uri]$Uri).AbsolutePath)
                    $ResolvedUri = "https://corretto.aws/downloads/latest/amazon-corretto-25.0.2.9.1-x64-windows-jdk$Extension"
                }
                [PSCustomObject]@{ ResponseUri = [System.Uri]$ResolvedUri }
            }
            Mock Invoke-EvergreenWebRequest {
                param ($Uri)
                $script:TestAmazonCorrettoChecksumUris += $Uri
                $script:TestAmazonCorrettoChecksum
            }
        }

        It "Returns versioned download metadata for each manifest URI" {
            $Results = @(Get-AmazonCorretto -res $res)

            $Results.Count | Should -Be 2
            $Results[0].Version | Should -Be "25.0.2.9.1"
            $Results[0].Md5 | Should -Be "0123456789abcdef0123456789abcdef"
            $Results[0].Architecture | Should -Be "x64"
            $Results[0].ImageType | Should -Be "JDK"
            $Results[0].Type | Should -Be "msi"
            $Results[1].Type | Should -Be "zip"
        }

        It "Replaces only the latest URL path segment when requesting checksums" {
            $null = @(Get-AmazonCorretto -res $res)

            $script:TestAmazonCorrettoChecksumUris | Should -Contain "https://corretto.aws/downloads/latest_checksum/amazon-corretto-25-x64-windows-jdk.msi?channel=latest"
            $script:TestAmazonCorrettoChecksumUris | Should -Contain "https://corretto.aws/downloads/latest_checksum/amazon-corretto-25-x64-windows-jdk.zip"
        }

        It "Rejects a version pattern without a capture group" {
            $res.Get.Download.MatchVersion = "\d+"

            { Get-AmazonCorretto -res $res } | Should -Throw "*must define a capture group*"
        }

        It "Rejects a resolved URI without a version match" {
            $script:TestAmazonCorrettoVersionlessUri = $true

            { Get-AmazonCorretto -res $res } | Should -Throw "*Could not extract a version*"
        }

        It "Rejects an invalid checksum response" {
            $script:TestAmazonCorrettoChecksum = "not-a-checksum"

            { Get-AmazonCorretto -res $res } | Should -Throw "*not a valid MD5 checksum*"
        }

        It "Rejects a resolved URI without a recognizable architecture" {
            $script:TestAmazonCorrettoUnknownArchitecture = $true

            { Get-AmazonCorretto -res $res } | Should -Throw "*Could not determine the architecture*"
        }

        It "Reports a download URI that cannot be resolved" {
            $script:TestAmazonCorrettoNullResponse = $true

            { Get-AmazonCorretto -res $res } | Should -Throw "*Could not resolve download URI*"
        }
    }
}
