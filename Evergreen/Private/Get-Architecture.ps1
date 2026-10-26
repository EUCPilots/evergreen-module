function Get-Architecture {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String] $String
    )

    switch -Regex ($String) {
        "(?<![a-z0-9])aarch64(?![a-z0-9])" { $architecture = "arm64"; break }
        "(?<![a-z0-9])amd64(?![a-z0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9])anycpu(?![a-z0-9])" { $architecture = "any"; break }
        "(?<![a-z0-9])arm64(?![a-z0-9])" { $architecture = "arm64"; break }
        "(?<![a-z0-9])arm32(?![a-z0-9])" { $architecture = "arm32"; break }
        "(?<![a-z0-9])arm(?=$|[^a-z0-9]|v[0-9])" { $architecture = "arm"; break }
        "(?<![a-z0-9])nt64(?![a-z0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9])nt32(?![a-z0-9])" { $architecture = "x86"; break }
        "(?<![a-z0-9])x86_64(?![a-z0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9])x64(?![a-z0-9])" { $architecture = "x64"; break }
        "(?<![0-9])x64(?=[0-9]+(?:$|[^a-z0-9]))" { $architecture = "x64"; break }
        "(?<![a-z0-9])w64(?![a-z0-9])" { $architecture = "x64"; break }
        "-64(?=(?:\.[a-z]{1,5})*(?:$|[/;?#]))" { $architecture = "x64"; break }
        "(?<![a-z0-9])64-bit(?![a-z0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9])64bit(?![a-z0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9])32-bit(?![a-z0-9])" { $architecture = "x86"; break }
        "(?<![a-z0-9])32bit(?![a-z0-9])" { $architecture = "x86"; break }
        "(?<![a-z0-9])x32(?![a-z0-9])" { $architecture = "x86"; break }
        "(?<![a-z0-9])w32(?![a-z0-9])" { $architecture = "x86"; break }
        "-32(?=(?:\.[a-z]{1,5})*(?:$|[/;?#]))" { $architecture = "x86"; break }
        "(?<![a-z0-9])-x86(?![a-z0-9])" { $architecture = "x86"; break }
        "(?<![a-z0-9])x86(?![a-z0-9])" { $architecture = "x86"; break }
        "(?<![a-z0-9])e64\.(?![0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9.])64\.(?![0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9])win64(?![a-z0-9])" { $architecture = "x64"; break }
        "(?<![a-z0-9])win32(?![a-z0-9])" { $architecture = "x86"; break }
        default {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Architecture not found in $String, defaulting to x86."
            $architecture = "x86"
        }
    }
    Write-Output -InputObject $architecture
}