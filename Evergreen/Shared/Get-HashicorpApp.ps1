function Get-HashicorpApp {
    <#
        .SYNOPSIS
            Get the current versions and download URLs for Hashicorp apps.

        .NOTES
            Author: Aaron Parker
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject] $res
    )

    if ($null -eq $res.Get -or $null -eq $res.Get.Update -or $null -eq $res.Get.Download) {
        throw "Get-HashicorpApp: The resource is missing Get.Update or Get.Download configuration."
    }
    if ([string]::IsNullOrWhiteSpace([string]$res.Get.Update.Uri)) {
        throw "Get-HashicorpApp: The resource is missing Get.Update.Uri."
    }
    if ($res.Get.Download.Uri -isnot [System.Collections.IDictionary] -or $res.Get.Download.Uri.Count -eq 0) {
        throw "Get-HashicorpApp: Get.Download.Uri must contain one or more architecture URL templates."
    }
    if ([string]::IsNullOrWhiteSpace([string]$res.Get.Download.ReplaceText)) {
        throw "Get-HashicorpApp: The resource is missing Get.Download.ReplaceText."
    }

    # Pass the repo releases API URL and return a formatted object
    $params = @{
        Uri               = $res.Get.Update.Uri
        MatchVersion      = $res.Get.Update.MatchVersion
        Filter            = $res.Get.Update.MatchFileTypes
        ReturnVersionOnly = $true
    }
    $object = Get-GitHubRepoRelease @params

    # Build the output object
    if ($null -eq $object) {
        return
    }
    if ($object.Version -eq "RateLimited") {
        throw "Get-HashicorpApp: GitHub API rate limit reached; unable to determine the current release version."
    }
    if ([string]::IsNullOrWhiteSpace([string]$object.Version)) {
        throw "Get-HashicorpApp: GitHub did not return a release version."
    }

    foreach ($Architecture in $res.Get.Download.Uri.GetEnumerator()) {
        $Uri = [string]$Architecture.Value
        if ([string]::IsNullOrWhiteSpace($Uri)) {
            throw "Get-HashicorpApp: The download URL template for architecture '$($Architecture.Key)' is empty."
        }
        $Uri = $Uri.Replace([string]$res.Get.Download.ReplaceText, [string]$object.Version)

        $ParsedUri = $null
        if (-not [System.Uri]::TryCreate($Uri, [System.UriKind]::Absolute, [ref]$ParsedUri) -or $ParsedUri.Scheme -notin @("http", "https")) {
            throw "Get-HashicorpApp: The download URL for architecture '$($Architecture.Key)' is not a valid HTTP or HTTPS URI."
        }

        $PSObject = [PSCustomObject] @{
            Version      = $object.Version
            Type         = Get-FileType -File $Uri
            Architecture = $Architecture.Key
            URI          = $Uri
        }
        Write-Output -InputObject $PSObject
    }
}
