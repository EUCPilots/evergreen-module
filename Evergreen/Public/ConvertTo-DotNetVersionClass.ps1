function ConvertTo-DotNetVersionClass {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
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

        # Split the version string into segments and initialise an array
        $Segments = $Version -split '[._+-]'
        $NormalizedSegments = @()

        # Normalize each segment
        foreach ($Segment in $Segments) {
            $NormalizedSegments += @(Convert-Segment -Segment $Segment)
        }

        # Preserve the first three segments and saturating-sum the remainder into a valid Int32 component.
        if ($NormalizedSegments.Count -gt 4) {
            $TailSum = [System.Int64]0
            foreach ($Segment in $NormalizedSegments[3..($NormalizedSegments.Count - 1)]) {
                if ($Segment -ge ([System.Int32]::MaxValue - $TailSum)) {
                    $TailSum = [System.Int32]::MaxValue
                    break
                }

                $TailSum += $Segment
            }

            $NormalizedSegments = @($NormalizedSegments[0..2]) + [System.Int32]$TailSum
        }

        # If the number of segments is less than 4, pad with zeros
        while ($NormalizedSegments.Count -lt 4) {
            $NormalizedSegments += 0
        }

        # Return the version as a .NET Version class; conversion failures are reported as errors, never strings.
        try {
            return [System.Version]($NormalizedSegments -join ".")
        }
        catch {
            throw [System.ArgumentException]::new(
                "Version '$Version' could not be converted to a .NET Version.",
                "Version",
                $_.Exception
            )
        }
    }
}
