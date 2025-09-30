function Get-Symbol {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("Tick", "Cross")]
        [System.String] $Symbol = "Tick"
    )

    switch ($Symbol) {
        "Tick" {
            return [System.Text.Encoding]::UTF32.GetString((19, 39, 0, 0))
        }
        "Cross" {
            return [System.Text.Encoding]::UTF32.GetString((23, 39, 0, 0))
        }
        default {
            return $null
        }
    }
}
