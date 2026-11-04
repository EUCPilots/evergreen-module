[CmdletBinding()]
param (
    [System.Management.Automation.SwitchParameter] $IncludeIntegration,

    [System.Management.Automation.SwitchParameter] $CollectCoverage,

    [System.String] $OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "Results")
)

$ErrorActionPreference = "Stop"
$OriginalWorkspace = $env:GITHUB_WORKSPACE
$OriginalRunnerTemp = $env:RUNNER_TEMP
$OriginalAppsPath = $env:EVERGREEN_APPS_PATH
$OriginalOffline = $env:EVERGREEN_TEST_OFFLINE
$OriginalTemp = $env:TEMP
$OriginalTmp = $env:TMP
$OriginalTmpDir = $env:TMPDIR
$TestRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Evergreen-CI-$([System.Guid]::NewGuid().ToString('N'))"

try {
    $env:GITHUB_WORKSPACE = Split-Path -Path $PSScriptRoot -Parent
    $env:RUNNER_TEMP = $TestRoot
    $env:EVERGREEN_APPS_PATH = Join-Path -Path $TestRoot -ChildPath "AppsCache"
    $env:EVERGREEN_TEST_OFFLINE = (-not $IncludeIntegration).ToString().ToLowerInvariant()
    $null = New-Item -Path $TestRoot -ItemType Directory
    $env:TEMP = $TestRoot
    $env:TMP = $TestRoot
    $env:TMPDIR = $TestRoot
    $null = New-Item -Path $OutputPath -ItemType Directory -Force

    & (Join-Path -Path $PSScriptRoot -ChildPath "Install-Pester.ps1")
    $Tools = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "..\ci\ValidationTools.psd1")
    Import-Module -Name Pester -RequiredVersion $Tools.Pester -Force
    Import-Module -Name (Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "Evergreen") -Force
    if ($IncludeIntegration) {
        Update-Evergreen -Verbose
    }

    $Config = [PesterConfiguration]::Default
    $Config.Run.Path = $PSScriptRoot
    $Config.Run.PassThru = $true
    if (-not $IncludeIntegration) {
        $Config.Filter.ExcludeTag = @("Integration")
        # These suites discover applications from the downloaded companion repository.
        $Config.Run.ExcludePath = @(
            "Public\Find-EvergreenApp.Tests.ps1"
            "Public\Export-EvergreenManifest.Tests.ps1"
            "Public\Get-EvergreenApp.Tests.ps1"
            "Public\Test-EvergreenLibrary.Tests.ps1"
            "Public\Update-Evergreen.Tests.ps1"
        ) | ForEach-Object { Join-Path -Path $PSScriptRoot -ChildPath $_ }
    }
    $Config.CodeCoverage.Enabled = $IncludeIntegration.IsPresent -or $CollectCoverage.IsPresent
    $Config.CodeCoverage.Path = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "Evergreen"
    $Config.CodeCoverage.OutputFormat = "JaCoCo"
    $Config.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
    $Config.Output.Verbosity = "Detailed"
    $Config.TestResult.Enabled = $true
    $Config.TestResult.OutputFormat = "NUnitXml"
    $Config.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
    $Result = Invoke-Pester -Configuration $Config
    if ($Result.Result -ne "Passed" -or $Result.PassedCount -eq 0) {
        throw "Pester validation failed: $($Result.FailedCount) failed tests, $($Result.FailedContainersCount) failed containers, $($Result.PassedCount) passed tests."
    }
    if (-not $IncludeIntegration) {
        $AllowedSkips = @(
            "Expand-CabArchive.Validate Shell extraction and expand.exe fallback.*"
            "Expand-CabArchive.Validate native Windows CAB extraction.*"
            "Expand-CabArchive.Validate Expand-CabArchive on Windows.*"
            "Expand-CabArchive.Validate Expand-CabArchive on non-Windows.*"
            "Resolve-DnsNameWrapper.Windows resolver output.*"
            "Test-IsWindows.Validate Test-IsWindows basic functionality.Should return true on Windows platform"
            "Test-IsWindows.Validate Test-IsWindows basic functionality.Should return true for Windows PowerShell Desktop edition"
            "Test-IsWindows.Validate Test-IsWindows basic functionality.Should return false on non-Windows platform"
            "Invoke-EvergreenRestMethod.Ensure Invoke-EvergreenRestMethod works as expected.Passes insecure redirect opt-in to PowerShell Core when supported"
            "Repository helper *"
        )
        foreach ($Test in $Result.Tests | Where-Object { $_.Result -eq "Skipped" }) {
            $TestName = $Test.ExpandedPath
            if (-not @($AllowedSkips | Where-Object { $TestName -like $_ }).Count) {
                throw "Unexpected skipped test: $TestName"
            }
        }
        if ($Result.InconclusiveCount -gt 0) {
            throw "Deterministic tests must not be inconclusive."
        }
    }
    foreach ($Suite in "Private", "Public", "Shared") {
        $SuitePath = Join-Path -Path $PSScriptRoot -ChildPath $Suite
        $PassedTests = @($Result.Tests | Where-Object {
            $_.Result -eq "Passed" -and $_.ScriptBlock.File.StartsWith($SuitePath, [System.StringComparison]::OrdinalIgnoreCase)
        })
        if ($PassedTests.Count -eq 0) {
            throw "Required suite '$Suite' did not execute any passing tests."
        }
    }
}
finally {
    Remove-Module -Name Evergreen -Force -ErrorAction SilentlyContinue
    $env:GITHUB_WORKSPACE = $OriginalWorkspace
    $env:RUNNER_TEMP = $OriginalRunnerTemp
    $env:EVERGREEN_APPS_PATH = $OriginalAppsPath
    $env:EVERGREEN_TEST_OFFLINE = $OriginalOffline
    $env:TEMP = $OriginalTemp
    $env:TMP = $OriginalTmp
    $env:TMPDIR = $OriginalTmpDir
    if (Test-Path -LiteralPath $TestRoot) {
        Remove-Item -LiteralPath $TestRoot -Recurse -Force
    }
}
