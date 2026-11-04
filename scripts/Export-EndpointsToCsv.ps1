<#
.SYNOPSIS
Exports Evergreen endpoints to a CSV file.

.DESCRIPTION
This script exports Evergreen endpoints to a CSV file.
It retrieves the endpoints using the Get-EvergreenEndpoint cmdlet and saves them in a CSV file specified by the $Path variable.

.PARAMETER Path
The path of the CSV file to export the endpoints to.

.EXAMPLE
Export-EndpointsToCsv.ps1

This example exports the Evergreen endpoints to a CSV file named "Endpoints.csv" in the current directory.
#>
[CmdletBinding()]
param (
    [System.String]$Path = "./Endpoints.csv"
)

Get-EvergreenEndpoint | ForEach-Object {
    [PSCustomObject]@{
        Application = $_.Application
        Endpoints   = $_.Endpoints -join ","
        Ports       = $_.Ports -join ","
    }
} | Export-Csv -Path $Path -NoTypeInformation -Encoding "Utf8" -Append

$Apps = @("7ZipZS",
    "AdobeAcrobatReaderDC",
    "GitForWindows",
    "KeePass",
    "Microsoft.NET",
    "Microsoft365Apps",
    "MicrosoftAzureCLI",
    "MicrosoftAzureStorageExplorer",
    "MicrosoftWvdMultimediaRedirection",
    "MicrosoftEdge",
    "MicrosoftFSLogix",
    "MicrosoftOneDrive",
    "MicrosoftWvdRtcService",
    "MicrosoftSsms",
    "MicrosoftTeams",
    "MicrosoftVisualStudioCode",
    "NotepadPlusPlus",
    "MicrosoftPowerShell",
    "PuTTY",
    "RemoteDisplayAnalyzer",
    "WinSCP")

$Endpoints = Get-EvergreenEndpoint
$Endpoints | Where-Object { $_.Application -in $Apps } | `
    Select-Object -ExpandProperty "Endpoints" | `
    Select-Object -Unique | `
    Sort-Object | `
    Set-Clipboard
