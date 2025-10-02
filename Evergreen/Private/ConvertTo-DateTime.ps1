function ConvertTo-DateTime {
    <#
        .SYNOPSIS
            Return a date/time string converted to a localised short date string.
            Pass the date pattern that the string is in, and it should return in the localised format
    #>
    [OutputType([System.DateTime])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DateTime,

        [Parameter(Position = 1)]
        [System.String] $Pattern = "M/d/yyyy"
    )

    # Convert the date/time passed to the function. If conversion fails, pass the same string back
    try {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Converting: [$DateTime]."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Attempting to convert date format to: $([System.Globalization.CultureInfo]::CurrentUICulture.Name)."
        $ConvertedDateTime = [System.DateTime]::ParseExact($DateTime, $Pattern, [System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat)
        $Output = $ConvertedDateTime.ToShortDateString()
    }
    catch {
        try {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to convert to short date. Falling back to simple conversion."
            $Output = [System.DateTime]$DateTime
        }
        catch {
            Write-Error -Message "$($MyInvocation.MyCommand): Failed to convert date, returning original string."
            $Output = $DateTime
        }
    }

    # Write the output to the pipeline
    Write-Verbose -Message "$($MyInvocation.MyCommand): Returning date: [$Output]."
    Write-Output -InputObject $Output
}
