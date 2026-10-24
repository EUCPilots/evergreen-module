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
    Describe -Name "Save-File" {
        BeforeEach {
            Mock Invoke-WebRequest {
                param ($Uri, $OutFile)
                [System.IO.File]::WriteAllText($OutFile, "test")
            }
        }

        It "Returns a FileInfo for a downloaded URL with a query string" {
            $result = Save-File -Uri "https://example.com/installer.json?download=1"
            try {
                $result | Should -BeOfType [System.IO.FileInfo]
                $result.Name | Should -Match "^[0-9a-f]{32}-installer\.json$"
                $result.Exists | Should -BeTrue
            }
            finally {
                Remove-Item -LiteralPath $result.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It "Uses a fallback filename when the URL path has no filename" {
            $result = Save-File -Uri "https://example.com/"
            try {
                $result.Name | Should -Match "^[0-9a-f]{32}-download$"
            }
            finally {
                Remove-Item -LiteralPath $result.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It "Uses a unique output path for each download" {
            $first = Save-File -Uri "https://example.com/installer.json"
            $second = Save-File -Uri "https://example.com/installer.json"
            try {
                $first.FullName | Should -Not -Be $second.FullName
            }
            finally {
                Remove-Item -LiteralPath $first.FullName, $second.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        It "Rejects non-HTTP URLs" {
            { Save-File -Uri "file:///installer.json" } | Should -Throw "*absolute HTTP or HTTPS URL*"
        }

        It "Propagates download errors" {
            $testId = [guid]::NewGuid().ToString("N")
            $uri = "https://example.com/failure-$testId.json"
            Mock Invoke-WebRequest {
                param ($Uri, $OutFile)
                [System.IO.File]::WriteAllText($OutFile, "partial")
                throw "download failed"
            }

            { Save-File -Uri $uri } | Should -Throw "*download failed*"
            @(Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter "*-failure-$testId.json") | Should -BeNullOrEmpty
        }
    }
}
