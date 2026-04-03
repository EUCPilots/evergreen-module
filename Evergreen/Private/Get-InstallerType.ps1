function Get-InstallerType {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String] $String
    )

    switch -Regex ($String.ToLower()) {
        "min"          { $Type = "Minimal"; break }
        "user"         { $Type = "User"; break }
        "portable"     { $Type = "Portable"; break }
        "no-installer" { $Type = "Portable"; break }
        "debug"        { $Type = "Debug"; break }
        "airgap"       { $Type = "Airgap"; break }
        "winmsi"       { $Type = "MSI"; break }
        default {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Installer type not found in $String, defaulting to 'Default'."
            $Type = "Default"
        }
    }
    Write-Output -InputObject $Type
}
