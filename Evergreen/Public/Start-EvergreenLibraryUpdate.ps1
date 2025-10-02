function Start-EvergreenLibraryUpdate {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias("Invoke-EvergreenLibraryUpdate")]
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
        [System.String] $Proxy,

        [Parameter(Mandatory = $false, Position = 2)]
        [System.Management.Automation.PSCredential]
        $ProxyCredential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        $params = @{}
        if ($PSBoundParameters.ContainsKey("Proxy")) {
            $params.Proxy = $Proxy
        }
        if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
            $params.ProxyCredential = $ProxyCredential
        }
    }

    process {
        if (Test-Path -Path $Path -PathType "Container") {
            $LibraryFile = $(Join-Path -Path $Path -ChildPath "EvergreenLibrary.json")

            if (Test-Path -Path $LibraryFile) {
                Write-Verbose -Message "Library exists: $LibraryFile."
                $Library = Get-Content -Path $LibraryFile -ErrorAction "Stop" | ConvertFrom-Json -ErrorAction "Stop"

                # Get current list of install media files present in library
                $LibContentBefore = Get-ChildItem -Path $Path -File -Recurse -Exclude "*.json" | `
                    Select-Object -Property "FullName" | Sort-Object -Property "FullName"

                # Return the application details
                foreach ($Application in $Library.Applications) {
                    $AppPath = $(Join-Path -Path $Path -ChildPath $Application.Name)
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Application path: $AppPath."
                    Write-Verbose -Message "$($MyInvocation.MyCommand): Query Evergreen for: $($Application.Name)."

                    # Gather the application version information from Get-EvergreenApp
                    if ([System.String]::IsNullOrEmpty($Application.Filter)) {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): No filter specified for $($Application.Name)."
                        $App = Get-EvergreenApp -Name $Application.EvergreenApp @params
                    }
                    else {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Filter: $($Application.Filter)."
                        $WhereBlock = [ScriptBlock]::Create($Application.Filter)
                        [System.Array]$App = @()
                        $App = Get-EvergreenApp -Name $Application.EvergreenApp @params | Where-Object $WhereBlock
                    }

                    # If something returned, add to the library
                    if ($null -ne $App) {
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Download count for $($Application.EvergreenApp): $($App.Count)."

                        # Save the installers to the library
                        if ($PSCmdlet.ShouldProcess("Downloading $($App.Count) application installers.", "Save-EvergreenApp")) {
                            $Saved = $App | Save-EvergreenApp -Path $AppPath @params
                        }

                        # Add the saved installer path to the application version information
                        if ($Saved.Count -gt 1) {
                            for ($i = 0; $i -lt $App.Count; $i++) {
                                $Item = $Saved | Where-Object { $_.FullName -match $App[$i].Version -and ((Split-Path $_.FullName -Leaf) -eq (Split-Path $App[$i].URI -Leaf)) }
                                Write-Verbose -Message "$($MyInvocation.MyCommand): Add path to object: $($Item.FullName)"
                                $App[$i] | Add-Member -MemberType "NoteProperty" -Name "Path" -Value $Item.FullName
                            }
                        }
                        else {
                            Write-Verbose -Message "$($MyInvocation.MyCommand): Add path to object: $($Saved.FullName)"
                            $App | Add-Member -MemberType "NoteProperty" -Name "Path" -Value $Saved.FullName
                        }

                        # Write the application version information to the library
                        Export-EvergreenApp -InputObject $App -Path $(Join-Path -Path $AppPath -ChildPath "$($Application.Name).json") | Out-Null
                    }
                }

                # Get new list of install media files present in library following update
                $LibContentAfter = Get-ChildItem -Path $Path -File -Recurse -Exclude "*.json" | Select-Object FullName | Sort-Object FullName

                # Output details of library updates
                if ($null -eq $LibContentAfter) {
                    Write-Warning -Message "$($MyInvocation.MyCommand): No media found in Evergreen Library"
                }
                elseif ($null -ne $LibContentBefore) {
                        (Compare-Object $LibContentBefore $LibContentAfter -Property FullName -IncludeEqual | ForEach-Object {
                        [PSCustomObject]@{
                            Installer = $_.FullName
                            Status    = $_.SideIndicator -replace "=>", "NEW" -replace "==", "UNCHANGED" -replace "<=", "DELETED"
                        }
                    })
                }
                else {
                    ($LibContentAfter | ForEach-Object {
                        [PSCustomObject]@{
                            Installer = $_.FullName
                            Status    = "NEW"
                        }
                    })
                }
            }
            else {
                $Msg = "$Path is not an Evergreen Library. Cannot find EvergreenLibrary.json. Create a library with New-EvergreenLibrary."
                throw [System.IO.FileNotFoundException]::New($Msg)
            }
        }
        else {
            $Msg = "Cannot use path $Path because it does not exist or is not a directory."
            throw [System.IO.DirectoryNotFoundException]::New($Msg)
        }
    }
}
