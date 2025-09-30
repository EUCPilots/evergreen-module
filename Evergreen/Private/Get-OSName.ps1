function Get-OSName {
    # OS name based on version
    if ($IsCoreCLR) {
        $os = if ($IsWindows) {
            (Get-CimInstance Win32_OperatingSystem).Caption
        }
        elseif ($IsLinux) {
            (uname)  # Assuming you're in a shell context or using Invoke-Expression
        }
        elseif ($IsMacOS) {
            "macOS"  # Or use `sw_vers` for more granularity
        }
    }
    else {
        # PowerShell 5.1 fallback via WMI
        try {
            $os = (Get-CimInstance Win32_OperatingSystem).Caption
        }
        catch {
            $os = "Unknown Windows"
        }
    }
    return $os
}
