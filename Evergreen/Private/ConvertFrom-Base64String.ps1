function ConvertFrom-Base64String {
    <#
        .SYNOPSIS
        Converts a Base64-encoded value to a lowercase hexadecimal string.

        .DESCRIPTION
        Decodes Base64 data and represents the resulting bytes as lowercase hexadecimal.
        This is useful for converting a Base64-encoded SHA-256 digest to the hexadecimal
        format used by Get-FileHash.

        .PARAMETER Base64String
        Specifies the Base64-encoded value to convert.

        .OUTPUTS
        System.String
        The decoded bytes represented as lowercase hexadecimal.

        .NOTES
        This cmdlet does not support the ShouldProcess functionality.

        .EXAMPLE
        ConvertFrom-Base64String -Base64String "K6fIxnNSlK0jmMNxR5JCiLkc17IqyYBmTZkKCPNH08M="
        # Outputs: "2ba7c8c6735294ad2398c37147924288b91cd7b22ac980664d990a08f347d3c3"
    #>
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
        [System.String] $Base64String
    )

    process {
        $Bytes = [System.Convert]::FromBase64String($Base64String)
        $HexString = [System.BitConverter]::ToString($Bytes).Replace('-', '').ToLowerInvariant()
        Write-Output -InputObject $HexString
    }
}
