<#
    .SYNOPSIS
        Main Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
param ()

BeforeDiscovery {
    $ModulePath = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "Evergreen")
    $ManifestPath = [System.IO.Path]::Combine($ModulePath, "Evergreen.psd1")

    # TestCases are splatted to the script so we need hashtables
    $Scripts = Get-ChildItem -Path $ModulePath -Recurse -Include *.ps1, *.psm1
    $TestCase = $Scripts | ForEach-Object { @{file = $_ } }

    # Find module scripts to create the test cases
    $Scripts = Get-ChildItem -Path $ModulePath -Recurse -Include *.ps1
    $TestCase = $Scripts | ForEach-Object { @{file = $_ } }
}

BeforeAll {
    $ModulePath = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "Evergreen")
    $ManifestPath = [System.IO.Path]::Combine($ModulePath, "Evergreen.psd1")
}

Describe "General project validation" {
    It "Script <file.Name> should exist" -TestCases $TestCase {
        param ($file)
        $file.FullName | Should -Exist
    }

    It "Script <file.Name> should be valid PowerShell" -TestCases $TestCase {
        param ($file)
        $contents = Get-Content -Path $file.FullName -ErrorAction "Stop"
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should -Be 0
    }
}

Describe "Module Function validation" {
    It "Script <file.Name> should only contain one function" -TestCases $TestCase {
        param ($file)
        $contents = Get-Content -Path $file.FullName -ErrorAction "Stop"
        $describes = [Management.Automation.Language.Parser]::ParseInput($contents, [ref]$null, [ref]$null)
        $test = $describes.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $test.Count | Should -Be 1
    }

    It "Script <file.Name> should match function name" -TestCases $TestCase {
        param ($file)
        $contents = Get-Content -Path $file.FullName -ErrorAction "Stop"
        $describes = [Management.Automation.Language.Parser]::ParseInput($contents, [ref]$null, [ref]$null)
        $test = $describes.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $test[0].name | Should -Be $file.basename
    }
}

# Test module and manifest
Describe "Module Metadata validation" {
    It "Script fileinfo should be OK" {
        { Test-ModuleManifest -Path $ManifestPath -ErrorAction "Stop" } | Should -Not -Throw
    }

    It "Import module should be OK" {
        { Import-Module $ModulePath -Force -ErrorAction "Stop" } | Should -Not -Throw
    }
}
