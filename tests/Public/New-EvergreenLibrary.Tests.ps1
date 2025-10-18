<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "New" -Name "New-EvergreenLibrary" {
    Context "Validate New-EvergreenLibrary parameter validation" {
        It "Should not throw with valid Path parameter" {
            if ($env:Temp) {
                $TestPath = Join-Path -Path $env:Temp -ChildPath "NewEvergreenLibraryTest"
            }
            elseif ($env:TMPDIR) {
                $TestPath = Join-Path -Path $env:TMPDIR -ChildPath "NewEvergreenLibraryTest"
            }
            else {
                $TestPath = "/tmp/NewEvergreenLibraryTest"
            }

            try {
                { New-EvergreenLibrary -Path $TestPath } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path $TestPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
        }

        It "Should throw when Path parameter is null or empty" {
            { New-EvergreenLibrary -Path "" } | Should -Throw
        }
    }

    Context "Validate New-EvergreenLibrary creates library structure" {
        BeforeAll {
            if ($env:Temp) {
                $script:TestLibPath = Join-Path -Path $env:Temp -ChildPath "NewEvergreenLibraryTest2"
            }
            elseif ($env:TMPDIR) {
                $script:TestLibPath = Join-Path -Path $env:TMPDIR -ChildPath "NewEvergreenLibraryTest2"
            }
            else {
                $script:TestLibPath = "/tmp/NewEvergreenLibraryTest2"
            }
        }

        AfterAll {
            Remove-Item -Path $script:TestLibPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }

        It "Should create library directory" {
            New-EvergreenLibrary -Path $script:TestLibPath
            Test-Path -Path $script:TestLibPath -PathType "Container" | Should -Be $true
        }

        It "Should create library structure files" {
            $LibraryFile = Get-ChildItem -Path $script:TestLibPath -Filter "*.json" -ErrorAction "SilentlyContinue"
            $LibraryFile | Should -Not -BeNullOrEmpty
        }
    }

    Context "Validate New-EvergreenLibrary with existing directory" {
        BeforeAll {
            if ($env:Temp) {
                $script:ExistingPath = Join-Path -Path $env:Temp -ChildPath "ExistingEvergreenLibrary"
            }
            elseif ($env:TMPDIR) {
                $script:ExistingPath = Join-Path -Path $env:TMPDIR -ChildPath "ExistingEvergreenLibrary"
            }
            else {
                $script:ExistingPath = "/tmp/ExistingEvergreenLibrary"
            }
            New-Item -Path $script:ExistingPath -ItemType "Directory" -Force | Out-Null
        }

        AfterAll {
            Remove-Item -Path $script:ExistingPath -Recurse -Force -ErrorAction "SilentlyContinue"
        }

        It "Should handle existing directory" {
            { New-EvergreenLibrary -Path $script:ExistingPath } | Should -Not -Throw
        }
    }
}
