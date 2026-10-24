function Get-FunctionResource {
    <#
        .SYNOPSIS
            Reads an application manifest from JSON and returns a hashtable.
    #>
    [OutputType([System.Collections.IDictionary])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if ([System.String]::IsNullOrWhiteSpace($_)) {
                throw "AppName cannot be empty or whitespace."
            }
            if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($_) -or $_ -match '[\\/]' -or [System.IO.Path]::GetFileName($_) -cne $_ -or $_ -in @(".", "..")) {
                throw "AppName must be a manifest name, not a path or wildcard pattern."
            }
            if ($_ -match '[<>:"|\x00-\x1F]') {
                throw "AppName contains characters that are not valid in a manifest filename."
            }
            $true
        })]
        [System.String] $AppName
    )

    # Setup path to the manifests folder and the app manifest
    $Path = Join-Path -Path (Get-EvergreenAppsPath) -ChildPath "Manifests"
    $AppManifest = Join-Path -Path $Path -ChildPath "$AppName.json"

    # Read the content from the manifest file
    if (-not (Test-Path -LiteralPath $AppManifest -PathType "Leaf")) {
        throw [System.IO.FileNotFoundException]::New("$($MyInvocation.MyCommand): manifest does not exist: $AppManifest.")
    }
    Write-Verbose -Message "$($MyInvocation.MyCommand): read application resource strings from [$AppManifest]"
    $content = Get-Content -LiteralPath $AppManifest -Raw -Encoding UTF8 -ErrorAction Stop

    # Convert the content from JSON into a hashtable
    try {
        if (Test-PSCore) {
            $hashTable = ConvertFrom-Json -InputObject $content -AsHashtable -ErrorAction Stop
        }
        else {
            $object = ConvertFrom-Json -InputObject $content -ErrorAction Stop
            $hashTable = ConvertTo-Hashtable -InputObject $object
        }
    }
    catch {
        Write-Warning -Message "$($MyInvocation.MyCommand): failed to parse manifest JSON from [$AppManifest]."
        throw
    }

    if ($hashTable -isnot [System.Collections.IDictionary]) {
        throw [System.IO.InvalidDataException]::New("$($MyInvocation.MyCommand): manifest root must be a JSON object: $AppManifest.")
    }

    Write-Output -InputObject $hashTable
}
