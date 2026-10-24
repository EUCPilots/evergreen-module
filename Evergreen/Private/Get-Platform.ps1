function Get-Platform {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $String
    )

    $inputValue = $String -replace '[?#].*$', ''
    if ($inputValue -match '(?i)\.nupkg$') {
        Write-Output -InputObject "NuGet"
        return
    }

    $platforms = @()
    $indicators = @{
        macOS   = '(?i)(?<![a-z0-9])(?:macos|osx|darwin)(?![a-z0-9])'
        Debian  = '(?i)(?<![a-z0-9])debian(?![a-z0-9])|\.deb$'
        Ubuntu  = '(?i)(?<![a-z0-9])ubuntu(?![a-z0-9])'
        CentOS  = '(?i)(?<![a-z0-9])centos(?![a-z0-9])'
        Linux   = '(?i)(?<![a-z0-9])linux(?![a-z0-9])'
        Windows = '(?i)\.(?:exe|msi|msix|msixbundle|appx|appxbundle)$|(?<![a-z0-9])(?:windows|win(?:32|64)?)(?![a-z0-9])'
    }

    foreach ($platform in $indicators.Keys) {
        if ($inputValue -match $indicators[$platform]) {
            $platforms += $platform
        }
    }

    if ($platforms.Count -eq 1) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Platform determined to be $($platforms[0])."
        Write-Output -InputObject $platforms[0]
        return
    }

    Write-Verbose -Message "$($MyInvocation.MyCommand): Platform not found or ambiguous; returning Unknown."
    Write-Output -InputObject "Unknown"
}
