function Get-EvergreenAppsPath {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    if (Test-Path -Path Env:EVERGREEN_APPS_PATH) {
        if (Test-Path -Path ${Env:EVERGREEN_APPS_PATH} -PathType "Container") {
            return (Resolve-Path -Path ${Env:EVERGREEN_APPS_PATH}).Path
        }
        else {
            Write-Warning -Message "Environment variable 'EVERGREEN_APPS_PATH' is set but does not point to a valid path."
            return ${Env:EVERGREEN_APPS_PATH}
        }
    }
    else {
        $AppsPath = if (Test-IsWindows) { Join-Path -Path ${Env:LOCALAPPDATA} -ChildPath 'Evergreen' } else { Join-Path -Path $HOME -ChildPath '.evergreen' }
        return $AppsPath
    }
}
