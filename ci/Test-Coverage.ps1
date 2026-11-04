function Test-Coverage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.String] $ReportPath,

        [System.String] $BaselinePath = (Join-Path $PSScriptRoot "..\.rules\CoverageBaseline.json"),

        [Parameter(Mandatory)]
        [System.String] $BaseRef
    )

    $ErrorActionPreference = "Stop"
    $Baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
    if ($Baseline.Total -notmatch '^\d+$' -or $Baseline.Covered -notmatch '^\d+$' -or
        $null -eq $Baseline.CriticalPercent -or $null -eq $Baseline.CriticalFiles -or
        $Baseline.Total -le 0 -or $Baseline.Covered -lt 0 -or $Baseline.Covered -gt $Baseline.Total -or
        $Baseline.CriticalPercent -lt 0 -or $Baseline.CriticalPercent -gt 100 -or
        @($Baseline.CriticalFiles).Count -eq 0) {
        throw "Invalid coverage baseline."
    }
    $Document = [System.Xml.XmlDocument]::new()
    $Document.XmlResolver = $null
    $Document.Load((Resolve-Path -LiteralPath $ReportPath).Path)
    $Counters = $Document.SelectNodes("/report/counter[@type='INSTRUCTION']")
    if ($Counters.Count -ne 1 -or $Counters[0].covered -notmatch '^\d+$' -or $Counters[0].missed -notmatch '^\d+$') {
        throw "Coverage report has no valid command counter."
    }
    $Counter = $Counters[0]
    $Covered = [long]$Counter.covered
    $Total = $Covered + [long]$Counter.missed
    if ($Total -le 0) {
        throw "Coverage report contains no analyzed commands."
    }
    $Failures = @()
    Write-Information -MessageData ("Command coverage: {0}/{1} ({2:P2}); baseline: {3}/{4}." -f $Covered, $Total, ($Covered / $Total), $Baseline.Covered, $Baseline.Total) -InformationAction Continue
    if ([decimal]$Covered * $Baseline.Total -lt [decimal]$Baseline.Covered * $Total) {
        $Failures += "Overall command coverage regressed."
    }
    $ChangedFiles = @(git diff --name-only --diff-filter=ACMR $BaseRef HEAD -- Evergreen)
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot determine changed files relative to '$BaseRef'."
    }
    foreach ($File in $ChangedFiles | Where-Object { $_ -in $Baseline.CriticalFiles }) {
        $Counters = @($Document.report.package | ForEach-Object {
            $Package = $_
            foreach ($Source in $Package.sourcefile) {
                $ModuleName = ($Package.name -split "/")[0]
                if ("$ModuleName/$($Source.name)" -ceq $File) {
                    $Source.counter | Where-Object type -eq "INSTRUCTION"
                }
            }
        })
        if ($Counters.Count -ne 1 -or $Counters[0].covered -notmatch '^\d+$' -or $Counters[0].missed -notmatch '^\d+$') {
            $Failures += "Missing or ambiguous command coverage for changed critical file '$File'."
            continue
        }
        $FileCovered = [long]$Counters[0].covered
        $FileTotal = $FileCovered + [long]$Counters[0].missed
        if ($FileTotal -le 0 -or [decimal]$FileCovered * 100 -lt [decimal]$Baseline.CriticalPercent * $FileTotal) {
            $Failures += "Changed critical file '$File' has $FileCovered/$FileTotal commands covered; requires $($Baseline.CriticalPercent)%."
        }
    }
    if ($Failures.Count) {
        throw ($Failures -join "`n")
    }
}
