[CmdletBinding()]
param (
    [System.String] $OutputPath = (Join-Path $PSScriptRoot "..\tests\Results\analysis.sarif")
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Tools = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "ValidationTools.psd1")
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer | Where-Object Version -eq $Tools.PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -RequiredVersion $Tools.PSScriptAnalyzer -Repository PSGallery -Scope CurrentUser -Force
}
Import-Module -Name PSScriptAnalyzer -RequiredVersion $Tools.PSScriptAnalyzer -Force
Push-Location -LiteralPath $Root
try {
    $Findings = @(Invoke-ScriptAnalyzer -Path (Join-Path $Root "Evergreen") -Recurse -Settings (Join-Path $Root ".rules\PSScriptAnalyzerSettings.psd1") -ErrorAction Stop)
    $Results = @($Findings | ForEach-Object {
        $RelativePath = $_.ScriptPath.Substring($Root.Length + 1).Replace("\", "/")
        @{
            ruleId = $_.RuleName
            level = if ($_.Severity -eq "Error") { "error" } else { "warning" }
            message = @{ text = $_.Message }
            locations = @(@{
                physicalLocation = @{
                    artifactLocation = @{ uri = $RelativePath }
                    region = @{ startLine = [Math]::Max(1, $_.Line); startColumn = [Math]::Max(1, $_.Column) }
                }
            })
        }
    })
    $Sarif = @{
        '$schema' = "https://json.schemastore.org/sarif-2.1.0.json"
        version = "2.1.0"
        runs = @(@{ tool = @{ driver = @{ name = "PSScriptAnalyzer"; version = $Tools.PSScriptAnalyzer } }; results = $Results })
    }
    $null = New-Item -Path (Split-Path $OutputPath -Parent) -ItemType Directory -Force
    $Sarif | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    if ($Findings.Count) {
        $Findings | Format-Table ScriptName, Line, RuleName, Severity, Message -Wrap | Out-Host
        throw "PSScriptAnalyzer reported $($Findings.Count) blocking Errors/Warnings."
    }
}
finally {
    Pop-Location
}
