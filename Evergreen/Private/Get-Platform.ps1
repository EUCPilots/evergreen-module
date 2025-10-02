function Get-Platform {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $String
    )

    switch -Regex ($String) {
        "\.tar.gz|linux" { $platform = "Linux"; break }
        "\.nupkg" { $platform = "NuGet"; break }
        "macos|osx|darwin" { $platform = "macOS"; break }
        "\.deb|debian" { $platform = "Debian"; break }
        "ubuntu" { $platform = "Ubuntu"; break }
        "centos" { $platform = "CentOS"; break }
        "\.exe|\.msi|\.msix|\.appx|\.appxbundle|windows|win" { $platform = "Windows"; break }
        default {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Platform not found, defaulting to Windows."
            $platform = "Windows"
        }
    }
    Write-Output -InputObject $platform
}
