function New-EvergreenPath {
    <#
        .SYNOPSIS
            Build a path from the Evergreen input object properties

        .DESCRIPTION
            With -WhatIf, returns the path that would be created without creating it.

        .NOTES
            Author: Aaron Parker
    #>
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject] $InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path
    )

    if ([System.String]::IsNullOrWhiteSpace($Path)) {
        throw [System.ArgumentException] "Path cannot contain only whitespace."
    }

    # Set the value of $Path to $OutPath to use to build the new path
    $OutPath = $Path

    # Build the new path using the specified object properties
    foreach ($property in ("Product", "Track", "Channel", "Release", "Ring", "Version", "Language", "Architecture")) {
        $value = $InputObject.$property
        if ([System.Boolean]$value) {
            $segment = [System.String]$value
            $invalidCharacters = [System.IO.Path]::GetInvalidFileNameChars()
            if (
                [System.String]::IsNullOrWhiteSpace($segment) -or
                $segment -in @(".", "..") -or
                $segment.IndexOfAny($invalidCharacters) -ge 0 -or
                $segment.Contains("/") -or
                $segment.Contains("\")
            ) {
                throw [System.ArgumentException] "InputObject property '$property' is not a valid path segment: '$segment'."
            }

            Write-Verbose -Message "$($MyInvocation.MyCommand): $($property): $segment."
            $OutPath = Join-Path -Path $OutPath -ChildPath $segment
            if (Test-Path -LiteralPath $OutPath -PathType Container) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Path exists: $OutPath."
            }
            else {
                if ($PSCmdlet.ShouldProcess($OutPath, "Create Directory")) {
                    try {
                        $params = @{
                            Path        = $OutPath
                            ItemType    = "Directory"
                            Force       = $true
                            ErrorAction = "Stop"
                        }
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Create path: $OutPath."
                        New-Item @params > $null
                    }
                    catch {
                        Write-Warning -Message "$($MyInvocation.MyCommand): Failed to create target directory. Error failed with: $($_.Exception.Message)."
                        throw
                    }
                }
            }
        }
    }

    # Return the newly built path
    Write-Output -InputObject $OutPath
}
