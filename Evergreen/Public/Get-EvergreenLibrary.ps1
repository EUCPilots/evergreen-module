function Get-EvergreenLibrary {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify the path to the library.",
            ParameterSetName = "Path")]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo] $Path,

        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify the URI to the library.",
            ParameterSetName = "URI")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
            if ($_ -match "^(https:\/\/([a-zA-Z0-9_\-\.]+)\/([a-zA-Z0-9_-]+)\/(EvergreenLibrary.json|Library.json))$") {
                $true
            }
            else {
                throw "'$_' must be in the format 'https://<storageaccount>/<container>/EvergreenLibrary.json' or 'https://<storageaccount>/<container>/Library.json'."
            }
        })]
        [System.Uri] $Uri
    )

    begin {
        if ($PSBoundParameters.ContainsKey("Uri")) {
            # Get the details from the library
            $Library = Invoke-EvergreenRestMethod -Uri $Uri

            # Get the parent URI which we will use later
            $ParentUri = ($Uri.ToString() -replace $Uri.Segments[-1], "").Trim("/")

            # Build the output object
            $Output = [PSCustomObject] @{
                "Library"   = $Library
                "Inventory" = (New-Object -TypeName "System.Collections.ArrayList")
            }
        }
    }

    process {
        # Build the inventory from a Library on $Uri
        if ($PSBoundParameters.ContainsKey("Uri")) {
            foreach ($Application in $Library.Applications) {

                # Add details for the application to the output object
                try {
                    $AppUri = "$($ParentUri)/$($Application.Name)/$($Application.Name).json"
                    $Versions = Invoke-EvergreenRestMethod -Uri $AppUri
                }
                catch {
                    Write-Warning -Message "Encountered an error reading $AppUri with: $($_.Exception.Message)"
                }

                # Add details for this application
                $App = [PSCustomObject] @{
                    ApplicationName = $Application.Name
                    Versions        = $Versions
                }
                $Output.Inventory.Add($App) | Out-Null
            }

            # Output the object to the pipeline
            Write-Output -InputObject $Output
        }

        # Build the inventory from a Library on $Path
        if ($PSBoundParameters.ContainsKey("Path")) {
            if (Test-Path -Path $Path -PathType "Container") {
                $LibraryFile = $(Join-Path -Path $Path -ChildPath "EvergreenLibrary.json")

                if (Test-Path -Path $LibraryFile) {
                    Write-Verbose -Message "Library exists: $LibraryFile."

                    try {
                        # Read the library file
                        Write-Verbose -Message "Read: $LibraryFile."
                        $Library = Get-Content -Path $LibraryFile | ConvertFrom-Json
                    }
                    catch {
                        throw $_
                    }

                    if ($null -ne $Library) {

                        # Build the output object
                        $Output = [PSCustomObject] @{
                            "Library"   = $Library
                            "Inventory" = (New-Object -TypeName "System.Collections.ArrayList")
                        }

                        foreach ($Application in $Library.Applications) {

                            # Add details for the application to the output object
                            $AppPath = $(Join-Path -Path $Path -ChildPath $Application.Name)
                            if (Test-Path -Path $AppPath) {

                                $AppManifest = $(Join-Path -Path $AppPath -ChildPath "$($Application.Name).json")
                                if (Test-Path -Path $AppManifest) {

                                    try {
                                        Write-Verbose -Message "Read: $AppManifest."
                                        $Versions = Get-Content -Path $AppManifest | ConvertFrom-Json
                                    }
                                    catch {
                                        Write-Warning -Message "Encountered an error reading $AppManifest with: $($_.Exception.Message)"
                                    }

                                    try {
                                        # Add details for this application
                                        $App = [PSCustomObject] @{
                                            ApplicationName = $Application.Name
                                            Versions        = $Versions
                                        }
                                        $Output.Inventory.Add($App) | Out-Null
                                    }
                                    catch {
                                        Write-Warning -Message "Encountered an error adding details for $($Application.Name) with: $($_.Exception.Message)"
                                    }

                                }
                                else {
                                    Write-Warning -Message "Unable to find $AppManifest. Update the library with Invoke-EvergreenLibraryUpdate."
                                }
                            }
                            else {
                                Write-Warning -Message "Unable to find $AppPath. Update the library with Invoke-EvergreenLibraryUpdate."
                            }
                        }

                        # Output the object to the pipeline
                        Write-Output -InputObject $Output
                    }
                }
                else {
                    throw [System.IO.FileNotFoundException] "$Path is not an Evergreen Library. Cannot find EvergreenLibrary.json. Create a library with New-EvergreenLibrary."
                }
            }
            else {
                throw [System.IO.DirectoryNotFoundException] "Cannot use path $Path because it does not exist or is not a directory."
            }
        }
    }

    end {}
}
