function Resolve-DnsNameWrapper {
    <#
        .SYNOPSIS
            Wrap Resolve-DnsName to filter what's returned
    #>
    #[OutputType([Microsoft.DnsClient.Commands.DnsRecord])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Type = "A"
    )

    # Resolve-DnsName only exists on Windows
    if (($PSVersionTable.PSEdition -eq "Desktop") -or ($PSVersionTable.Platform -eq "Win32NT")) {

        # Wrap Resolve-DnsName
        Write-Verbose -Message "$($MyInvocation.MyCommand): Running on Windows PowerShell."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolving: $Name, with type: $Type."
        try {
            Import-Module -Name "DnsClient" -ErrorAction "SilentlyContinue"
            $params = @{
                Name        = $Name
                Type        = $Type
                ErrorAction = "SilentlyContinue"
            }
            $Response = Resolve-DnsName @params | Where-Object { $_.Type -eq $Type }
        }
        catch {
            throw $_
        }
        if ($null -ne $Response) {
            Write-Output -InputObject $Response.Strings
        }
        else {
            Write-Error -Message "$($MyInvocation.MyCommand): failed to return a useable object from Resolve-DnsName."
        }
    }
    else {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Running on PowerShell Core."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Resolving: $Name, with type: $Type."
        if (Get-Module -Name "DnsClient-PS" -ListAvailable) {
            try {
                Import-Module -Name "DnsClient-PS" -ErrorAction "SilentlyContinue"
                $params = @{
                    Query       = $Name
                    QueryType   = $Type
                    ErrorAction = "Continue"
                }
                $Response = Resolve-Dns @params | Where-Object { $_.Answers.RecordType -eq $Type }
            }
            catch {
                throw $_
            }
            if ($null -ne $Response) {
                Write-Output -InputObject $Response.Answers.Text
            }
            else {
                Write-Error -Message "$($MyInvocation.MyCommand): failed to return a useable object from Resolve-Dns."
            }
        }
        else {
            Write-Warning -Message "$($MyInvocation.MyCommand): This function requires the DnsClient module on Microsoft Windows."
            Write-Warning -Message "$($MyInvocation.MyCommand): To use this module on macOS or Linux, install the DnsClient-PS module."
        }
    }
}
