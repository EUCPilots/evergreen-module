function Resolve-MicrosoftFwLink {
    <#
        .SYNOPSIS
            Resolves https://go.microsoft.com/fwlink URLs

        .DESCRIPTION
            Returns download metadata for the final URL. Date is an invariant
            yyyy-MM-dd string when available, otherwise null. Size is null when
            the response does not advertise a content length.

        .NOTES
            Author: Aaron Parker
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( {
                $ParsedUri = $null
                if (-not [System.Uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$ParsedUri)) {
                    throw "'$_' must be an absolute URL in the format 'https://go.microsoft.com/fwlink/?linkid=2248728'."
                }
                if ($ParsedUri.Scheme -ne "https" -or $ParsedUri.Host -ne "go.microsoft.com" -or $ParsedUri.AbsolutePath -ne "/fwlink/") {
                    throw "'$_' must use https://go.microsoft.com/fwlink/."
                }
                if ($ParsedUri.Query.TrimStart("?") -notmatch "(?i)(?:^|&)linkid=[0-9]+(?:&|$)") {
                    throw "'$_' must include a numeric linkid query parameter."
                }
                $true
            })]
        [System.String[]] $Uri,

        [Parameter()]
        [ValidateRange(0, [System.Int32]::MaxValue)]
        [System.Int32] $MaximumRedirection = 1
    )

    process {
        foreach ($Url in $Uri) {

            # Resolve the URL
            $params = @{
                Uri                = $Url
                MaximumRedirection = $MaximumRedirection
            }
            $ResolvedUrl = Resolve-SystemNetWebRequest @params

            # Find a version number in the final URL path, excluding query parameters.
            $FileName = [System.IO.Path]::GetFileName($ResolvedUrl.ResponseUri.AbsolutePath)
            $VersionMatch = [RegEx]::Match($FileName, "(?<![\d.])(\d+(?:\.\d+){1,4})(?!\.\d)")
            if ($VersionMatch.Success) {
                $Version = $VersionMatch.Groups[1].Value
            }
            else {
                $Version = "Unknown"
                Write-Warning -Message "$($MyInvocation.MyCommand): Failed to match version number from: $($ResolvedUrl.ResponseUri.AbsoluteUri)."
            }

            $Date = $null
            if ($ResolvedUrl.LastModified -gt [DateTime]::MinValue) {
                $Date = ConvertTo-DateTime -DateTime $ResolvedUrl.LastModified -AutoDetect
            }
            $Size = $null
            if ($ResolvedUrl.ContentLength -ge 0) {
                $Size = $ResolvedUrl.ContentLength
            }

            # Output a version object
            [PSCustomObject]@{
                Version      = $Version
                Date         = $Date
                Size         = $Size
                Language     = "Unknown"
                Architecture = Get-Architecture -String $ResolvedUrl.ResponseUri.AbsoluteUri
                Type         = Get-FileType -File $ResolvedUrl.ResponseUri.AbsoluteUri
                URI          = $ResolvedUrl.ResponseUri.AbsoluteUri
            } | Write-Output
        }
    }
}
