function Get-Architecture {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String] $String
    )

    switch -Regex ($String.ToLower()) {
        "aarch64"   { $architecture = "ARM64"; break }
        "amd64"     { $architecture = "x64"; break }
        "arm64"     { $architecture = "ARM64"; break }
        "arm32"     { $architecture = "ARM32"; break }
        "arm"       { $architecture = "ARM64"; break }
        "nt64"      { $architecture = "x64"; break }
        "nt32"      { $architecture = "x86"; break }
        "win64"     { $architecture = "x64"; break }
        "win32"     { $architecture = "x86"; break }
        "win-arm64" { $architecture = "ARM64"; break }
        "win-x64"   { $architecture = "x64"; break }
        "win-x86"   { $architecture = "x86"; break }
        "x86_64"    { $architecture = "x64"; break }
        "x64"       { $architecture = "x64"; break }
        "w64"       { $architecture = "x64"; break }
        "-64"       { $architecture = "x64"; break }
        "64-bit"    { $architecture = "x64"; break }
        "64bit"     { $architecture = "x64"; break }
        "32-bit"    { $architecture = "x86"; break }
        "32bit"     { $architecture = "x86"; break }
        "x32"       { $architecture = "x86"; break }
        "w32"       { $architecture = "x86"; break }
        "-32"       { $architecture = "x86"; break }
        "-x86"      { $architecture = "x86"; break }
        "x86"       { $architecture = "x86"; break }
        "e64\."       { $architecture = "x64"; break }
        "64\."       { $architecture = "x64"; break }
        default {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Architecture not found in $String, defaulting to x86."
            $architecture = "x86"
        }
    }
    Write-Output -InputObject $architecture
}