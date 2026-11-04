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
        [System.Management.Automation.SwitchParameter] $NoProgress,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $VerifyChecksum,

        [Parameter()]
        [ValidateRange(0, 10)]
        [System.Int32] $RetryCount = 3,

        [Parameter()]
        [ValidateRange(0, 60)]
        [System.Int32] $RetryDelaySeconds = 2,

        [Parameter()]
        [ValidateRange(1, 3600)]
        [System.Int32] $MaximumRetryDelaySeconds = 300,

        [Parameter()]
        [ValidateRange(1, 600)]
        [System.Int32] $ConnectionTimeoutSeconds = 30,

        [Parameter()]
        [ValidateRange(1, 86400)]
        [System.Int32] $OperationTimeoutSeconds = 300
    )

    begin {
        if ($PSBoundParameters.ContainsKey("ProxyCredential") -and -not($PSBoundParameters.ContainsKey("Proxy"))) {
            throw [System.ArgumentException]::New("ProxyCredential requires Proxy.")
        }
        if (
            $PSVersionTable.PSVersion -lt [System.Version]"7.4" -and
            $PSBoundParameters.ContainsKey("OperationTimeoutSeconds")
        ) {
            Write-Warning -Message "OperationTimeoutSeconds is only supported by Invoke-WebRequest in PowerShell 7.4 and later."
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

            $ExpectedHashes = @()
            if ($VerifyChecksum) {
                foreach ($algorithm in @("SHA1", "SHA256", "SHA512")) {
                    $hashProperty = $Object.PSObject.Properties[$algorithm]
                    if ($null -ne $hashProperty -and -not [System.String]::IsNullOrWhiteSpace([System.String]$hashProperty.Value)) {
                        $ExpectedHashes += [PSCustomObject]@{
                            Algorithm = $algorithm
                            Value     = ([System.String]$hashProperty.Value).Trim()
                        }
                    }
                }
            }
            $TestFileChecksums = {
                param ([System.String] $FilePath, [PSObject[]] $Hashes)
                $mismatchedAlgorithms = @()
                foreach ($expectedHash in $Hashes) {
                    try {
                        $actualHash = (Get-FileHash -LiteralPath $FilePath -Algorithm $expectedHash.Algorithm -ErrorAction "Stop").Hash
                    }
                    catch {
                        $actualHash = $null
                    }
                    if ($actualHash -ine $expectedHash.Value) {
                        $mismatchedAlgorithms += $expectedHash.Algorithm
                    }
                }
                if ($mismatchedAlgorithms.Count -gt 0) {
                    Write-Warning -Message "Checksum verification failed for '$FilePath' using: $($mismatchedAlgorithms -join ', ')."
                    return $false
                }
                Write-Verbose -Message "Checksum verification passed for '$FilePath' using: $(($Hashes.Algorithm) -join ', ')."
                return $true
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
                    if ($PSVersionTable.PSVersion -ge [System.Version]"7.4") {
                        $params.ConnectionTimeoutSeconds = $ConnectionTimeoutSeconds
                        $params.OperationTimeoutSeconds = $OperationTimeoutSeconds
                    }
                    else {
                        $params.TimeoutSec = $ConnectionTimeoutSeconds
                    }
                    $supportsResume = $PSVersionTable.PSVersion -ge [System.Version]"6.1"
                    if ($supportsResume) {
                        $params.Resume = $true
                    }
                    Write-Verbose -Message "Downloading to: $DownloadFile."
                    $securityProtocol = [System.Net.ServicePointManager]::SecurityProtocol
                    try {
                        [System.Net.ServicePointManager]::SecurityProtocol = $securityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
                        $attempt = 0
                        $maximumAttempts = $RetryCount + 1
                        $downloaded = $false
                        $checksumFailed = $false
                        while (-not $downloaded) {
                            $attempt++
                            try {
                                if (-not $supportsResume -and (Test-Path -LiteralPath $TemporaryFile -PathType "Leaf")) {
                                    Remove-Item -LiteralPath $TemporaryFile -Force -ErrorAction "Stop"
                                }
                                Invoke-WebRequest @params
                                if (-not (Test-Path -LiteralPath $TemporaryFile -PathType "Leaf")) {
                                    throw [System.IO.IOException]::New("The download completed without creating a file: $TemporaryFile.")
                                }
                                if ($VerifyChecksum -and $ExpectedHashes.Count -gt 0 -and -not (& $TestFileChecksums -FilePath $TemporaryFile -Hashes $ExpectedHashes)) {
                                    $checksumFailed = $true
                                    break
                                }
                                if ($VerifyChecksum -and $ExpectedHashes.Count -eq 0) {
                                    Write-Verbose -Message "No supported checksum properties found for '$DownloadFile'; skipping checksum verification."
                                }
                                $downloaded = $true
                            }
                            catch {
                                $requestError = $_
                                $response = $requestError.Exception.Response
                                $statusCode = $null
                                $retryAfterHeader = $null
                                if ($null -ne $response) {
                                    try { $statusCode = [System.Int32]$response.StatusCode } catch { Write-Warning -Message "Failed to parse status code from response." }
                                    try { $retryAfterHeader = [System.String]$response.Headers["Retry-After"] } catch { Write-Warning -Message "Failed to parse Retry-After header from response." }
                                }

                                $retryableStatusCodes = @(408, 429, 500, 502, 503, 504)
                                $retryableExceptionTypes = @(
                                    "System.IO.IOException",
                                    "System.Net.Http.HttpRequestException",
                                    "System.Net.Sockets.SocketException",
                                    "System.Net.WebException",
                                    "System.Threading.Tasks.TaskCanceledException",
                                    "System.TimeoutException"
                                )
                                $isNetworkFailure = $false
                                $currentException = $requestError.Exception
                                while ($null -ne $currentException) {
                                    if ($currentException.GetType().FullName -in $retryableExceptionTypes) {
                                        $isNetworkFailure = $true
                                        break
                                    }
                                    $currentException = $currentException.InnerException
                                }
                                $isRetryable = $isNetworkFailure -or ($statusCode -in $retryableStatusCodes)
                                if (-not $isRetryable -or $attempt -ge $maximumAttempts) {
                                    throw
                                }

                                if (Test-Path -LiteralPath $TemporaryFile -PathType "Leaf") {
                                    Remove-Item -LiteralPath $TemporaryFile -Force -ErrorAction "SilentlyContinue"
                                }

                                $delaySeconds = [System.Int32][System.Math]::Min(
                                    $MaximumRetryDelaySeconds,
                                    $RetryDelaySeconds * [System.Math]::Pow(2, $attempt - 1)
                                )
                                $retryAfterSeconds = 0
                                $parsedRetryAfterSeconds = 0
                                if ([System.Int32]::TryParse($retryAfterHeader, [ref]$parsedRetryAfterSeconds)) {
                                    $retryAfterSeconds = [System.Math]::Max(0, $parsedRetryAfterSeconds)
                                }
                                else {
                                    $retryAfterDate = [System.DateTimeOffset]::MinValue
                                    if ([System.DateTimeOffset]::TryParse($retryAfterHeader, [ref]$retryAfterDate)) {
                                        $retryAfterSeconds = [System.Math]::Max(0, [System.Math]::Ceiling(($retryAfterDate - [System.DateTimeOffset]::UtcNow).TotalSeconds))
                                    }
                                }
                                if ($retryAfterSeconds -gt 0) {
                                    $delaySeconds = [System.Int32][System.Math]::Min(
                                        $MaximumRetryDelaySeconds,
                                        [System.Math]::Max($delaySeconds, $retryAfterSeconds)
                                    )
                                }

                                Write-Verbose -Message "Download attempt $attempt failed. Retrying in $delaySeconds second(s). Error: $($requestError.Exception.Message)"
                                if ($delaySeconds -gt 0) {
                                    Start-Sleep -Seconds $delaySeconds
                                }
                            }
                        }
                        if (-not $checksumFailed) {
                            Move-Item -LiteralPath $TemporaryFile -Destination $DownloadFile -Force:$Force -ErrorAction "Stop"
                        }
                    }
                    finally {
                        [System.Net.ServicePointManager]::SecurityProtocol = $securityProtocol
                        if (Test-Path -LiteralPath $TemporaryFile -PathType "Leaf") {
                            Remove-Item -LiteralPath $TemporaryFile -Force -ErrorAction "SilentlyContinue"
                        }
                    }
                    if ($checksumFailed) {
                        continue
                    }
                    Write-Verbose -Message "Successfully downloaded: $DownloadFile."
                    Write-Output -InputObject (Get-Item -LiteralPath $DownloadFile)
                }
            }
            elseif (Test-Path -LiteralPath $DownloadFile -PathType "Leaf") {
                if ($VerifyChecksum -and $ExpectedHashes.Count -gt 0 -and -not (& $TestFileChecksums -FilePath $DownloadFile -Hashes $ExpectedHashes)) {
                    continue
                }
                if ($VerifyChecksum -and $ExpectedHashes.Count -eq 0) {
                    Write-Verbose -Message "No supported checksum properties found for '$DownloadFile'; skipping checksum verification."
                }
                Write-Verbose -Message "File exists: $DownloadFile."
                Write-Output -InputObject (Get-Item -LiteralPath $DownloadFile)
            }
        }
    }

    end {
        Write-Verbose -Message "Complete."
    }
}
