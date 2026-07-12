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
        if (-not (Test-Path -Path $Path -PathType "Container")) {
            $Msg = "Cannot use path $Path because it does not exist or is not a directory."
            throw [System.IO.DirectoryNotFoundException]::New($Msg)
        }

        $LibraryFile = Join-Path -Path $Path -ChildPath "EvergreenLibrary.json"
        if (-not (Test-Path -Path $LibraryFile -PathType "Leaf")) {
            $Msg = "$Path is not an Evergreen Library. Cannot find EvergreenLibrary.json. Create a library with New-EvergreenLibrary."
            throw [System.IO.FileNotFoundException]::New($Msg)
        }

        $Library = Get-Content -Path $LibraryFile -ErrorAction "Stop" | ConvertFrom-Json -ErrorAction "Stop"

        $TargetApplications = $Library.Applications
        if ($PSBoundParameters.ContainsKey("Name")) {
            $TargetApplications = $Library.Applications | Where-Object { $_.Name -in $Name }
        }

        foreach ($Application in $TargetApplications) {
            $AppPath = Join-Path -Path $Path -ChildPath $Application.Name
            $AppManifest = Join-Path -Path $AppPath -ChildPath "$($Application.Name).json"

            if (-not (Test-Path -Path $AppManifest -PathType "Leaf")) {
                Write-Warning -Message "$($MyInvocation.MyCommand): App manifest missing: $AppManifest"
                continue
            }

            try {
                [System.Array] $AppVersions = @(Get-Content -Path $AppManifest -ErrorAction "Stop" | ConvertFrom-Json -ErrorAction "Stop")
            }
            catch {
                Write-Warning -Message "$($MyInvocation.MyCommand): Failed reading $AppManifest with: $($_.Exception.Message)"
                continue
            }

            if ($AppVersions.Count -le $Keep) {
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

            $RemovedFiles = New-Object -TypeName "System.Collections.ArrayList"
            foreach ($Pruned in $PrunedItems) {
                if ([System.String]::IsNullOrEmpty($Pruned.Item.Path)) {
                    continue
                }

                if (-not (Test-Path -Path $Pruned.Item.Path -PathType "Leaf")) {
                    continue
                }

                if ($PSCmdlet.ShouldProcess($Pruned.Item.Path, "Remove old installer")) {
                    Remove-Item -Path $Pruned.Item.Path -Force -ErrorAction "Stop"
                    $RemovedFiles.Add($Pruned.Item.Path) | Out-Null
                }
            }

            [System.Array] $RetainedObjects = @($RetainedItems | Select-Object -ExpandProperty "Item")
            if ($PSCmdlet.ShouldProcess($AppManifest, "Update retained versions")) {
                $RetainedObjects | ConvertTo-Json -ErrorAction "Stop" | Out-File -FilePath $AppManifest -Encoding "Utf8" -NoNewline -ErrorAction "Stop"
            }

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