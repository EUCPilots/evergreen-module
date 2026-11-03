function Remove-EvergreenLibraryAppVersion {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify the path to the library.",
            ParameterSetName = "Path")]
        [ValidateNotNull()]
        [System.IO.FileInfo] $Path,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32] $Keep = 3,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Name
    )

    begin {
    }

    process {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Validating library path '$Path'. Keep: $Keep."
        if (-not (Test-Path -Path $Path -PathType "Container")) {
            $Msg = "Cannot use path $Path because it does not exist or is not a directory."
            throw [System.IO.DirectoryNotFoundException]::New($Msg)
        }

        $LibraryFile = Join-Path -Path $Path -ChildPath "EvergreenLibrary.json"
        if (-not (Test-Path -Path $LibraryFile -PathType "Leaf")) {
            $Msg = "$Path is not an Evergreen Library. Cannot find EvergreenLibrary.json. Create a library with New-EvergreenLibrary."
            throw [System.IO.FileNotFoundException]::New($Msg)
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand): Reading library manifest '$LibraryFile'."
        $Library = Get-Content -Path $LibraryFile -ErrorAction "Stop" | ConvertFrom-Json -ErrorAction "Stop"
        $LibraryRoot = [System.IO.Path]::GetFullPath($Path.FullName)
        $PathComparison = if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
            [System.StringComparison]::OrdinalIgnoreCase
        }
        else {
            [System.StringComparison]::Ordinal
        }

        $TargetApplications = $Library.Applications
        if ($PSBoundParameters.ContainsKey("Name")) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Filtering applications by name: $($Name -join ', ')."
            $TargetApplications = $Library.Applications | Where-Object { $_.Name -in $Name }
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand): Selected $(@($TargetApplications).Count) of $(@($Library.Applications).Count) applications."

        foreach ($Application in $TargetApplications) {
            if ([System.String]::IsNullOrWhiteSpace($Application.Name) -or
                [System.IO.Path]::IsPathRooted($Application.Name) -or
                $Application.Name -match "[\\/]" -or
                [System.IO.Path]::GetFileName($Application.Name) -ne $Application.Name) {
                Write-Warning -Message "$($MyInvocation.MyCommand): Skipping application with unsafe library name '$($Application.Name)'."
                continue
            }

            $AppPath = [System.IO.Path]::GetFullPath((Join-Path -Path $LibraryRoot -ChildPath $Application.Name))
            $LibraryRootPrefix = $LibraryRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if (-not $AppPath.StartsWith($LibraryRootPrefix, $PathComparison)) {
                Write-Warning -Message "$($MyInvocation.MyCommand): Skipping '$($Application.Name)' because its path is outside the library."
                continue
            }

            $AppManifest = Join-Path -Path $AppPath -ChildPath "$($Application.Name).json"
            Write-Verbose -Message "$($MyInvocation.MyCommand): Processing '$($Application.Name)'. App manifest: '$AppManifest'."

            if (-not (Test-Path -LiteralPath $AppPath -PathType "Container") -or
                -not (Test-Path -LiteralPath $AppManifest -PathType "Leaf")) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping '$($Application.Name)' because its app manifest is missing."
                Write-Warning -Message "$($MyInvocation.MyCommand): App manifest missing: $AppManifest"
                continue
            }

            $AppDirectoryItem = Get-Item -LiteralPath $AppPath -Force -ErrorAction "Stop"
            $ManifestItem = Get-Item -LiteralPath $AppManifest -Force -ErrorAction "Stop"
            if (($AppDirectoryItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -or
                ($ManifestItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                Write-Warning -Message "$($MyInvocation.MyCommand): Skipping '$($Application.Name)' because its app directory or manifest is a reparse point."
                continue
            }

            try {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Reading app manifest '$AppManifest'."
                [System.Array] $AppVersions = Get-Content -Path $AppManifest -Raw -ErrorAction "Stop" | ConvertFrom-Json -ErrorAction "Stop"
            }
            catch {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping '$($Application.Name)' because its app manifest could not be read."
                Write-Warning -Message "$($MyInvocation.MyCommand): Failed reading $AppManifest with: $($_.Exception.Message)"
                continue
            }
            Write-Verbose -Message "$($MyInvocation.MyCommand): Found $($AppVersions.Count) version entries for '$($Application.Name)'."

            if ($AppVersions.Count -le $Keep) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): No pruning required for '$($Application.Name)': $($AppVersions.Count) entries is within the keep limit of $Keep. Installers and manifest unchanged."
                Write-Output -InputObject ([PSCustomObject] @{
                        ApplicationName = $Application.Name
                        Keep            = $Keep
                        KeptCount       = $AppVersions.Count
                        PrunedCount     = 0
                        RemovedCount    = 0
                        RemovedFileCount = 0
                        RemovedFiles    = @()
                        ManifestPath    = $AppManifest
                    })
                continue
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Sorting System.Version-compatible entries by numeric version, then other entries by version text, with manifest index as the final tie-breaker (descending). System.Version-compatible entries take priority."
            $ItemsWithSortData = for ($i = 0; $i -lt $AppVersions.Count; $i++) {
                Get-VersionItemSortData -Item $AppVersions[$i] -Index $i
            }

            $SortedItems = $ItemsWithSortData | Sort-Object -Property `
            @{ Expression = { $_.HasParsedVersion }; Descending = $true }, `
            @{ Expression = { $_.ParsedVersion }; Descending = $true }, `
            @{ Expression = { $_.VersionText }; Descending = $true }, `
            @{ Expression = { $_.Index }; Descending = $true }

            [System.Array] $RetainedItems = @($SortedItems | Select-Object -First $Keep)
            [System.Array] $PrunedItems = @($SortedItems | Select-Object -Skip $Keep)
            Write-Verbose -Message "$($MyInvocation.MyCommand): Retaining $($RetainedItems.Count) entries and pruning $($PrunedItems.Count) entries for '$($Application.Name)'."
            foreach ($Retained in $RetainedItems) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Retaining version '$($Retained.VersionText)' (manifest index $($Retained.Index), parsed version: $($Retained.HasParsedVersion)). Installer: '$($Retained.Item.Path)'."
            }

            [System.Array] $RetainedObjects = @($RetainedItems | Select-Object -ExpandProperty "Item")
            $ManifestUpdated = $false
            if ($PSCmdlet.ShouldProcess($AppManifest, "Update retained versions")) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Writing $($RetainedObjects.Count) retained entries to '$AppManifest'."
                $TemporaryManifest = Join-Path -Path $AppPath -ChildPath ".$($Application.Name).$([System.Guid]::NewGuid().ToString('N')).tmp"
                $BackupManifest = "$TemporaryManifest.bak"
                try {
                    ConvertTo-Json -InputObject $RetainedObjects -ErrorAction "Stop" |
                        Out-File -FilePath $TemporaryManifest -Encoding "Utf8" -NoNewline -ErrorAction "Stop"
                    [System.IO.File]::Replace($TemporaryManifest, $AppManifest, $BackupManifest)
                }
                finally {
                    if (Test-Path -LiteralPath $TemporaryManifest -PathType "Leaf") {
                        Remove-Item -LiteralPath $TemporaryManifest -Force -ErrorAction "Stop"
                    }
                    if (Test-Path -LiteralPath $BackupManifest -PathType "Leaf") {
                        Remove-Item -LiteralPath $BackupManifest -Force -ErrorAction "Stop"
                    }
                }
                $ManifestUpdated = $true
                Write-Verbose -Message "$($MyInvocation.MyCommand): Updated app manifest '$AppManifest'."
            }
            else {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Manifest update not approved by ShouldProcess (WhatIf or confirmation declined): '$AppManifest'."
            }

            $RemovedFiles = New-Object -TypeName "System.Collections.ArrayList"
            if ($ManifestUpdated) {
                foreach ($Pruned in $PrunedItems) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Pruning version '$($Pruned.VersionText)' (manifest index $($Pruned.Index), parsed version: $($Pruned.HasParsedVersion)). Installer: '$($Pruned.Item.Path)'."
                    if ([System.String]::IsNullOrEmpty($Pruned.Item.Path)) {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping installer removal for version '$($Pruned.VersionText)': no installer path is recorded."
                        continue
                    }

                    $InstallerPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($AppPath, [System.String]$Pruned.Item.Path))
                    $AppPathPrefix = $AppPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
                    if (-not $InstallerPath.StartsWith($AppPathPrefix, $PathComparison)) {
                        Write-Warning -Message "$($MyInvocation.MyCommand): Skipping installer removal because '$($Pruned.Item.Path)' is outside '$AppPath'."
                        continue
                    }

                    if (-not (Test-Path -LiteralPath $InstallerPath -PathType "Leaf")) {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping installer removal: '$InstallerPath' does not exist or is not a file."
                        continue
                    }

                    $CurrentPath = $InstallerPath
                    $UnsafePath = $false
                    while ($CurrentPath.StartsWith($AppPathPrefix, $PathComparison) -or
                        [System.String]::Equals($CurrentPath, $AppPath, $PathComparison)) {
                        $PathItem = Get-Item -LiteralPath $CurrentPath -Force -ErrorAction "Stop"
                        if ($PathItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                            $UnsafePath = $true
                            break
                        }
                        if ([System.String]::Equals($CurrentPath, $AppPath, $PathComparison)) {
                            break
                        }
                        $CurrentPath = Split-Path -Path $CurrentPath -Parent
                    }
                    if ($UnsafePath) {
                        Write-Warning -Message "$($MyInvocation.MyCommand): Skipping installer removal because '$InstallerPath' traverses a reparse point."
                        continue
                    }

                    if ($PSCmdlet.ShouldProcess($InstallerPath, "Remove old installer")) {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Removing installer '$InstallerPath'."
                        Remove-Item -LiteralPath $InstallerPath -Force -ErrorAction "Stop"
                        $RemovedFiles.Add($InstallerPath) | Out-Null
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Removed installer '$InstallerPath'."
                    }
                    else {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Installer removal not approved by ShouldProcess (WhatIf or confirmation declined): '$InstallerPath'."
                    }
                }
            }

            $RemovedCount = if ($ManifestUpdated) { $PrunedItems.Count } else { 0 }
            Write-Verbose -Message "$($MyInvocation.MyCommand): Completed '$($Application.Name)': $($RetainedObjects.Count) entries selected for retention, $($PrunedItems.Count) entries selected for pruning, $($RemovedFiles.Count) installer files removed."
            Write-Output -InputObject ([PSCustomObject] @{
                    ApplicationName = $Application.Name
                    Keep            = $Keep
                    KeptCount       = $RetainedObjects.Count
                    PrunedCount     = $PrunedItems.Count
                    RemovedCount    = $RemovedCount
                    RemovedFileCount = $RemovedFiles.Count
                    RemovedFiles    = $RemovedFiles
                    ManifestPath    = $AppManifest
                })
        }
    }
}