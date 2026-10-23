function ConvertTo-DateTime {
    <#
        .SYNOPSIS
            Convert a date/time string to a DateTime object.
        .DESCRIPTION
            The input is parsed using the specified pattern and invariant culture.
            AutoDetect first tries known vendor formats using invariant culture:
            M/d/yyyy, MM/dd/yyyy HH:mm:ss, yyyy-MM-dd, yyyy-MM-dd'T'HH:mm:ss,
            and yyyy-MM-dd'T'HH:mm:ss.FFFFFFFK.
            If none match, it parses common formats using US input culture instead.
            Ambiguous dates are interpreted as month/day/year in AutoDetect mode.
            The returned DateTime object is formatted according to the culture of its consumer.
        .EXAMPLE
            ConvertTo-DateTime -DateTime "December 31, 2024 11:45 PM" -AutoDetect
        .EXAMPLE
            ConvertTo-DateTime -DateTime "31/12/2024 23:45" -Pattern "dd/MM/yyyy HH:mm"
    #>
    [OutputType([System.DateTime])]
    [CmdletBinding(DefaultParameterSetName = "Exact", SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DateTime,

        [Parameter(Position = 1, ParameterSetName = "Exact")]
        [ValidateNotNullOrEmpty()]
        [System.String] $Pattern = "M/d/yyyy",

        [Parameter(Mandatory = $true, ParameterSetName = "AutoDetect")]
        [System.Management.Automation.SwitchParameter] $AutoDetect
    )

    Write-Verbose -Message "$($MyInvocation.MyCommand): Converting: [$DateTime]."
    if ($AutoDetect) {
        [System.String[]] $KnownFormats = @(
            "M/d/yyyy"
            "MM/dd/yyyy HH:mm:ss"
            "yyyy-MM-dd"
            "yyyy-MM-dd'T'HH:mm:ss"
            "yyyy-MM-dd'T'HH:mm:ss.FFFFFFFK"
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
        if (-not $Parsed) {
            throw "$($MyInvocation.MyCommand): Failed to parse date [$DateTime] using automatic parsing with en-US culture."
        }
    }
    else {
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
