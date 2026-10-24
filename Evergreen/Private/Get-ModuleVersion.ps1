function Get-ModuleVersion {
    $module = $MyInvocation.MyCommand.Module
    if ($null -ne $module) {
        return $module.Version
    }

    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Evergreen.psd1"
    $manifest = Import-PowerShellDataFile -Path $manifestPath -ErrorAction "Stop"
    return [System.Version]$manifest.ModuleVersion
}
