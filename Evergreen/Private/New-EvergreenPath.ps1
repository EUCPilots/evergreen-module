function New-EvergreenPath {
    <#
        .SYNOPSIS
            Build a path from the Evergreen input object properties

        .NOTES
            Author: Aaron Parker
    #>
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        [System.Management.Automation.PSObject] $InputObject,

        [Parameter()]
        [System.String] $Path
    )

    # Set the value of $Path to $OutPath to use to build the new path
    $OutPath = $Path

    # Build the new path using the specified object properties
    foreach ($property in ("Product", "Track", "Channel", "Release", "Ring", "Version", "Language", "Architecture")) {
        if ([System.Boolean]($InputObject.$property)) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): $($property): $($InputObject.$property)."
            $OutPath = Join-Path -Path $OutPath -ChildPath $InputObject.$property
            if (Test-Path -Path $OutPath) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Path exists: $OutPath."
            }
            else {
                if ($PSCmdlet.ShouldProcess($OutPath, "Create Directory")) {
                    try {
                        $params = @{
                            Path        = $OutPath
                            ItemType    = "Directory"
                            ErrorAction = "Continue"
                        }
                        Write-Verbose -Message "$($MyInvocation.MyCommand): Create path: $OutPath."
                        New-Item @params > $null
                    }
                    catch {
                        Write-Warning -Message "$($MyInvocation.MyCommand): Failed to create target directory. Error failed with: $($_.Exception.Message)."
                        throw $_
                    }
                }
            }
        }
    }

    # Return the newly built path
    Write-Output -InputObject $OutPath
}
