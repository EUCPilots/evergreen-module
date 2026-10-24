function ConvertFrom-Jwt {
    <#
        .SYNOPSIS
            Decodes a two- or three-part JWT without verifying its signature.
        .DESCRIPTION
            Returns the decoded header and payload with the original signature segment.
            Throws if the segment count is invalid or either JSON part cannot be decoded.
            Two-part tokens return a null signature; an empty third segment is preserved.
            Signatures and claims, including expiry, are not validated.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.String]$Token
    )

    $parts = $Token -split '\.'
    if ($parts.Count -notin 2, 3) {
        throw "$($MyInvocation.MyCommand): Invalid JWT: must contain exactly two or three parts (header, payload, and optional signature)."
    }

    # Helper: Convert Base64URL to Base64 and decode to JSON
    function Decode-Part([System.String]$Part, [System.String]$Name) {
        # Fix Base64URL encoding (replace - and _)
        $replaced = $Part.Replace('-', '+').Replace('_', '/')
        # Pad string length to multiple of 4
        switch ($replaced.Length % 4) {
            2 { $replaced += '==' }
            3 { $replaced += '=' }
        }
        try {
            $json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($replaced))
            $decoded = ConvertFrom-Json -InputObject $json -ErrorAction "Stop"
            if ($null -eq $decoded) {
                throw "ConvertFrom-Jwt: Decoded JSON must not be null or empty."
            }
            return $decoded
        }
        catch {
            throw "ConvertFrom-Jwt: Failed to decode ${Name}: $($_.Exception.Message)"
        }
    }

    # Return the decoded header and payload as a custom object
    [PSCustomObject]@{
        Header    = Decode-Part -Part $parts[0] -Name "Header"
        Payload   = Decode-Part -Part $parts[1] -Name "Payload"
        Signature = if ($parts.Count -gt 2) { $parts[2] } else { $null }
    } | Write-Output
}
