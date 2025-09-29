function Test-IsWindows {
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        # Windows PowerShell 5.1 is only available on Windows
        return $true
    } elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        return $true
    } else {
        return $false
    }
}
