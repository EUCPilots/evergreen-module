function Resolve-DnsNameWrapper {
    <#
        .SYNOPSIS
            Wrap DNS resolvers and return textual record data.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('\S')]
        [System.String] $Name,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(?:[A-Za-z][A-Za-z0-9-]*|TYPE\d+)$')]
        [System.String] $Type = "A"
    )

    $Name = $Name.Trim()
    $Type = $Type.Trim().ToUpperInvariant()
    $CommandName = $null
    $Response = $null

    if (($PSVersionTable.PSEdition -eq "Desktop") -or ($PSVersionTable.Platform -eq "Win32NT")) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Running on Windows."
        $CommandName = "Resolve-DnsName"
        Import-Module -Name "DnsClient" -ErrorAction "Stop"
        $params = @{
            Name        = $Name
            Type        = $Type
            ErrorAction = "Stop"
        }
        $Response = Resolve-DnsName @params | Where-Object { $_.Type -eq $Type }
    }
    else {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Running on PowerShell Core."
        if (-not (Get-Module -Name "DnsClient-PS" -ListAvailable)) {
            throw "$($MyInvocation.MyCommand): DnsClient-PS is required on macOS and Linux. Install the DnsClient-PS module and try again."
        }

        $CommandName = "Resolve-Dns"
        Import-Module -Name "DnsClient-PS" -ErrorAction "Stop"
        $params = @{
            Query       = $Name
            QueryType   = $Type
            ErrorAction = "Stop"
        }
        $Response = Resolve-Dns @params | Where-Object { $_.Answers.RecordType -eq $Type }
    }

    if ($null -eq $Response) {
        throw "$($MyInvocation.MyCommand): $CommandName returned no $Type records for '$Name'."
    }

    if ($CommandName -eq "Resolve-Dns") {
        $Values = @(
            foreach ($Record in $Response) {
                foreach ($Text in $Record.Answers.Text) {
                    if (-not [System.String]::IsNullOrEmpty([System.String]$Text)) {
                        [System.String]$Text
                    }
                }
            }
        )
    }
    else {
        $Values = @(
            foreach ($Record in $Response) {
                $Value = switch -Regex ($Record.Type) {
                    '^(A|AAAA)$' { $Record.IPAddress; break }
                    '^TXT$' { $Record.Strings; break }
                    '^(CNAME|DNAME|NS|PTR)$' { $Record.NameHost; break }
                    '^MX$' { $Record.NameExchange; break }
                    '^SRV$' { $Record.NameTarget; break }
                    default {
                        foreach ($PropertyName in @("Strings", "IPAddress", "NameHost", "NameExchange", "NameTarget", "PrimaryServer", "Text")) {
                            if ($null -ne $Record.$PropertyName) {
                                $Record.$PropertyName
                                break
                            }
                        }
                    }
                }
                if ($null -ne $Value) {
                    $Value
                }
            }
        )
        $Values = @($Values | ForEach-Object { "$_" } | Where-Object { $_.Length -gt 0 })
    }

    if ($Values.Count -eq 0) {
        throw "$($MyInvocation.MyCommand): $CommandName returned $Type records for '$Name', but no textual record data was available."
    }

    Write-Output -InputObject $Values
}
