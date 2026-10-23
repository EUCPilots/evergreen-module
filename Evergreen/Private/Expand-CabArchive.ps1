function Expand-CabArchive {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if (Test-Path -Path $_ -PathType "Leaf") { $true } else { throw "Cannot find path $_." } })]
        [System.String] $Path,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if (Test-Path -Path $(Split-Path -Path $_ -Parent) -PathType "Container") { $true } else { throw "Cannot find path $(Split-Path -Path $_ -Parent)." } })]
        [System.String] $DestinationPath
    )

    if (Test-IsWindows) {
        $StageRoot = Join-Path -Path $DestinationPath -ChildPath ".Expand-CabArchive-$([System.Guid]::NewGuid().ToString())"
        $ShellStage = Join-Path -Path $StageRoot -ChildPath "Shell"
        $FallbackStage = Join-Path -Path $StageRoot -ChildPath "Expand"
        $ExpectedNames = @()

        try {
            $null = New-Item -Path $DestinationPath -ItemType "Directory" -Force
            $ShellSucceeded = $false
            $StagePath = $null
            try {
                $Shell = New-Object -ComObject "Shell.Application"
                $SourceCab = $Shell.NameSpace($Path)
                if ($null -eq $SourceCab) {
                    throw "Shell.Application could not open CAB file '$Path'."
                }
                $CabItems = @($SourceCab.Items())
                $ExpectedNames = @($CabItems | Where-Object { $null -ne $_ } | ForEach-Object { [System.String]$_.Name } | Where-Object { -not [System.String]::IsNullOrWhiteSpace($_) })
                if ($ExpectedNames.Count -eq 0) {
                    throw "Shell.Application found no items in CAB file '$Path'."
                }

                foreach ($Name in $ExpectedNames) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): CAB file contains: '$Name'."
                }

                $null = New-Item -Path $ShellStage -ItemType "Directory" -Force
                $DestinationFolder = $Shell.NameSpace($ShellStage)
                if ($null -eq $DestinationFolder) {
                    throw "Shell.Application could not open staging directory '$ShellStage'."
                }

                Write-Verbose -Message "$($MyInvocation.MyCommand): Expanding CAB file '$Path' to staging directory '$ShellStage'."
                $DestinationFolder.CopyHere($SourceCab.Items(), 0x1014)

                $Timer = [System.Diagnostics.Stopwatch]::StartNew()
                do {
                    $MissingNames = @($ExpectedNames | Where-Object {
                            -not (Test-Path -LiteralPath (Join-Path -Path $ShellStage -ChildPath $_) -PathType "Leaf")
                        })
                    if ($MissingNames.Count -eq 0) {
                        break
                    }
                    Start-Sleep -Milliseconds 100
                } while ($Timer.Elapsed.TotalSeconds -lt 30)
                $Timer.Stop()

                if ($MissingNames.Count -gt 0) {
                    throw "Shell.Application.CopyHere did not extract all CAB items before the timeout. Missing: $($MissingNames -join ', ')."
                }

                $ShellSucceeded = $true
                $StagePath = $ShellStage
            }
            catch {
                Write-Verbose -Message "$($MyInvocation.MyCommand): $($_.Exception.Message)"
                Write-Verbose -Message "$($MyInvocation.MyCommand): Falling back to expand.exe."
                $ShellError = $_.Exception.Message
            }

            if (-not $ShellSucceeded) {
                $ExpandExe = Join-Path -Path $Env:SystemRoot -ChildPath "System32\expand.exe"
                if (-not (Test-Path -LiteralPath $ExpandExe -PathType "Leaf")) {
                    throw "$($MyInvocation.MyCommand): Shell extraction failed: $ShellError expand.exe was not found at '$ExpandExe'."
                }

                try {
                    $null = New-Item -Path $FallbackStage -ItemType "Directory" -Force
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Expanding CAB file '$Path' with expand.exe to staging directory '$FallbackStage'."
                    $LASTEXITCODE = 0
                    & $ExpandExe $Path $FallbackStage | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        throw "expand.exe exited with code $LASTEXITCODE."
                    }
                }
                catch {
                    throw "$($MyInvocation.MyCommand): Shell extraction failed: $ShellError expand.exe fallback failed: $($_.Exception.Message)"
                }

                $ExtractedFiles = @(Get-ChildItem -LiteralPath $FallbackStage -File -Recurse)
                if ($ExtractedFiles.Count -eq 0) {
                    throw "$($MyInvocation.MyCommand): Shell extraction failed: $ShellError expand.exe produced no files."
                }

                if ($ExpectedNames.Count -gt 0) {
                    $ExtractedNames = @($ExtractedFiles | Select-Object -ExpandProperty "Name")
                    $MissingNames = @($ExpectedNames | Where-Object { $_ -notin $ExtractedNames })
                    if ($MissingNames.Count -gt 0) {
                        throw "$($MyInvocation.MyCommand): expand.exe did not extract all CAB items. Missing: $($MissingNames -join ', ')."
                    }
                }
                $StagePath = $FallbackStage
            }

            $ExtractedFiles = @(Get-ChildItem -LiteralPath $StagePath -File -Recurse)

            $Items = @()
            foreach ($File in $ExtractedFiles) {
                $RelativePath = $File.FullName.Substring($StagePath.Length).TrimStart([System.Char[]]@('\', '/'))
                $DestinationFile = Join-Path -Path $DestinationPath -ChildPath $RelativePath
                $DestinationParent = Split-Path -Path $DestinationFile -Parent
                $null = New-Item -Path $DestinationParent -ItemType "Directory" -Force
                Move-Item -LiteralPath $File.FullName -Destination $DestinationFile -Force -ErrorAction "Stop"
                $Items += $DestinationFile
                Write-Verbose -Message "$($MyInvocation.MyCommand): Expanded item '$DestinationFile' to '$DestinationPath'."
            }

            return $Items
        }
        finally {
            Remove-Item -LiteralPath $StageRoot -Recurse -Force -ErrorAction "SilentlyContinue"
        }
    }
    else {
        # Future update for cross-platform
        throw "$($MyInvocation.MyCommand): Expand-CabArchive is only supported on Windows."
    }
}
