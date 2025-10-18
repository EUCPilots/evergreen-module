<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
param ()

BeforeDiscovery {
    # Get details for Microsoft Edge
    $Installers = Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Channel -eq "Stable" }
}

BeforeAll {
}

Describe -Tag "Save" -Name "Save-EvergreenApp" -ForEach $Installers {
    BeforeAll {
        # Renaming the automatic $_ variable to $application to make it easier to work with
        $installer = $_

        # Create download path
        if ($env:Temp) {
            $Path = Join-Path -Path $env:Temp -ChildPath "Downloads"
        }
        elseif ($env:TMPDIR) {
            $Path = Join-Path -Path $env:TMPDIR -ChildPath "Downloads"
        }
        elseif ($env:RUNNER_TEMP) {
            $Path = Join-Path -Path $env:RUNNER_TEMP -ChildPath "Downloads"
        }
        New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
    }

    # Test that Save-EvergreenApp accepts the object and saves the file
    Context "Validate Save-EvergreenApp works with <installer.Architecture>." {
        It "Save-EvergreenApp should not throw with Path" {
            $params = @{
                InputObject = $installer
                Path        = $Path
                UserAgent   = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
                Force       = $true
                NoProgress  = $true
            }
            { Save-EvergreenApp @params } | Should -Not -Throw
        }

        # Test that the file downloaded into the path: "$Path/Stable/Enterprise/<version>/x64/MicrosoftEdgeEnterpriseX64.msi"
        It "Should save in the right path" {
            $File = [System.IO.Path]::Combine($Path, $installer.Channel, $installer.Release, $installer.Version, $installer.Architecture, $(Split-Path -Path $installer.URI -Leaf))
            Test-Path -Path $File -PathType "Leaf" | Should -Be $True
        }

        It "Save-EvergreenApp should not throw with CustomPath" {
            $params = @{
                InputObject = $installer
                CustomPath  = $Path
                UserAgent   = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
                Force       = $true
                NoProgress  = $true
            }
            { Save-EvergreenApp @params } | Should -Not -Throw
        }
    }
}
