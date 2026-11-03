function Save-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Path")]
    [Alias("sea")]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Pass an application object from Get-EvergreenApp.")]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject] $InputObject,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify a top-level directory path where the application installers will be saved into.",
            ParameterSetName = "Path")]
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "CustomPath")]
        [System.IO.FileInfo] $Path,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify a single directory path where all application installers will be saved into.",
            ParameterSetName = "CustomPath")]
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName,
            ParameterSetName = "Path")]
        [Alias("LiteralPath")]
        [System.IO.FileInfo] $CustomPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [System.String] $Proxy,

        [Parameter(Mandatory = $false, Position = 3)]
        [System.Management.Automation.PSCredential]
        $ProxyCredential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $UserAgent = (Get-EvergreenUserAgent),

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $Force,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $NoProgress
    )

    begin {
        if ($PSBoundParameters.ContainsKey("ProxyCredential") -and -not($PSBoundParameters.ContainsKey("Proxy"))) {
            throw [System.ArgumentException]::New("ProxyCredential requires Proxy.")
        }

        # Disable the Invoke-WebRequest progress bar for faster downloads
        if ($PSBoundParameters.ContainsKey("Verbose") -and !($PSBoundParameters.ContainsKey("NoProgress"))) {
            $ProgressPreference = [System.Management.Automation.ActionPreference]::continue
        }
        else {
            $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        }

    }

    process {
        # Loop through each object and download to the target path
        foreach ($Object in $InputObject) {

            #region Validate the URI property and find the output filename
            if ([System.Boolean]($Object.URI)) {
                Write-Verbose -Message "URL: $($Object.URI)."
                if ([System.Boolean]($Object.FileName)) {
                    $OutFile = $Object.FileName
                }
                elseif ([System.Boolean]($Object.URI)) {
                    $OutFile = Split-Path -Path $Object.URI -Leaf
                }
            }
            else {
                throw [System.Management.Automation.PropertyNotFoundException] "InputObject does not have valid URI property."
            }

            if (
                [System.String]::IsNullOrWhiteSpace([System.String]$OutFile) -or
                [System.IO.Path]::IsPathRooted($OutFile) -or
                $OutFile -in @(".", "..") -or
                $OutFile -match '[/\\]' -or
                $OutFile.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0
            ) {
                throw [System.ArgumentException]::New("InputObject contains an invalid file name: '$OutFile'.")
            }
            if (
                -not [System.String]::IsNullOrWhiteSpace([System.String]$Path) -and
                -not [System.String]::IsNullOrWhiteSpace([System.String]$CustomPath)
            ) {
                throw [System.ArgumentException]::New("Specify either Path or CustomPath, not both.")
            }
            $UseCustomPath = -not [System.String]::IsNullOrWhiteSpace([System.String]$CustomPath)
            $RequestedPath = if ($UseCustomPath) { $CustomPath } else { $Path }
            if ([System.String]::IsNullOrWhiteSpace([System.String]$RequestedPath)) {
                throw [System.ArgumentException]::New("A path must be provided with -Path or -CustomPath.")
            }
            $NewPath = [System.IO.Path]::GetFullPath([System.String]$RequestedPath)
            if (-not (Test-Path -LiteralPath $NewPath -PathType "Container")) {
                if (Test-Path -LiteralPath $NewPath -PathType "Leaf") {
                    throw [System.IO.IOException]::New("The destination path is a file: $NewPath.")
                }
                if ($PSCmdlet.ShouldProcess($NewPath, "Create directory")) {
                    [System.IO.Directory]::CreateDirectory($NewPath) | Out-Null
                }
            }

            # Handle the output path depending on whether -Path or -CustomPath are used
            if ($UseCustomPath) {
                $OutPath = $NewPath
            }
            else {
                if ([System.Boolean]($Object.Version)) {
                    $OutPath = New-EvergreenPath -InputObject $Object -Path $NewPath
                }
                else {
                    throw [System.Management.Automation.PropertyNotFoundException] "InputObject does not have valid Version property."
                }
            }

            $OutPath = [System.IO.Path]::GetFullPath([System.String]$OutPath)
            $DownloadFile = [System.IO.Path]::GetFullPath((Join-Path -Path $OutPath -ChildPath $OutFile))
            $OutPathPrefix = $OutPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            $comparison = if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                [System.StringComparison]::OrdinalIgnoreCase
            }
            else {
                [System.StringComparison]::Ordinal
            }
            if (-not $DownloadFile.StartsWith($OutPathPrefix, $comparison)) {
                throw [System.ArgumentException]::New("The destination file resolves outside the output directory: $DownloadFile.")
            }

            if ($Force -or -not (Test-Path -LiteralPath $DownloadFile -PathType "Leaf")) {
                if ($PSCmdlet.ShouldProcess($DownloadFile, "Download")) {
                    $TemporaryFile = Join-Path -Path $OutPath -ChildPath ".evergreen-$([System.Guid]::NewGuid().ToString('N')).download"
                    $params = @{
                        Uri             = $Object.URI
                        OutFile         = $TemporaryFile
                        UseBasicParsing = $true
                        UserAgent       = $UserAgent
                        ErrorAction     = "Stop"
                    }
                    if ($PSBoundParameters.ContainsKey("Proxy")) {
                        $params.Proxy = $Proxy
                    }
                    if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                        $params.ProxyCredential = $ProxyCredential
                    }
                    Write-Verbose -Message "Downloading to: $DownloadFile."
                    $securityProtocol = [System.Net.ServicePointManager]::SecurityProtocol
                    try {
                        [System.Net.ServicePointManager]::SecurityProtocol = $securityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
                        Invoke-WebRequest @params
                        if (-not (Test-Path -LiteralPath $TemporaryFile -PathType "Leaf")) {
                            throw [System.IO.IOException]::New("The download completed without creating a file: $TemporaryFile.")
                        }
                        Move-Item -LiteralPath $TemporaryFile -Destination $DownloadFile -Force:$Force -ErrorAction "Stop"
                    }
                    finally {
                        [System.Net.ServicePointManager]::SecurityProtocol = $securityProtocol
                        if (Test-Path -LiteralPath $TemporaryFile -PathType "Leaf") {
                            Remove-Item -LiteralPath $TemporaryFile -Force -ErrorAction "SilentlyContinue"
                        }
                    }
                    Write-Verbose -Message "Successfully downloaded: $DownloadFile."
                    Write-Output -InputObject (Get-Item -LiteralPath $DownloadFile)
                }
            }
            elseif (Test-Path -LiteralPath $DownloadFile -PathType "Leaf") {
                Write-Verbose -Message "File exists: $DownloadFile."
                Write-Output -InputObject (Get-Item -LiteralPath $DownloadFile)
            }
        }
    }

    end {
        Write-Verbose -Message "Complete."
    }
}
