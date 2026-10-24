function Get-FileType {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ -not [System.String]::IsNullOrWhiteSpace($_) })]
        [System.String] $File
    )

    $ParsedUri = $null
    if ([System.Uri]::TryCreate($File, [System.UriKind]::Absolute, [ref]$ParsedUri) -and $ParsedUri.Scheme -in @("http", "https")) {
        $File = $ParsedUri.AbsolutePath
    }

    $FileName = [System.IO.Path]::GetFileName($File)
    if ($FileName.StartsWith(".") -and $FileName.IndexOf(".", 1) -lt 0) {
        $Extension = ""
    }
    else {
        $Extension = [System.IO.Path]::GetExtension($File).TrimStart(".")
    }

    Write-Verbose -Message "$($MyInvocation.MyCommand): found extension: [$Extension]"
    Write-Output -InputObject $Extension
}
