function Get-ModuleVersion {
    try {
        $ErrorActionPreference = "Stop"
        $module = (Get-Module -Name "Evergreen" -All)[0]
        if ($null -ne $module) {
            return $module.Version
        }
        else {
            return $(Get-Date -Format "yyMM.9999")
        }
    }
    catch {
        return $(Get-Date -Format "yyMM.9999")
    }
}
