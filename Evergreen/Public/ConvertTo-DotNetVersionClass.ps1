function ConvertTo-DotNetVersionClass {
    <#
        .SYNOPSIS
            Converts a version string to a four-component .NET Version.
        .DESCRIPTION
            Separators (period, underscore, plus, and hyphen) delimit version components.
            Numeric components must use ASCII digits. Text components are mapped to stable
            SHA-256-derived integers; this permits conversion but does not preserve semantic
            version ordering. Components after the third are summed into the fourth component,
            saturating at Int32.MaxValue.
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Version])]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "A version string to convert to a standard .NET compliant version class.")]
        [ValidateNotNullOrEmpty()]
        [System.String] $Version
    )

    process {
        if ([System.String]::IsNullOrWhiteSpace($Version)) {
            throw [System.ArgumentException]::new("Version must not be empty or whitespace.", "Version")
        }

        if ($Version -match '(^[._+-]|[._+-]$|[._+-]{2})') {
            throw [System.ArgumentException]::new(
                "Version '$Version' contains an empty segment. Separators must be single and occur between segments.",
                "Version"
            )
        }

        # Normalize into a fixed-size list and reuse one hash instance for text segments.
        $Segments = $Version -split '[._+-]'
        $NormalizedSegments = [System.Collections.Generic.List[System.Int32]]::new()
        $TailSum = [System.Int64]0
        $HashAlgorithm = $null
        $SegmentIndex = 0

        try {
            foreach ($Segment in $Segments) {
                if ($Segment.Length -gt 0 -and
                    $Segment -notmatch '^[0-9]+$' -and
                    $Segment -notmatch '^\p{Nd}+$' -and
                    $null -eq $HashAlgorithm) {
                    $HashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
                }

                $NormalizedSegment = Convert-Segment -Segment $Segment -HashAlgorithm $HashAlgorithm
                if ($SegmentIndex -lt 3) {
                    $NormalizedSegments.Add($NormalizedSegment)
                }
                elseif ($TailSum -lt [System.Int32]::MaxValue) {
                    if ($NormalizedSegment -ge ([System.Int32]::MaxValue - $TailSum)) {
                        $TailSum = [System.Int32]::MaxValue
                    }
                    else {
                        $TailSum += $NormalizedSegment
                    }
                }

                $SegmentIndex++
            }
        }
        finally {
            if ($null -ne $HashAlgorithm) {
                $HashAlgorithm.Dispose()
            }
        }

        if ($SegmentIndex -gt 3) {
            $NormalizedSegments.Add([System.Int32]$TailSum)
        }

        while ($NormalizedSegments.Count -lt 4) {
            $NormalizedSegments.Add(0)
        }

        return [System.Version]::new(
            $NormalizedSegments[0],
            $NormalizedSegments[1],
            $NormalizedSegments[2],
            $NormalizedSegments[3]
        )
    }
}
