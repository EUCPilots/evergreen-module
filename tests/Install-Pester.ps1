<#
    Install the Pester version used by CI, including on PowerShell 7.4.
#>

$PesterVersion = (Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "..\ci\ValidationTools.psd1")).Pester
if (-not (Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -eq [System.Version]$PesterVersion })) {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $null = Install-PackageProvider -Name NuGet -MinimumVersion "2.8.5.208" -Force -Scope CurrentUser -ErrorAction Stop
    }
    Install-Module -Name Pester -RequiredVersion $PesterVersion -Repository PSGallery -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
}
