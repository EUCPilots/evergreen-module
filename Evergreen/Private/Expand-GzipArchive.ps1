function Expand-GzipArchive {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if (Test-Path -Path $_ -PathType "Leaf") { $true } else { throw "Cannot find path $_." } })]
        [System.String] $Path,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                $ResolvedDestination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_)
                $DestinationDirectory = [System.IO.Path]::GetDirectoryName($ResolvedDestination)
                if ([System.IO.Directory]::Exists($DestinationDirectory)) {
                    $true
                }
                else {
                    throw "Cannot find destination directory $DestinationDirectory."
                }
            })]
        [System.String] $DestinationPath = ($Path -replace "\.gz$", ""),

        [Parameter()]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32] $BufferSize = 1024
    )

    if (-not $PSBoundParameters.ContainsKey("DestinationPath") -and $Path -notmatch "\.gz$") {
        throw "DestinationPath must be specified when Path does not end in .gz."
    }

    $SourceFullPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $DestinationFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
    $PathComparison = [System.StringComparison]::Ordinal
    if (Test-IsWindows) {
        $PathComparison = [System.StringComparison]::OrdinalIgnoreCase
    }
    if ([System.String]::Equals($SourceFullPath, $DestinationFullPath, $PathComparison)) {
        throw "The destination path must be different from the source path."
    }

    $DestinationDirectory = [System.IO.Path]::GetDirectoryName($DestinationFullPath)
    $TemporaryPath = [System.IO.Path]::Combine(
        $DestinationDirectory,
        ".$([System.IO.Path]::GetFileName($DestinationFullPath)).$([System.Guid]::NewGuid().ToString('N')).tmp"
    )
    $InputStream = $null
    $OutputStream = $null
    $GzipStream = $null
    $Succeeded = $false

    try {
        try {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Create input file stream."
            $InputStream = [System.IO.File]::Open(
                $SourceFullPath,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::Read
            )

            Write-Verbose -Message "$($MyInvocation.MyCommand): Create temporary output file stream."
            $OutputStream = [System.IO.File]::Open(
                $TemporaryPath,
                [System.IO.FileMode]::CreateNew,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )

            Write-Verbose -Message "$($MyInvocation.MyCommand): Create Gzip stream."
            $GzipStream = New-Object -TypeName "System.IO.Compression.GzipStream" $InputStream, `
                ([System.IO.Compression.CompressionMode]::Decompress)

            Write-Verbose -Message "$($MyInvocation.MyCommand): Attempt expand: $DestinationPath."
            $Buffer = New-Object -TypeName System.Byte[] -ArgumentList $BufferSize
            while ($true) {
                $Read = $GzipStream.Read($Buffer, 0, $BufferSize)
                if ($Read -le 0) {
                    break
                }
                $OutputStream.Write($Buffer, 0, $Read)
            }
        }
        finally {
            try {
                if ($null -ne $GzipStream) {
                    $GzipStream.Dispose()
                }
            }
            finally {
                try {
                    if ($null -ne $OutputStream) {
                        $OutputStream.Dispose()
                    }
                }
                finally {
                    if ($null -ne $InputStream) {
                        $InputStream.Dispose()
                    }
                }
            }
        }

        if ([System.IO.File]::Exists($DestinationFullPath)) {
            $BackupPath = "$TemporaryPath.bak"
            [System.IO.File]::Replace($TemporaryPath, $DestinationFullPath, $BackupPath)
            [System.IO.File]::Delete($BackupPath)
        }
        else {
            [System.IO.File]::Move($TemporaryPath, $DestinationFullPath)
        }

        $Succeeded = $true
        Write-Verbose -Message "$($MyInvocation.MyCommand): Successfully expanded: $DestinationPath."
        Write-Output -InputObject $DestinationPath
    }
    finally {
        if (-not $Succeeded -and [System.IO.File]::Exists($TemporaryPath)) {
            Remove-Item -LiteralPath $TemporaryPath -Force -ErrorAction Stop
        }
    }
}
