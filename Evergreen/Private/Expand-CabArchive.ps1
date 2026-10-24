function Expand-CabArchive {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath
    )

    if (-not (Test-IsWindows)) {
        throw "$($MyInvocation.MyCommand): Expand-CabArchive is only supported on Windows."
    }

    if (-not (Test-Path -LiteralPath $Path -PathType "Leaf")) {
        throw "Cannot find CAB file '$Path'."
    }
    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    try {
        $DestinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        $DestinationPath = [System.IO.Path]::GetFullPath($DestinationPath)
    }
    catch {
        throw "Invalid destination path '$DestinationPath': $($_.Exception.Message)"
    }
    if (Test-Path -LiteralPath $DestinationPath -PathType "Leaf") {
        throw "Destination path '$DestinationPath' is a file; a directory path is required."
    }
    $DestinationParent = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -LiteralPath $DestinationParent -PathType "Container")) {
        throw "Cannot find destination parent directory '$DestinationParent'."
    }
    if (Test-Path -LiteralPath $DestinationPath -PathType "Container") {
        $DestinationItem = Get-Item -LiteralPath $DestinationPath -Force
        if ($DestinationItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "Destination directory '$DestinationPath' cannot be a reparse point."
        }
    }

    $StageRoot = Join-Path -Path $DestinationPath -ChildPath ".Expand-CabArchive-$([System.Guid]::NewGuid().ToString())"
    $ShellStage = Join-Path -Path $StageRoot -ChildPath "Shell"
    $FallbackStage = Join-Path -Path $StageRoot -ChildPath "Expand"
    $BackupStage = Join-Path -Path $StageRoot -ChildPath "Backup"
    $ExpectedFiles = @()
    $KeepStage = $false
    $UnsafeCabEntryError = $null

    $NormalizeRelativePath = {
        param ([System.String] $Name)

        $RelativeName = $Name.Replace("/", "\")
        if ([System.IO.Path]::IsPathRooted($RelativeName) -or $RelativeName -match "^[A-Za-z]:") {
            throw "CAB item path '$Name' is rooted."
        }
        $Segments = @($RelativeName -split "\\")
        if ($Segments.Count -eq 0 -or @($Segments | Where-Object { [System.String]::IsNullOrWhiteSpace($_) -or $_ -eq "." -or $_ -eq ".." }).Count -gt 0) {
            throw "CAB item path '$Name' contains an invalid path segment."
        }
        $InvalidCharacters = [System.IO.Path]::GetInvalidFileNameChars()
        foreach ($Segment in $Segments) {
            if ($Segment.IndexOfAny($InvalidCharacters) -ge 0) {
                throw "CAB item path '$Name' contains an invalid file name."
            }
        }
        return ($Segments -join "\")
    }

    $GetMissingExpectedFiles = {
        param ($Expected, $Files, $Root)

        $FilePaths = New-Object -TypeName System.Collections.ArrayList
        foreach ($File in $Files) {
            $null = $FilePaths.Add($File.FullName.Substring($Root.Length).TrimStart([System.Char[]]@('\', '/')))
        }
        $Missing = @()
        foreach ($ExpectedFile in $Expected) {
            $MatchedIndex = -1
            for ($Index = 0; $Index -lt $FilePaths.Count; $Index++) {
                if ($ExpectedFile.RelativePath.Contains("\")) {
                    $MatchesExpected = $FilePaths[$Index] -ieq $ExpectedFile.RelativePath
                }
                else {
                    $MatchesExpected = (Split-Path -Path $FilePaths[$Index] -Leaf) -ieq $ExpectedFile.RelativePath
                }
                if ($MatchesExpected) {
                    $MatchedIndex = $Index
                    break
                }
            }
            if ($MatchedIndex -lt 0) {
                $Missing += $ExpectedFile.RelativePath
            }
            else {
                $FilePaths.RemoveAt($MatchedIndex)
            }
        }
        return $Missing
    }

    try {
        $null = New-Item -Path $DestinationPath -ItemType "Directory" -Force -ErrorAction "Stop"
        $ShellSucceeded = $false
        $StagePath = $null

        try {
            $Shell = New-Object -ComObject "Shell.Application"
            $SourceCab = $Shell.NameSpace($Path)
            if ($null -eq $SourceCab) {
                throw "Shell.Application could not open CAB file '$Path'."
            }
            $CabItems = @($SourceCab.Items())
            $ExpectedFiles = @()
            foreach ($CabItem in $CabItems) {
                if ($null -eq $CabItem -or $CabItem.IsFolder) {
                    continue
                }
                $ItemName = [System.String]$CabItem.Name
                if ([System.String]::IsNullOrWhiteSpace($ItemName)) {
                    continue
                }
                try {
                    $RelativePath = & $NormalizeRelativePath $ItemName
                }
                catch {
                    $UnsafeCabEntryError = $_.Exception.Message
                    throw
                }
                $ExpectedFiles += [PSCustomObject]@{ RelativePath = $RelativePath }
            }
            if ($ExpectedFiles.Count -eq 0) {
                throw "Shell.Application found no files in CAB file '$Path'."
            }

            foreach ($File in $ExpectedFiles) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): CAB file contains: '$($File.RelativePath)'."
            }

            $null = New-Item -Path $ShellStage -ItemType "Directory" -Force -ErrorAction "Stop"
            $DestinationFolder = $Shell.NameSpace($ShellStage)
            if ($null -eq $DestinationFolder) {
                throw "Shell.Application could not open staging directory '$ShellStage'."
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Expanding CAB file '$Path' to staging directory '$ShellStage'."
            $DestinationFolder.CopyHere($SourceCab.Items(), 0x1014)

            $Timer = [System.Diagnostics.Stopwatch]::StartNew()
            $PreviousSnapshot = $null
            $StableSnapshots = 0
            $MissingFiles = @($ExpectedFiles | ForEach-Object { $_.RelativePath })
            do {
                $ShellFiles = @(Get-ChildItem -LiteralPath $ShellStage -File -Recurse -Force -ErrorAction "Stop")
                $MissingFiles = @(& $GetMissingExpectedFiles $ExpectedFiles $ShellFiles $ShellStage)
                if ($MissingFiles.Count -eq 0) {
                    $Snapshot = @(
                        $ShellFiles |
                            ForEach-Object {
                                "$($_.FullName.Substring($ShellStage.Length).TrimStart([System.Char[]]@('\', '/'))):$($_.Length)"
                            } |
                            Sort-Object
                    ) -join "|"
                    if ($Snapshot -eq $PreviousSnapshot) {
                        $StableSnapshots++
                    }
                    else {
                        $PreviousSnapshot = $Snapshot
                        $StableSnapshots = 0
                    }
                    if ($StableSnapshots -ge 3) {
                        break
                    }
                }
                else {
                    $StableSnapshots = 0
                }
                Start-Sleep -Milliseconds 500
            } while ($Timer.Elapsed.TotalSeconds -lt 120)
            $Timer.Stop()

            if ($MissingFiles.Count -gt 0 -or $StableSnapshots -lt 3) {
                throw "Shell.Application.CopyHere did not finish extracting all CAB files before the timeout. Missing: $($MissingFiles -join ', ')."
            }

            $ShellSucceeded = $true
            $StagePath = $ShellStage
        }
        catch {
            Write-Verbose -Message "$($MyInvocation.MyCommand): $($_.Exception.Message)"
            Write-Verbose -Message "$($MyInvocation.MyCommand): Falling back to expand.exe."
            $ShellError = $_.Exception.Message
        }

        if ($null -ne $UnsafeCabEntryError) {
            throw "$($MyInvocation.MyCommand): Refusing to extract unsafe CAB entry: $UnsafeCabEntryError"
        }

        if (-not $ShellSucceeded) {
            $ExpandExe = Join-Path -Path $Env:SystemRoot -ChildPath "System32\expand.exe"
            if (-not (Test-Path -LiteralPath $ExpandExe -PathType "Leaf")) {
                throw "$($MyInvocation.MyCommand): Shell extraction failed: $ShellError expand.exe was not found at '$ExpandExe'."
            }

            try {
                $null = New-Item -Path $FallbackStage -ItemType "Directory" -Force -ErrorAction "Stop"
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

            $ExtractedFiles = @(Get-ChildItem -LiteralPath $FallbackStage -File -Recurse -Force -ErrorAction "Stop")
            if ($ExtractedFiles.Count -eq 0) {
                throw "$($MyInvocation.MyCommand): Shell extraction failed: $ShellError expand.exe produced no files."
            }
            if ($ExpectedFiles.Count -gt 0) {
                $MissingFiles = @(& $GetMissingExpectedFiles $ExpectedFiles $ExtractedFiles $FallbackStage)
                if ($MissingFiles.Count -gt 0) {
                    throw "$($MyInvocation.MyCommand): expand.exe did not extract all CAB files. Missing: $($MissingFiles -join ', ')."
                }
            }
            $StagePath = $FallbackStage
        }

        $StageEntries = @(Get-ChildItem -LiteralPath $StagePath -Force -Recurse -ErrorAction "Stop" | Sort-Object -Property "FullName")
        $ReparsePoints = @($StageEntries | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint })
        if ($ReparsePoints.Count -gt 0) {
            throw "$($MyInvocation.MyCommand): Extraction produced reparse points, which are not safe to promote."
        }
        $ExtractedFiles = @($StageEntries | Where-Object { -not $_.PSIsContainer })
        if ($ExtractedFiles.Count -eq 0) {
            throw "$($MyInvocation.MyCommand): Extraction produced no files."
        }

        $Promotions = @()
        $SeenTargets = @{}
        foreach ($File in $ExtractedFiles) {
            $RelativePath = $File.FullName.Substring($StagePath.Length).TrimStart([System.Char[]]@('\', '/'))
            $RelativePath = & $NormalizeRelativePath $RelativePath
            $DestinationFile = [System.IO.Path]::GetFullPath((Join-Path -Path $DestinationPath -ChildPath $RelativePath))
            $DestinationPrefix = $DestinationPath.TrimEnd([System.Char[]]@('\', '/')) + [System.IO.Path]::DirectorySeparatorChar
            if (-not $DestinationFile.StartsWith($DestinationPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "$($MyInvocation.MyCommand): Extracted path '$RelativePath' resolves outside destination '$DestinationPath'."
            }
            if ($SeenTargets.ContainsKey($DestinationFile)) {
                throw "$($MyInvocation.MyCommand): Multiple CAB entries resolve to '$DestinationFile'."
            }
            $SeenTargets[$DestinationFile] = $true

            $Promotions += [PSCustomObject]@{
                Source = $File.FullName
                Target = $DestinationFile
                RelativePath = $RelativePath
                Backup = Join-Path -Path $BackupStage -ChildPath $RelativePath
                HadBackup = $false
                Installed = $false
            }
        }

        $CreatedDirectories = @()
        $PromotionRecords = @()
        try {
            foreach ($Promotion in $Promotions) {
                $Parent = Split-Path -Path $Promotion.Target -Parent
                $MissingParents = @()
                $CurrentParent = $Parent
                while ($CurrentParent.StartsWith($DestinationPath, [System.StringComparison]::OrdinalIgnoreCase) -and
                    -not (Test-Path -LiteralPath $CurrentParent -PathType "Container")) {
                    $MissingParents += $CurrentParent
                    $CurrentParent = Split-Path -Path $CurrentParent -Parent
                }
                [array]::Reverse($MissingParents)
                foreach ($Directory in $MissingParents) {
                    if (Test-Path -LiteralPath $Directory -PathType "Leaf") {
                        throw "Cannot create destination directory '$Directory' because a file already exists there."
                    }
                    $null = New-Item -Path $Directory -ItemType "Directory" -ErrorAction "Stop"
                    $CreatedDirectories += $Directory
                }

                $CurrentParent = $Parent
                while ($CurrentParent.StartsWith($DestinationPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $DirectoryItem = Get-Item -LiteralPath $CurrentParent -Force -ErrorAction "Stop"
                    if ($DirectoryItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                        throw "Destination path '$CurrentParent' contains a reparse point."
                    }
                    if ($CurrentParent -ieq $DestinationPath) {
                        break
                    }
                    $CurrentParent = Split-Path -Path $CurrentParent -Parent
                }

                if (Test-Path -LiteralPath $Promotion.Target) {
                    if (-not (Test-Path -LiteralPath $Promotion.Target -PathType "Leaf")) {
                        throw "Cannot replace destination directory '$($Promotion.Target)' with an extracted file."
                    }
                    $null = New-Item -Path (Split-Path -Path $Promotion.Backup -Parent) -ItemType "Directory" -Force -ErrorAction "Stop"
                }

                $Record = [PSCustomObject]@{
                    Promotion = $Promotion
                    HadBackup = $false
                    Installed = $false
                }
                $PromotionRecords += $Record
                if (Test-Path -LiteralPath $Promotion.Target -PathType "Leaf") {
                    Move-Item -LiteralPath $Promotion.Target -Destination $Promotion.Backup -ErrorAction "Stop"
                    $Record.HadBackup = $true
                }
                Move-Item -LiteralPath $Promotion.Source -Destination $Promotion.Target -ErrorAction "Stop"
                $Record.Installed = $true
                Write-Verbose -Message "$($MyInvocation.MyCommand): Expanded item '$($Promotion.Target)' to '$DestinationPath'."
            }
        }
        catch {
            $PromotionError = $_.Exception.Message
            $RollbackErrors = @()
            [array]::Reverse($PromotionRecords)
            foreach ($Record in $PromotionRecords) {
                try {
                    if ($Record.Installed -and (Test-Path -LiteralPath $Record.Promotion.Target)) {
                        Remove-Item -LiteralPath $Record.Promotion.Target -Force -ErrorAction "Stop"
                    }
                    if ($Record.HadBackup -and (Test-Path -LiteralPath $Record.Promotion.Backup -PathType "Leaf")) {
                        Move-Item -LiteralPath $Record.Promotion.Backup -Destination $Record.Promotion.Target -ErrorAction "Stop"
                    }
                }
                catch {
                    $RollbackErrors += $_.Exception.Message
                }
            }
            [array]::Reverse($CreatedDirectories)
            foreach ($Directory in $CreatedDirectories) {
                try {
                    Remove-Item -LiteralPath $Directory -Force -ErrorAction "Stop"
                }
                catch {
                    $RollbackErrors += $_.Exception.Message
                }
            }
            if ($RollbackErrors.Count -gt 0) {
                $KeepStage = $true
                throw "$($MyInvocation.MyCommand): Promotion failed: $PromotionError Rollback was incomplete: $($RollbackErrors -join '; '). Backups/staging retained at '$StageRoot'."
            }
            throw "$($MyInvocation.MyCommand): Promotion failed; changes were rolled back: $PromotionError"
        }

        return @($Promotions | ForEach-Object { $_.Target })
    }
    finally {
        if (-not $KeepStage) {
            Remove-Item -LiteralPath $StageRoot -Recurse -Force -ErrorAction "SilentlyContinue"
        }
    }
}
