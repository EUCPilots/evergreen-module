function Update-Evergreen {
    <#
        .EXTERNALHELP Evergreen-help.xml     
    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    param(
        [Parameter()]
        [System.Management.Automation.SwitchParameter] $Force,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ($_ -match "^v\d{2}\.(0[1-9]|1[0-2])\.(0[1-9]|[12]\d|3[01])\.(0|[1-9]\d{0,5})$") {
                    $true
                }
                else {
                    throw "'$_' must be in the format 'v<major>.<minor>.<patch>.<build>'."
                }
            })]
        [System.String] $Release
    )

    begin {
        # Sync folders to check for expected structure
        $SyncFolders = @((Join-Path -Path $Script:AppsPath -ChildPath 'Apps'), (Join-Path -Path $Script:AppsPath -ChildPath 'Manifests'))

        # Validate Force parameter requirement when Release is specified
        if ($PSBoundParameters['Release'] -and -not $PSBoundParameters['Force']) {
            throw "-Force parameter required when specifying a release version."
        }

        try {
            # Get the latest version from the remote repository
            if ($PSBoundParameters['Release']) {
                Write-Message -Message "Using specified Evergreen apps release version: $Release"
                $Url = "https://api.github.com/repos/$($script:resourceStrings.Repositories.Apps.Repo)/releases/tags/$Release"
            }
            else {
                Write-Message -Message "Checking for latest Evergreen apps release from: $($script:resourceStrings.Repositories.Apps.Repo)"
                $Url = "https://api.github.com/repos/$($script:resourceStrings.Repositories.Apps.Repo)/releases/latest"
            }

            Write-Message -Message "Release URL: $Url"
            $EvergreenAppsRelease = Get-GitHubRepoRelease -Uri $Url -Filter "\.zip$|\.csv"
            $EvergreenAppsZip = $EvergreenAppsRelease | Where-Object { $_.Type -eq "zip" }
            $EvergreenAppsCsv = $EvergreenAppsRelease | Where-Object { $_.Type -eq "csv" }
            Write-Message -Message "Found Evergreen apps release: $($EvergreenAppsZip.Version)"
        }
        catch {
            $EvergreenAppsRelease = $null
        }

        # Check whether the AppsPath exists and create it if not
        if (Test-Path -Path $script:AppsPath -PathType "Container") {

            $DoHashCheck = $false
            foreach ($folder in $SyncFolders) {
                if (Test-Path -Path $folder -PathType "Container") {
                    $DoHashCheck = $true
                }
            }

            if ($DoHashCheck) {
                try {
                    # Get remote SHA256 hashes from CSV which will be attached to the latest release
                    Write-Message -Message "Downloading hash file: $($EvergreenAppsCsv.Uri)."
                    $Sha256Csv = $EvergreenAppsCsv | Save-EvergreenApp -LiteralPath $script:AppsPath -Force
                    if ($Sha256Csv) {
                        $FileHash = (Get-FileHash -Path $Sha256Csv -Algorithm "SHA256").Hash.ToLower()
                        if ($FileHash -ne $EvergreenAppsCsv.Sha256.ToLower()) {
                            throw "SHA256 mismatch for downloaded hash file."
                        }
                        else {
                            Write-Message -Message "Downloaded hash file passed hash validation." -MessageType "Pass"
                        }
                    }
                    $RemoteFileShas = $Sha256Csv | Get-Content | ConvertFrom-Csv
                }
                catch {
                    Write-Warning -Message "Failed to retrieve or parse SHA256 hash file: $_"
                }

                # Check if the local files match the expected SHA256 hashes
                Write-Message -Message "Validating local cache against SHA256 hashes."
                $HashMismatch = $false
                foreach ($File in $RemoteFileShas) {
                    $FilePath = Join-Path -Path $script:AppsPath -ChildPath $File.file_path
                    if (Test-Path -Path $FilePath) {
                        $LocalHash = (Get-FileHash -Path $FilePath -Algorithm "SHA256").Hash.ToLower()
                        if ($LocalHash -ne $File.sha256.ToLower()) {
                            Write-Message -Message "SHA256 mismatch for file: '$($FilePath)'." -MessageType "Fail"
                            $HashMismatch = $true
                        }
                    }
                }
                if ($HashMismatch) {
                    Write-Message -Message "SHA256 mismatch found. Recommend running 'Update-Evergreen -Force'." -MessageType "Warning"
                }
                else {
                    Write-Message -Message "Local cache passed hash validation." -MessageType "Pass"
                }
            }
        }
        else {
            # Create the AppsPath directory
            Write-Message -Message "Creating Evergreen apps cache directory: $script:AppsPath."
            New-Item -Path $script:AppsPath -ItemType "Directory" -Force | Out-Null
        }
    }

    process {
        try {
            # Read the local version file
            $LocalVersion = (Get-Content -Path $script:VersionFile -Raw -ErrorAction "Stop").Trim()
            Write-Message -Message "Local cache version: $LocalVersion"
        }
        catch {
            $LocalVersion = $null
        }

        $DoUpdate = $false
        if ($null -eq $EvergreenAppsRelease) {
            throw "Could not retrieve remote version information. Please check your internet connection, the repository URL, or your access token."
        }
        elseif ($Release) {
            Write-Message -Message "Forcing update to specified Evergreen apps release version: $Release."
            $DoUpdate = $true
        }
        elseif ($null -eq $LocalVersion) {
            Write-Message -Message "Unable to find Evergreen apps cached version. Downloading latest release."
            $DoUpdate = $true
        }
        elseif ([System.Version]$EvergreenAppsZip.Version -gt [System.Version]$LocalVersion) {
            Write-Message -Message "Evergreen apps cache is out of date. Downloading latest release."
            $DoUpdate = $true
        }
        elseif ([System.Version]$EvergreenAppsZip.Version -le [System.Version]$LocalVersion) {
            Write-Message -Message "Local cache matches release version. Evergreen apps are up to date."
            $DoUpdate = $false
            if ($PSBoundParameters['Force']) {
                Write-Message -Message "Forcing update due to -Force parameter."
            }
            else {
                Write-Message -Message "Use 'Update-Evergreen -Force' to force a full re-sync."
            }
        }
        else {
            Write-Message -Message "Unable to validate local Evergreen apps cached version. Downloading latest release."
            $DoUpdate = $true
        }

        # Check local expected directories exist
        foreach ($folder in $SyncFolders) {
            if (-not (Test-Path -Path $folder -PathType "Container")) {
                Write-Message -Message "'$folder' does not exist. Will perform full sync."
                $DoUpdate = $true
            }
        }

        # If -Force or no local copy or commit mismatch, do a full download
        if ($PSBoundParameters['Force'] -or $DoUpdate) {
            Write-Message -Message "Performing full sync from remote repository."

            Write-Message -Message "Downloading Evergreen apps release: $($EvergreenAppsZip.Uri)."
            $ZipFile = Save-EvergreenApp -InputObject $EvergreenAppsZip -LiteralPath $script:AppsPath -Force
            if (Test-Path -Path $ZipFile -PathType "Leaf") {
                Write-Verbose -Message "Downloaded Evergreen apps release to $ZipFile."

                $ZipFileHash = (Get-FileHash -Path $ZipFile -Algorithm "SHA256").Hash.ToLower()
                if ($EvergreenAppsZip.Sha256.ToLower() -ne $ZipFileHash) {
                    throw "SHA256 mismatch for downloaded release zip file."
                }
                else {
                    Write-Message -Message "Downloaded release zip file passed hash validation." -MessageType "Pass"
                }

                Write-Verbose -Message "Extracting Evergreen apps release from $ZipFile."
                $ExtractPath = Join-Path -Path $script:AppsPath -ChildPath "_extracted"
                if (Test-Path -Path $ExtractPath) { Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction "SilentlyContinue" }
                $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
                Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force
                Remove-Item -Path $ZipFile -Force -ErrorAction "SilentlyContinue"

                Write-Message -Message "Validating extracted files against SHA256 hashes."
                $DoReplace = $true
                foreach ($File in $RemoteFileShas) {
                    $FilePath = Join-Path -Path $ExtractPath -ChildPath $File.file_path
                    if (Test-Path -Path $FilePath) {
                        $LocalHash = (Get-FileHash -Path $FilePath -Algorithm "SHA256").Hash.ToLower()
                        if ($LocalHash -ne $File.sha256.ToLower()) {
                            Write-Warning -Message "SHA256 mismatch for file '$($File.file_path)'." -MessageType "Fail"
                            $DoReplace = $false
                        }
                        else {
                            Write-Verbose -Message "[$(Get-Symbol -Symbol "Tick")] File '$($File.file_path)' hash matches expected value."
                        }
                    }
                    else {
                        Write-Warning -Message "Expected file '$($File.file_path)' not found in extracted release." -MessageType "Fail"
                        $DoReplace = $false
                    }
                }

                if ($DoReplace) {
                    Write-Message -Message "Extracted files passed hash validation." -MessageType "Pass"
                    Write-Message -Message "Synchronizing Evergreen apps and manifests to $script:AppsPath."
                    # Remove existing Apps and Manifests directories
                    $LocalAppsPath = Join-Path -Path $script:AppsPath -ChildPath "Apps"
                    $LocalManifestsPath = Join-Path -Path $script:AppsPath -ChildPath "Manifests"
                    if (Test-Path -Path $LocalAppsPath) { Remove-Item -Path $LocalAppsPath -Recurse -Force -ErrorAction "SilentlyContinue" }
                    if (Test-Path -Path $LocalManifestsPath) { Remove-Item -Path $LocalManifestsPath -Recurse -Force -ErrorAction "SilentlyContinue" }

                    # Move extracted contents to the correct locations
                    Move-Item -Path (Join-Path -Path $ExtractPath -ChildPath "Apps") -Destination $script:AppsPath
                    Move-Item -Path (Join-Path -Path $ExtractPath -ChildPath "Manifests") -Destination $script:AppsPath

                    if ($EvergreenAppsZip) { Set-Content -Path $script:VersionFile -Value $EvergreenAppsZip.Version -Encoding "UTF8" -Force }
                    Write-Message -Message "Update complete."
                }
                else {
                    Write-Warning -Message "Some files did not match expected SHA256 hashes. Evergreen apps and manifests were not updated."
                }

                # Clean up the extracted files
                Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction "SilentlyContinue"
            }
            else {
                throw "Failed to download Evergreen apps release. The file does not exist at $ZipFile."
            }
        }
    }
}
