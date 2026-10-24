function Convert-Segment {
    param (
        [System.Object] $Segment
    )

    if ($null -eq $Segment) {
        throw [System.ArgumentNullException]::new("Segment")
    }
    if ($Segment -isnot [System.String]) {
        throw [System.ArgumentException]::new("Segment must be a string.", "Segment")
    }

    if ($Segment -match '^\d+$') {
        $NumericSegment = 0
        if (-not [System.Int32]::TryParse(
                $Segment,
                [System.Globalization.NumberStyles]::None,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [ref]$NumericSegment
            )) {
            throw [System.OverflowException]::new("Numeric segment '$Segment' exceeds the Int32 range.")
        }

        return $NumericSegment
    }

    if ($Segment.Length -eq 0) {
        return 0
    }

    $HashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        # Hashing is bounded and stable, but distinct text segments can collide.
        $Hash = $HashAlgorithm.ComputeHash([System.Text.Encoding]::Unicode.GetBytes($Segment))
        $Normalized = ([int64]$Hash[0] -shl 24) -bor
            ([int64]$Hash[1] -shl 16) -bor
            ([int64]$Hash[2] -shl 8) -bor
            [int64]$Hash[3]

        return [System.Int32]($Normalized -band [System.Int32]::MaxValue)
    }
    finally {
        $HashAlgorithm.Dispose()
    }
}
