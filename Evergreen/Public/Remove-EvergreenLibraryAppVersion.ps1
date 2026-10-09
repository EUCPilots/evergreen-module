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

        $TargetApplications = $Library.Applications
        if ($PSBoundParameters.ContainsKey("Name")) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Filtering applications by name: $($Name -join ', ')."
            $TargetApplications = $Library.Applications | Where-Object { $_.Name -in $Name }
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand): Selected $(@($TargetApplications).Count) of $(@($Library.Applications).Count) applications."

        foreach ($Application in $TargetApplications) {
            $AppPath = Join-Path -Path $Path -ChildPath $Application.Name
            $AppManifest = Join-Path -Path $AppPath -ChildPath "$($Application.Name).json"
            Write-Verbose -Message "$($MyInvocation.MyCommand): Processing '$($Application.Name)'. App manifest: '$AppManifest'."

            if (-not (Test-Path -Path $AppManifest -PathType "Leaf")) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping '$($Application.Name)' because its app manifest is missing."
                Write-Warning -Message "$($MyInvocation.MyCommand): App manifest missing: $AppManifest"
                continue
            }

            try {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Reading app manifest '$AppManifest'."
                [System.Array] $AppVersions = @(Get-Content -Path $AppManifest -ErrorAction "Stop" | ConvertFrom-Json -ErrorAction "Stop")
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
                        RemovedCount    = 0
                        RemovedFiles    = @()
                        ManifestPath    = $AppManifest
                    })
                continue
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Sorting versions by parsed version, version text, then manifest index (descending). Entries with parsed versions take priority."
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

            $RemovedFiles = New-Object -TypeName "System.Collections.ArrayList"
            foreach ($Pruned in $PrunedItems) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Pruning version '$($Pruned.VersionText)' (manifest index $($Pruned.Index), parsed version: $($Pruned.HasParsedVersion)). Installer: '$($Pruned.Item.Path)'."
                if ([System.String]::IsNullOrEmpty($Pruned.Item.Path)) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping installer removal for version '$($Pruned.VersionText)': no installer path is recorded."
                    continue
                }

                if (-not (Test-Path -Path $Pruned.Item.Path -PathType "Leaf")) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Skipping installer removal: '$($Pruned.Item.Path)' does not exist or is not a file."
                    continue
                }

                if ($PSCmdlet.ShouldProcess($Pruned.Item.Path, "Remove old installer")) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Removing installer '$($Pruned.Item.Path)'."
                    Remove-Item -Path $Pruned.Item.Path -Force -ErrorAction "Stop"
                    $RemovedFiles.Add($Pruned.Item.Path) | Out-Null
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Removed installer '$($Pruned.Item.Path)'."
                }
                else {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Installer removal not approved by ShouldProcess (WhatIf or confirmation declined): '$($Pruned.Item.Path)'."
                }
            }

            [System.Array] $RetainedObjects = @($RetainedItems | Select-Object -ExpandProperty "Item")
            if ($PSCmdlet.ShouldProcess($AppManifest, "Update retained versions")) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Writing $($RetainedObjects.Count) retained entries to '$AppManifest'."
                $RetainedObjects | ConvertTo-Json -ErrorAction "Stop" | Out-File -FilePath $AppManifest -Encoding "Utf8" -NoNewline -ErrorAction "Stop"
                Write-Verbose -Message "$($MyInvocation.MyCommand): Updated app manifest '$AppManifest'."
            }
            else {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Manifest update not approved by ShouldProcess (WhatIf or confirmation declined): '$AppManifest'."
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): Completed '$($Application.Name)': $($RetainedObjects.Count) entries selected for retention, $($PrunedItems.Count) entries selected for pruning, $($RemovedFiles.Count) installer files removed."
            Write-Output -InputObject ([PSCustomObject] @{
                    ApplicationName = $Application.Name
                    Keep            = $Keep
                    KeptCount       = $RetainedObjects.Count
                    RemovedCount    = $PrunedItems.Count
                    RemovedFiles    = $RemovedFiles
                    ManifestPath    = $AppManifest
                })
        }
    }
}