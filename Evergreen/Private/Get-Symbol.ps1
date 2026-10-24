function Get-Symbol {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("Tick", "Cross")]
        [System.String] $Symbol = "Tick"
    )

    switch ($Symbol) {
        "Tick" {
            return [System.String][System.Char]0x2713
        }
        "Cross" {
            return [System.String][System.Char]0x2717
        }
    }
}
