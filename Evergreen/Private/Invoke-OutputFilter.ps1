function Invoke-OutputFilter {
    <#
        .SYNOPSIS
            Applies the per-application JSON output filter to pipeline input, if a filter exists.
            Looks for a filter at <AppsPath>/Filters/<Name>.json and passes each input object to
            Get-FilteredData. If no filter exists, input objects are passed through unchanged.
    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    [OutputType([System.Management.Automation.PSObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [AllowNull()]
        [System.Object] $InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name
    )

    begin {
        $FilterPath = [System.IO.Path]::Combine((Get-EvergreenAppsPath), "Filters", "$Name.json")
        $ApplyFilter = Test-Path -Path $FilterPath -PathType "Leaf"
        if ($ApplyFilter) {
            Write-Verbose -Message "Applying output filter from path: $FilterPath"
        }
    }

    process {
        # Pass $null through unchanged; Get-FilteredData requires a non-null InputObject
        if ($ApplyFilter -and $null -ne $InputObject) {
            Get-FilteredData -InputObject $InputObject -FilterPath $FilterPath
        }
        else {
            $InputObject
        }
    }
}
