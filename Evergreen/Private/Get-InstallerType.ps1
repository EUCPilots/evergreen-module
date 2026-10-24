function Get-InstallerType {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String] $String
    )

    $Tokens = @($String -csplit '(?<=[a-z0-9])(?=[A-Z])|[^A-Za-z0-9]+')
    $Terms = @(
        for ($Index = 0; $Index -lt $Tokens.Count; $Index++) {
            $Tokens[$Index].ToLowerInvariant()
            if ($Index -lt ($Tokens.Count - 1)) {
                "$($Tokens[$Index])$($Tokens[$Index + 1])".ToLowerInvariant()
            }
        }
    )

    $InstallerTypes = [ordered] @{
        noadmin      = "NoAdmin"
        admin        = "Admin"
        airgap       = "Airgap"
        classic      = "Classic"
        debug        = "Debug"
        grouppolicy  = "GroupPolicy"
        legacy       = "Legacy"
        light        = "Light"
        minimalist   = "Minimal"
        ndm          = "NonDarkMode"
        noinstaller  = "Portable"
        portable     = "Portable"
        plus         = "Plus"
        premium      = "Premium"
        standalone   = "Standalone"
        qt5          = "Qt5"
        qt6          = "Qt6"
        user         = "User"
        winmsi       = "MSI"
    }

    $Type = "Default"
    foreach ($InstallerType in $InstallerTypes.Keys) {
        if ($Terms -contains $InstallerType) {
            $Type = $InstallerTypes[$InstallerType]
            break
        }
    }

    if ($Type -eq "Default") {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Installer type not found in $String, defaulting to 'Default'."
    }
    Write-Output -InputObject $Type
}
