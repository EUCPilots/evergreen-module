<#
    .SYNOPSIS
        Pester tests for Get-AzulZulu.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Get-AzulZulu" {
        Context "Throw scenarios" {
            It "Does not throw when passed correct parameters" {
                # Mock resource object
                $res = [PSCustomObject]@{
                    Get = [PSCustomObject]@{
                        Update = [PSCustomObject]@{
                            Uri         = "https://api.azul.com/metadata/v1/zulu/packages/?java_version=25&os=windows&archive_type=msi&crac_supported=false&latest=true&release_status=ga&availability_types=CA&certifications=tck&page=1&page_size=100"
                            ContentType = "application/json"
                        }
                    }
                }
                { Get-AzulZulu -res $res } | Should -Not -Throw
            }

            It "Should throw when passed an incorrect URL" {
                # Mock resource object with invalid URL
                $res = [PSCustomObject]@{
                    Get = [PSCustomObject]@{
                        Update = [PSCustomObject]@{
                            Uri         = "https://api.example.com/invalid/endpoint"
                            ContentType = "application/json"
                        }
                    }
                }
                { Get-AzulZulu -res $res } | Should -Throw
            }
        }

        Context "It returns an object with the expected properties" {
            BeforeAll {
                # Mock resource object
                $res = [PSCustomObject]@{
                    Get = [PSCustomObject]@{
                        Update = [PSCustomObject]@{
                            Uri         = "https://api.azul.com/metadata/v1/zulu/packages/?java_version=25&os=windows&archive_type=msi&crac_supported=false&latest=true&release_status=ga&availability_types=CA&certifications=tck&page=1&page_size=100"
                            ContentType = "application/json"
                        }
                    }
                }
                $result = Get-AzulZulu -res $res
            }

            It "Returns results" {
                $result | Should -Not -BeNullOrEmpty
            }

            It "Returns a Version property" {
                $result[0].Version | Should -Not -BeNullOrEmpty
                $result[0].Version.Length | Should -BeGreaterThan 0
            }

            It "Returns a JavaVersion property" {
                $result[0].JavaVersion | Should -Not -BeNullOrEmpty
                $result[0].JavaVersion.Length | Should -BeGreaterThan 0
            }

            It "Returns an ImageType property" {
                $result[0].ImageType | Should -Not -BeNullOrEmpty
                $result[0].ImageType | Should -BeIn @("JRE", "JDK")
            }

            It "Returns an Architecture property" {
                $result[0].Architecture | Should -Not -BeNullOrEmpty
                $result[0].Architecture.Length | Should -BeGreaterThan 0
            }

            It "Returns a Type property" {
                $result[0].Type | Should -Not -BeNullOrEmpty
                $result[0].Type.Length | Should -BeGreaterThan 0
            }

            It "Returns a URI property" {
                $result[0].URI | Should -Not -BeNullOrEmpty
                $result[0].URI.Length | Should -BeGreaterThan 0
            }
        }

        Context "It filters for the latest version correctly" {
            BeforeAll {
                # Mock resource object
                $res = [PSCustomObject]@{
                    Get = [PSCustomObject]@{
                        Update = [PSCustomObject]@{
                            Uri         = "https://api.azul.com/metadata/v1/zulu/packages/?java_version=25&os=windows&archive_type=msi&crac_supported=false&latest=true&release_status=ga&availability_types=CA&certifications=tck&page=1&page_size=100"
                            ContentType = "application/json"
                        }
                    }
                }
                $result = Get-AzulZulu -res $res
            }

            It "Returns only the latest version" {
                $versions = $result.Version | Select-Object -Unique
                $versions.Count | Should -Be 1
            }

            It "All results have the same version number" {
                $uniqueVersions = $result | Select-Object -ExpandProperty Version -Unique
                $uniqueVersions.Count | Should -Be 1
            }
        }
    }
}
