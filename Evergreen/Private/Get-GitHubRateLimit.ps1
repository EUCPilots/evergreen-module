function Get-GitHubRateLimit {
    <#
        Check that we aren't rate limited
        https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param ()

    process {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Checking for how many requests to the GitHub API we have left."
        $Headers = @{}
        # If GITHUB_TOKEN or GH_TOKEN exists, let's add that to the API request
        if (-not [System.String]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
            $Headers.Authorization = "token $env:GITHUB_TOKEN"
        }
        elseif (-not [System.String]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
            $Headers.Authorization = "token $env:GH_TOKEN"
        }

        $RequestParams = @{
            Uri         = "https://api.github.com/rate_limit"
            ErrorAction = "Stop"
        }
        if ($Headers.Count -gt 0) {
            $RequestParams.Headers = $Headers
        }
        $GitHubRate = Invoke-EvergreenRestMethod @RequestParams

        $Rate = $null
        if ($null -ne $GitHubRate) {
            $RateProperty = $GitHubRate.PSObject.Properties["rate"]
            if ($null -ne $RateProperty) {
                $Rate = $RateProperty.Value
            }
        }
        if ($null -eq $Rate) {
            throw [System.IO.InvalidDataException]::new(
                "The GitHub rate limit response is missing the required 'rate.remaining' or 'rate.reset' properties."
            )
        }

        $RemainingProperty = $Rate.PSObject.Properties["remaining"]
        $ResetProperty = $Rate.PSObject.Properties["reset"]
        if ($null -eq $RemainingProperty -or $null -eq $ResetProperty) {
            throw [System.IO.InvalidDataException]::new(
                "$($MyInvocation.MyCommand): The GitHub rate limit response is missing the required 'rate.remaining' or 'rate.reset' properties."
            )
        }

        $Remaining = 0L
        $Reset = 0L
        $NumberStyles = [System.Globalization.NumberStyles]::Integer
        $Culture = [System.Globalization.CultureInfo]::InvariantCulture
        if (-not [long]::TryParse([string]$Rate.remaining, $NumberStyles, $Culture, [ref]$Remaining) -or
            -not [long]::TryParse([string]$Rate.reset, $NumberStyles, $Culture, [ref]$Reset)) {
            throw [System.IO.InvalidDataException]::new(
                "$($MyInvocation.MyCommand): The GitHub rate limit response contains invalid 'rate.remaining' or 'rate.reset' values."
            )
        }

        try {
            $ResetWindow = [System.DateTimeOffset]::FromUnixTimeSeconds($Reset).ToLocalTime()
        }
        catch [System.ArgumentOutOfRangeException] {
            throw [System.IO.InvalidDataException]::new(
                "The GitHub rate limit response contains a 'rate.reset' value outside the supported Unix timestamp range.",
                $_.Exception
            )
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand): We have $Remaining requests left to the GitHub API in this window."
        Write-Verbose -Message "$($MyInvocation.MyCommand): Rate limit window resets at: $($ResetWindow.ToString('d')) $($ResetWindow.ToString('t'))."
        if ($Remaining -eq 0) {
            Write-Warning -Message "$($MyInvocation.MyCommand): Requests to GitHub are being rate limited."
        }

        # Output the .rate property
        Write-Output -InputObject $GitHubRate.rate
    }
}
