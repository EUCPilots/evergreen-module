function Get-FunctionResource {
    <#
        .SYNOPSIS
            Reads the function strings from the JSON file and returns a hashtable.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [System.String] $AppName
    )

    # Setup path to the manifests folder and the app manifest
    # $Path = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "Manifests"
    $Path = Join-Path -Path (Get-EvergreenAppsPath) -ChildPath "Manifests"
    $AppManifest = Join-Path -Path $Path -ChildPath "$AppName.json"

    # Read the content from the manifest file
    if (Test-Path -Path $AppManifest) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): read application resource strings from [$AppManifest]"
        $content = Get-Content -Path $AppManifest -Raw
    }
    else {
        throw [System.IO.FileNotFoundException]::New("$($MyInvocation.MyCommand): manifest does not exist: $AppManifest.")
    }

    # Convert the content from JSON into a hashtable
    try {
        if (Test-PSCore) {
            $hashTable = $content | ConvertFrom-Json -AsHashtable
        }
        else {
            $hashTable = $content | ConvertFrom-Json | ConvertTo-Hashtable
        }
    }
    catch {
        Write-Warning -Message "$($MyInvocation.MyCommand): failed to convert strings to required hashtable object."
        throw $_
    }

    # If we got a hashtable, return it to the pipeline
    if ($null -ne $hashTable) {
        Write-Output -InputObject $hashTable
    }
}
