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
        try {
            $Shell = New-Object -ComObject "Shell.Application"
            $SourceCab = $Shell.NameSpace($Path)
            $Items = $SourceCab.Items() | ForEach-Object { Join-Path -Path $DestinationPath -ChildPath $_.Name }
            Remove-Item -Path $Items -ErrorAction "SilentlyContinue" -Force
            $DestinationFolder = $Shell.NameSpace($DestinationPath)
            Write-Verbose -Message "$($MyInvocation.MyCommand): Expanding CAB file '$Path' to '$DestinationPath'."
            $DestinationFolder.CopyHere($SourceCab.Items(), 0x1014)
            return $Items
        }
        catch {
            throw "Failed to expand CAB file. $_"
        }
    }
    else {
        # Future update for cross-platform
        throw "Expand-CabArchive is only supported on Windows."
    }
}
