function Get-ModuleResource {
    <#
        .SYNOPSIS
            Reads the module strings from the JSON file and returns a hashtable.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNull()]
        [ValidateScript( { if (Test-Path -Path $_ -PathType 'Leaf') { $true } else { throw "Cannot find file $_" } })]
        [System.String] $Path = (Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "Evergreen.json")
    )

    try {
        Write-Verbose -Message "$($MyInvocation.MyCommand): read module resource strings from: $Path"
        $params = @{
            Path        = $Path
            Raw         = $true
            ErrorAction = "Stop"
        }
        $content = Get-Content @params
        if (Test-PSCore) {
            $script:resourceStringsTable = $content | ConvertFrom-Json -AsHashtable -ErrorAction "Stop"
        }
        else {
            $script:resourceStringsTable = $content | ConvertFrom-Json -ErrorAction "Stop" | ConvertTo-Hashtable
        }
        Write-Output -InputObject $script:resourceStringsTable
    }
    catch {
        Write-Warning -Message "$($MyInvocation.MyCommand): failed to module manifest at: $Path."
        throw $_
    }
}
