[CmdletBinding()]
param ()

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Tools = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "ValidationTools.psd1")
if (-not (Get-Module -ListAvailable -Name powershell-yaml | Where-Object Version -eq $Tools.PowerShellYaml)) {
    Install-Module -Name powershell-yaml -RequiredVersion $Tools.PowerShellYaml -Repository PSGallery -Scope CurrentUser -Force
}
Import-Module -Name powershell-yaml -RequiredVersion $Tools.PowerShellYaml -Force
$ToolPath = Join-Path ([System.IO.Path]::GetTempPath()) "Evergreen-actionlint-$([System.Guid]::NewGuid().ToString('N'))"
$null = New-Item -Path $ToolPath -ItemType Directory
try {
    $Version = $Tools.Actionlint
    $ArchiveName = "actionlint_${Version}_windows_amd64.zip"
    $ArchivePath = Join-Path $ToolPath $ArchiveName
    $ChecksumsPath = Join-Path $ToolPath "checksums.txt"
    $ReleaseUri = "https://github.com/rhysd/actionlint/releases/download/v$Version"
    Invoke-WebRequest -Uri "$ReleaseUri/$ArchiveName" -OutFile $ArchivePath
    Invoke-WebRequest -Uri "$ReleaseUri/actionlint_${Version}_checksums.txt" -OutFile $ChecksumsPath
    $ExpectedHash = @(Get-Content -LiteralPath $ChecksumsPath | Where-Object { $_ -match "^[a-fA-F0-9]{64}\s+\*?$([regex]::Escape($ArchiveName))$" })
    if ($ExpectedHash.Count -ne 1 -or (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ine ($ExpectedHash[0] -split '\s+')[0]) {
        throw "actionlint archive checksum verification failed."
    }
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $ToolPath
    $Workflows = @(Get-ChildItem -LiteralPath (Join-Path $Root ".github\workflows") -File | Where-Object Extension -in ".yml", ".yaml")
    if ($Workflows.Count -eq 0) { throw "No workflows found." }
    $Arguments = ($Workflows | ForEach-Object { '"{0}"' -f $_.FullName }) -join " "
    $Process = Start-Process -FilePath (Join-Path $ToolPath "actionlint.exe") -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
    if ($Process.ExitCode -ne 0) { throw "actionlint rejected the workflows." }
    foreach ($File in $Workflows) {
        $Workflow = Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Yaml
        foreach ($Job in $Workflow.jobs.Values) {
            foreach ($Step in $Job.steps) {
                if (-not $Step.run) { continue }
                $Shell = $Step.shell
                if (-not $Shell) { $Shell = $Job.defaults.run.shell }
                if (-not $Shell) { $Shell = $Workflow.defaults.run.shell }
                if ($Shell -and $Shell -notmatch 'powershell|pwsh|^\$\{\{') { continue }
                if (-not $Shell -and $Job.'runs-on' -notmatch 'windows') { continue }
                $Script = $Step.run -replace '\$\{\{.*?\}\}', '0'
                $Tokens = $null
                $ParseErrors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseInput($Script, [ref]$Tokens, [ref]$ParseErrors)
                if ($ParseErrors.Count) {
                    throw "Invalid embedded PowerShell in '$($File.Name)' step '$($Step.name)': $($ParseErrors.Message -join '; ')"
                }
            }
        }
    }
    foreach ($File in Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -File | Where-Object Extension -in ".ps1", ".psm1", ".psd1") {
        $Tokens = $null
        $ParseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$Tokens, [ref]$ParseErrors)
        if ($ParseErrors.Count) { throw "Invalid CI script '$($File.Name)': $($ParseErrors.Message -join '; ')" }
    }
}
finally {
    for ($Attempt = 1; $Attempt -le 5; $Attempt++) {
        try {
            Remove-Item -LiteralPath $ToolPath -Recurse -Force
            break
        }
        catch [System.IO.IOException], [System.UnauthorizedAccessException] {
            if ($Attempt -eq 5) { throw }
            Write-Warning "Workflow validator cleanup is waiting for a file lock: $($_.Exception.Message)"
            Start-Sleep -Seconds 1
        }
    }
}
