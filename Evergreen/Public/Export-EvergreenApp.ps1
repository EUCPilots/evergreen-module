function Export-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Pass an application object from Get-EvergreenApp.")]
        [ValidateNotNull()]
        [System.Array] $InputObject,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify the path to the JSON file.",
            ParameterSetName = "Path")]
        [ValidateNotNull()]
        [System.IO.FileInfo] $Path
    )

    begin {
        $InputItems = [System.Collections.Generic.List[System.Object]]::new()
    }

    process {
        foreach ($Item in $InputObject) {
            $InputItems.Add($Item)
        }
    }

    end {
        if ($InputItems.Count -eq 0) {
            throw [System.ArgumentException]::new("At least one application version must be provided.", "InputObject")
        }

        $TargetPath = $Path.FullName
        $AllItems = [System.Collections.Generic.List[System.Object]]::new()
        foreach ($Item in $InputItems) {
            $AllItems.Add($Item)
        }

        if (Test-Path -LiteralPath $TargetPath -PathType "Leaf") {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Reading existing application versions from '$TargetPath'."
            $Content = Get-Content -LiteralPath $TargetPath -Raw -ErrorAction "Stop" -Verbose:$VerbosePreference |
                ConvertFrom-Json -ErrorAction "Stop"
            foreach ($Item in @($Content)) {
                if ($null -ne $Item) {
                    $AllItems.Add($Item)
                }
            }
        }

        # Normalise URLs that can change on each request
        foreach ($AppLibInfo in $AllItems) {
            if (([System.Uri]$AppLibInfo.URI).Host -like "*.dl.sourceforge.net") {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Normalise Sourceforge download mirror URL"
                $AppLibInfo.URI = $AppLibInfo.URI -replace ([System.Uri]$AppLibInfo.URI).Host, "nchc.dl.sourceforge.net"
            }
        }

        # Keep unique records and sort valid versions numerically before nonstandard version strings.
        Write-Verbose -Message "$($MyInvocation.MyCommand): Input object count: $($AllItems.Count)"
        $Properties = $AllItems | Get-Member |
            Where-Object { $_.MemberType -eq "NoteProperty" } | Select-Object -ExpandProperty "Name" -Unique | `
            Sort-Object -Descending
        $UniqueItems = @($AllItems | Select-Object -Unique -Property $Properties)
        $ItemsWithSortData = for ($Index = 0; $Index -lt $UniqueItems.Count; $Index++) {
            Get-VersionItemSortData -Item $UniqueItems[$Index] -Index $Index
        }
        $SortedItems = @(
            $ItemsWithSortData | Sort-Object -Property `
                @{ Expression = { $_.HasParsedVersion }; Descending = $true }, `
                @{ Expression = { $_.ParsedVersion }; Descending = $false }, `
                @{ Expression = { $_.VersionText }; Descending = $false }, `
                @{ Expression = { $_.Index }; Descending = $false }
        )
        $OutputObject = @($SortedItems | Select-Object -ExpandProperty "Item")
        Write-Verbose -Message "$($MyInvocation.MyCommand): Output object count: $($OutputObject.Count)"

        $Json = ConvertTo-Json -InputObject $OutputObject -Depth 100 -ErrorAction "Stop"
        if ($PSCmdlet.ShouldProcess($TargetPath, "Write application versions")) {
            $Json | Out-File -FilePath $TargetPath -Encoding "Utf8" -NoNewline `
                -ErrorAction "Stop" -Verbose:$VerbosePreference
            $Output = [PSCustomObject] @{
                Path = Resolve-Path -LiteralPath $TargetPath -ErrorAction "Stop"
            }
            Write-Output -InputObject $Output
        }
    }
}
