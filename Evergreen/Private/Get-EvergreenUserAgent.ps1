function Get-EvergreenUserAgent {
    [OutputType([System.String])]
    $Version = Get-ModuleVersion
    return "Evergreen/$Version (https://github.com/EUCPilots/evergreen-module; PowerShell $($PSVersionTable.PSVersion); $($script:OSName))"
}
