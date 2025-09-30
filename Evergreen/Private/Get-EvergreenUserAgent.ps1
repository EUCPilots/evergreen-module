function Get-EvergreenUserAgent {
    return "Evergreen/$(Get-ModuleVersion) (https://github.com/aaronparker/evergreen; PowerShell $($PSVersionTable.PSVersion); $(Get-OSName))"
}
