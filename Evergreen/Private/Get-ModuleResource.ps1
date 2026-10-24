function Get-ModuleResource {
    <#
        .SYNOPSIS
            Reads the module strings from the JSON file and returns a hashtable.
    #>
    [OutputType([System.Collections.IDictionary])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNull()]
        [ValidateScript( { if (Test-Path -LiteralPath $_ -PathType 'Leaf') { $true } else { throw "Cannot find file $_" } })]
        [System.String] $Path = (Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "Evergreen.json")
    )

    try {
        Write-Verbose -Message "$($MyInvocation.MyCommand): read module resource strings from: $Path"
        $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction "Stop"
        if (Test-PSCore) {
            $resourceStringsTable = ConvertFrom-Json -InputObject $content -AsHashtable -ErrorAction "Stop"
        }
        else {
            $object = ConvertFrom-Json -InputObject $content -ErrorAction "Stop"
            $resourceStringsTable = ConvertTo-Hashtable -InputObject $object
        }

        if ($resourceStringsTable -isnot [System.Collections.IDictionary]) {
            throw [System.IO.InvalidDataException]::New("$($MyInvocation.MyCommand): module resource root must be a JSON object: $Path.")
        }

        Write-Output -InputObject $resourceStringsTable
    }
    catch {
        Write-Warning -Message "$($MyInvocation.MyCommand): failed to load module resource from [$Path]: $($_.Exception.Message)"
        throw
    }
}
