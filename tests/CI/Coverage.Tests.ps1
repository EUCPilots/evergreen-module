BeforeAll {
    . (Join-Path $PSScriptRoot "..\..\ci\Test-Coverage.ps1")
}

Describe "Coverage release gate" {
    BeforeEach {
        $Report = Join-Path $TestDrive "coverage.xml"
        $Baseline = Join-Path $TestDrive "baseline.json"
        '{"Covered":8,"Total":10,"CriticalPercent":90,"CriticalFiles":["Evergreen/Public/Save-EvergreenApp.ps1"]}' |
            Set-Content -LiteralPath $Baseline
        '<report><package name="Evergreen/Public"><sourcefile name="Public/Save-EvergreenApp.ps1"><counter type="INSTRUCTION" covered="9" missed="1"/></sourcefile></package><counter type="INSTRUCTION" covered="8" missed="2"/></report>' |
            Set-Content -LiteralPath $Report
        Mock git {
            $global:LASTEXITCODE = 0
            "Evergreen/Public/Save-EvergreenApp.ps1"
        }
    }

    It "Accepts equality at both thresholds" {
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Not -Throw
    }

    It "Rejects an overall regression without rounding it away" {
        (Get-Content -LiteralPath $Report -Raw).Replace('covered="8" missed="2"', 'covered="79999" missed="20001"') |
            Set-Content -LiteralPath $Report
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Throw "*regressed*"
    }

    It "Rejects a changed critical file below 90 percent" {
        (Get-Content -LiteralPath $Report -Raw).Replace('covered="9" missed="1"', 'covered="89" missed="11"') |
            Set-Content -LiteralPath $Report
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Throw "*requires 90%*"
    }

    It "Does not impose the changed-file target on unchanged critical files" {
        Mock git { $global:LASTEXITCODE = 0 }
        (Get-Content -LiteralPath $Report -Raw).Replace('covered="9" missed="1"', 'covered="0" missed="10"') |
            Set-Content -LiteralPath $Report
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Not -Throw
    }

    It "Rejects missing critical-file counters" {
        (Get-Content -LiteralPath $Report -Raw).Replace('Save-EvergreenApp.ps1', 'Other.ps1') |
            Set-Content -LiteralPath $Report
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Throw "*Missing or ambiguous*"
    }

    It "Rejects duplicate critical-file counters" {
        $Text = Get-Content -LiteralPath $Report -Raw
        $Text.Replace('</sourcefile>', '<counter type="INSTRUCTION" covered="9" missed="1"/></sourcefile>') |
            Set-Content -LiteralPath $Report
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Throw "*Missing or ambiguous*"
    }

    It "Rejects empty or malformed reports: <ReportText>" -ForEach @(
        @{ ReportText = '<report/>' }
        @{ ReportText = '<report><counter type="INSTRUCTION" covered="0" missed="0"/></report>' }
        @{ ReportText = '<report><counter type="INSTRUCTION" covered="-1" missed="2"/></report>' }
        @{ ReportText = 'invalid xml' }
    ) {
        Set-Content -LiteralPath $Report -Value $ReportText
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Throw
    }

    It "Rejects an invalid baseline" {
        '{"Covered":8,"Total":0}' | Set-Content -LiteralPath $Baseline
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef HEAD } | Should -Throw "*Invalid coverage baseline*"
    }

    It "Rejects an unresolved comparison ref" {
        Mock git { $global:LASTEXITCODE = 128 }
        { Test-Coverage -ReportPath $Report -BaselinePath $Baseline -BaseRef missing } | Should -Throw "*Cannot determine changed files*"
    }
}
