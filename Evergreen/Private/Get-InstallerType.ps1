function Get-InstallerType {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String] $String
    )

    switch -Regex ($String.ToLower()) {
        "airgap" { $Type = "Airgap"; break }
        "debug" { $Type = "Debug"; break }
        "grouppolicy" { $Type = "GroupPolicy"; break }
        "minimalist" { $Type = "Minimal"; break }
        "ndm" { $Type = "NonDarkMode"; break }
        "no-installer" { $Type = "Portable"; break }
        "noadmin" { $Type = "NoAdmin"; break }
        "portable" { $Type = "Portable"; break }
        "qt5" { $Type = "Qt5"; break }
        "qt6" { $Type = "Qt6"; break }
        "user" { $Type = "User"; break }
        "winmsi" { $Type = "MSI"; break }
        default {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Installer type not found in $String, defaulting to 'Default'."
            $Type = "Default"
        }
    }
    Write-Output -InputObject $Type
}
