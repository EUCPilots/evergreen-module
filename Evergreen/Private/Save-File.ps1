function Save-File {
    <#
        .SYNOPSIS
            Downloads a file with Invoke-WebRequest and returns the downloaded file as a FileInfo object.
    #>
    [OutputType([System.IO.FileInfo])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri
    )

    $downloadUri = $null
    if (-not [System.Uri]::TryCreate($Uri, [System.UriKind]::Absolute, [ref]$downloadUri) -or $downloadUri.Scheme -notin @("http", "https")) {
        throw [System.ArgumentException]::new("Uri must be an absolute HTTP or HTTPS URL.", "Uri")
    }

    $fileName = [System.IO.Path]::GetFileName($downloadUri.AbsolutePath)
    $fileName = [System.Uri]::UnescapeDataString($fileName)
    foreach ($invalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
        $fileName = $fileName.Replace([string]$invalidCharacter, "_")
    }
    if ([string]::IsNullOrWhiteSpace($fileName) -or $fileName -in @(".", "..")) {
        $fileName = "download"
    }

    $uniqueFileName = "$([guid]::NewGuid().ToString('N'))-$fileName"
    $OutFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath $uniqueFileName
    Write-Verbose -Message "$($MyInvocation.MyCommand): Using save path: $OutFile."

    $originalSecurityProtocol = $null
    $restoreSecurityProtocol = $false
    try {
        $params = @{
            Uri             = $Uri
            OutFile         = $OutFile
            UseBasicParsing = $true
            UserAgent       = (Get-EvergreenUserAgent)
        }
        if (Test-PSCore) {
            $params.SslProtocol = "Tls12"
        }
        else {
            $originalSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol
            [System.Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
            $restoreSecurityProtocol = $true
        }
        Invoke-WebRequest @params -ErrorAction Stop | Out-Null
    }
    catch {
        if (Test-Path -LiteralPath $OutFile) {
            try {
                Remove-Item -LiteralPath $OutFile -Force -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "Failed to remove partial download '$OutFile': $($_.Exception.Message)"
            }
        }
        throw
    }
    finally {
        if ($restoreSecurityProtocol) {
            [System.Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
        }
    }

    Get-Item -LiteralPath $OutFile -ErrorAction Stop
}
