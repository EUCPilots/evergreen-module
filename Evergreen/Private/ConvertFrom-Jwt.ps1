function ConvertFrom-Jwt {
    param(
        [Parameter(Mandatory = $true)]
        [System.String]$Token
    )

    # Split the token into its three parts
    $parts = $Token -split '\.'
    if ($parts.Count -lt 2) {
        throw "$($MyInvocation.MyCommand): Invalid JWT: must contain at least two parts (header and payload)."
    }

    # Helper: Convert Base64URL to Base64 and decode to JSON
    function Decode-Part([System.String]$Part) {
        # Fix Base64URL encoding (replace - and _)
        $replaced = $Part.Replace('-', '+').Replace('_', '/')
        # Pad string length to multiple of 4
        switch ($replaced.Length % 4) {
            2 { $replaced += '==' }
            3 { $replaced += '=' }
        }
        try {
            $json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($replaced))
            return (ConvertFrom-Json -InputObject $json)
        }
        catch {
            Write-Warning -Message "$($MyInvocation.MyCommand): Failed to decode part: $($_.Exception.Message)"
            return $null
        }
    }

    # Return the decoded header and payload as a custom object
    [PSCustomObject]@{
        Header    = Decode-Part -Part $parts[0]
        Payload   = Decode-Part -Part $parts[1]
        Signature = if ($parts.Count -gt 2) { $parts[2] } else { $null }
    } | Write-Output
}
