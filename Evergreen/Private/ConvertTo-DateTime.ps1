function ConvertTo-DateTime {
    <#
        .SYNOPSIS
            Convert a date/time string to a DateTime object.
        .DESCRIPTION
            By default, AutoDetect first tries known vendor formats using invariant culture:
            US and day-first dates, 12-hour and 24-hour timestamps, ISO 8601,
            and timestamps with GMT or numeric timezone offsets.
            If none match, it parses common formats using US input culture, then falls
            back to the specified pattern using invariant culture if automatic parsing fails.
            Ambiguous dates are interpreted as month/day/year when automatically detected.
            Use -AutoDetect:$false to parse only with the specified pattern.
            The returned DateTime object is formatted according to the culture of its consumer.
        .EXAMPLE
            ConvertTo-DateTime -DateTime "December 31, 2024 11:45 PM"
        .EXAMPLE
            ConvertTo-DateTime -DateTime "31/12/2024 23:45" -Pattern "dd/MM/yyyy HH:mm"
    #>
    [OutputType([System.DateTime])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DateTime,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Pattern = "M/d/yyyy",

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $AutoDetect = $true
    )

    Write-Verbose -Message "$($MyInvocation.MyCommand): Converting: [$DateTime]."
    $Parsed = $false
    if ($AutoDetect) {
        [System.String[]] $KnownFormats = @(
            "M/d/yyyy"
            "MM/dd/yyyy HH:mm:ss"
            "M/d/yyyy h:mm tt"
            "M/d/yyyy h:mm:ss tt"
            "MM-dd-yyyy"
            "yyyy-MM-dd"
            "yyyy-MM-dd HH:mm:ss"
            "yyyy-MM-dd'T'HH:mm:ss"
            "yyyy-MM-dd'T'HH:mm:ss.FFFFFFFK"
            "ddd, dd MMM yyyy HH:mm:ss GMT"
            "ddd, dd MMM yyyy HH:mm:ss zzz"
            "d/M/yyyy"
            "dd/MM/yyyy hh:mm tt"
            "dd/MM/yyyy hh:mm:ss tt"
            "dd/MM/yyyy HH:mm:ss"
        )
        $Output = [System.DateTime]::MinValue
        $Parsed = [System.DateTime]::TryParseExact(
            $DateTime,
            $KnownFormats,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None,
            [ref] $Output
        )
        if (-not $Parsed) {
            $Parsed = [System.DateTime]::TryParse(
                $DateTime,
                [System.Globalization.CultureInfo]::GetCultureInfo("en-US"),
                [System.Globalization.DateTimeStyles]::None,
                [ref] $Output
            )
        }
    }
    if (-not $Parsed) {
        try {
            $Output = [System.DateTime]::ParseExact(
                $DateTime,
                $Pattern,
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        }
        catch {
            throw "$($MyInvocation.MyCommand): Failed to parse date [$DateTime] using pattern [$Pattern]: $($_.Exception.Message)"
        }
    }

    Write-Verbose -Message "$($MyInvocation.MyCommand): Returning DateTime: [$Output]."
    Write-Output -InputObject $Output
}
