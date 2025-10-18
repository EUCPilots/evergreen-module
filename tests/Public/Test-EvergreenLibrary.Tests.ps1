<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
}

BeforeAll {
}

Describe -Tag "Library" -Name "Test Evergreen Library functions" {
    BeforeAll {
        if ($env:Temp) {
            $Path = $env:Temp
        }
        elseif ($env:TMPDIR) {
            $Path = $env:TMPDIR
        }
        elseif ($env:RUNNER_TEMP) {
            $Path = $env:RUNNER_TEMP
        }
    }

    Context "Test 'New-EvergreenLibrary'" {
        It "Does not throw when creating a new new Evergreen Library" {
            { New-EvergreenLibrary -Path "$Path\EvergreenLibrary" -Name "TestLibrary" } | Should -Not -Throw
        }

        It "Creates a new Evergreen Library OK" {
            Test-Path -Path "$Path\EvergreenLibrary\EvergreenLibrary.json" | Should -BeTrue
        }

        It "Sets the library name OK" {
            (Get-Content -Path "$Path\EvergreenLibrary\EvergreenLibrary.json" | ConvertFrom-Json).Name | Should -BeExactly "TestLibrary"
        }
    }

    Context "Test 'Start-EvergreenLibraryUpdate'" {
        BeforeAll {
            $params = @{
                Path        = "$env:GITHUB_WORKSPACE\tests\EvergreenLibrary.json"
                Destination = "$Path\EvergreenLibrary\EvergreenLibrary.json"
                Force       = $True
                Confirm     = $False
            }
            Copy-Item @params
        }

        It "Update an Evergreen library" {
            { Start-EvergreenLibraryUpdate -Path "$Path\EvergreenLibrary" } | Should -Not -Throw
        }
    }

    Context "Test 'Get-EvergreenLibrary' works" {
        BeforeAll {
            $params = @{
                Path        = "$env:GITHUB_WORKSPACE\tests\EvergreenLibrary.json"
                Destination = "$Path\EvergreenLibrary\EvergreenLibrary.json"
                Force       = $True
                Confirm      = $False
            }
            Copy-Item @params
        }

        It "Returns details of the library" {
            Get-EvergreenLibrary -Path "$Path\EvergreenLibrary" | Should -BeOfType [System.Object]
        }

        It "Does not throw" {
            { Get-EvergreenLibrary -Path "$Path\EvergreenLibrary" } | Should -Not -Throw
        }
    }

    Context "Test 'Get-EvergreenLibraryApp' works" {
        It "Does not throw when getting details for MicrosoftTeams" {
            { Get-EvergreenLibrary -Path "$Path\EvergreenLibrary" | Get-EvergreenLibraryApp -Name "MicrosoftTeams" } | Should -Not -Throw
        }

        It "Return details from the library for MicrosoftTeams" {
            Get-EvergreenLibrary -Path "$Path\EvergreenLibrary" | Get-EvergreenLibraryApp -Name "MicrosoftTeams" | Should -BeOfType [System.Object]
        }
    }

    Context "Test 'Get-EvergreenLibraryApp' fails" {
        BeforeAll {
            $Object = [PSCustomObject]@{
                Name = "Value"
            }
        }

        It "Throws when passed an invalid library object" {
            { $Object | Get-EvergreenLibraryApp -Name "MicrosoftTeams" } | Should -Throw
        }

        It "Throws when an application that is not in the library is passed" {
            { Get-EvergreenLibrary -Path "$Path\EvergreenLibrary" | Get-EvergreenLibraryApp -Name "MicrosoftEdge" } | Should -Throw
        }
    }

    Context "Test 'Get-EvergreenLibrary' fails" {
        BeforeAll {
            $params = @{
                FilePath = "$Path\EvergreenLibrary\EvergreenLibrary.json"
                Force    = $True
                Confirm   = $False
            }
            "nonsense" | Out-File @params
        }

        It "Does throw" {
            { Get-EvergreenLibrary -Path "$Path\EvergreenLibrary" } | Should -Throw
        }
    }
}
