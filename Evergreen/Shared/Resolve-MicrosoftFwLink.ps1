function Resolve-MicrosoftFwLink {
    <#
        .SYNOPSIS
            Resolves https://go.microsoft.com/fwlink URLs

        .NOTES
            Author: Aaron Parker
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( {
                if ($_ -match "^(https:\/\/go\.microsoft\.com\/fwlink\/\?linkid=)([0-9]+).*$") { $true }
                else {
                    throw "'$_' must be in the format 'https://go.microsoft.com/fwlink/?linkid=2248728'."
                }
            })]
        [System.String[]] $Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
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

            try {
                # Find the version number
                $Version = [RegEx]::Match($ResolvedUrl.ResponseUri.AbsoluteUri, "(\d+(\.\d+){1,4}).*").Captures.Groups[1].Value
            }
            catch {
                $Version = "Unknown"
                Write-Warning -Message "$($MyInvocation.MyCommand): Failed to match version number from: $($ResolvedUrl.ResponseUri.AbsoluteUri)."
            }

            # Output a version object
            [PSCustomObject]@{
                Version      = $Version
                Date         = $ResolvedUrl.LastModified.ToShortDateString()
                Size         = $ResolvedUrl.ContentLength
                Language     = "Unknown"
                Architecture = Get-Architecture -String $ResolvedUrl.ResponseUri.AbsoluteUri
                Type         = Get-FileType -File $ResolvedUrl.ResponseUri.AbsoluteUri
                URI          = $ResolvedUrl.ResponseUri.AbsoluteUri
            } | Write-Output
        }
    }
}
