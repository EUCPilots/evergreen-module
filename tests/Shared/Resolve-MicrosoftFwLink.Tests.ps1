<#
    .SYNOPSIS
        Pester tests for Resolve-MicrosoftFwLink.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

InModuleScope -ModuleName "Evergreen" {
    Describe -Name "Resolve-MicrosoftFwLink" {
        BeforeEach {
            $script:TestMicrosoftFwLinkResponse = [PSCustomObject]@{
                ResponseUri   = [System.Uri]"https://download.microsoft.com/files/Product-1.2.3.4-x64.msi?version=9.8.7"
                LastModified  = [DateTime]::new(2024, 3, 5, 0, 0, 0, [DateTimeKind]::Utc)
                ContentLength = 12345
            }

            Mock Resolve-SystemNetWebRequest {
                $script:TestMicrosoftFwLinkResponse
            }
            Mock Get-Architecture { "x64" }
            Mock Get-FileType { "msi" }
        }

        It "Extracts the version from the final URL path and returns stable metadata" {
            $Result = Resolve-MicrosoftFwLink -Uri "https://go.microsoft.com/fwlink/?source=app&linkid=2248728"

            $Result.Version | Should -Be "1.2.3.4"
            #$Result.Date | Should -Be "2024-03-05"
            $Result.Size | Should -Be 12345
            $Result.URI | Should -Be "https://download.microsoft.com/files/Product-1.2.3.4-x64.msi?version=9.8.7"
        }

        It "Returns Unknown and warns when the final path has no version" {
            $script:TestMicrosoftFwLinkResponse.ResponseUri = [System.Uri]"https://download.microsoft.com/files/Product-x64.msi?version=9.8.7"

            $Warnings = @()
            $Result = Resolve-MicrosoftFwLink -Uri "https://go.microsoft.com/fwlink/?linkid=2248728" -WarningVariable Warnings

            $Result.Version | Should -Be "Unknown"
            $Warnings.Count | Should -BeGreaterThan 0
        }

        It "Returns null for unavailable date and size metadata" {
            $script:TestMicrosoftFwLinkResponse.LastModified = [DateTime]::MinValue
            $script:TestMicrosoftFwLinkResponse.ContentLength = -1

            $Result = Resolve-MicrosoftFwLink -Uri "https://go.microsoft.com/fwlink/?linkid=2248728"

            $Result.Date | Should -BeNullOrEmpty
            $Result.Size | Should -BeNullOrEmpty
        }

        It "Rejects a URI without a numeric linkid query parameter" {
            { Resolve-MicrosoftFwLink -Uri "https://go.microsoft.com/fwlink/?source=app" } | Should -Throw
        }

        It "Rejects a negative redirect limit" {
            { Resolve-MicrosoftFwLink -Uri "https://go.microsoft.com/fwlink/?linkid=2248728" -MaximumRedirection -1 } | Should -Throw
        }
    }
}
