function Get-FileType {
    [OutputType([System.String])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $File
    )

    try {
        $Extension = [System.IO.Path]::GetExtension($File).Split(".")[-1]
        Write-Verbose -Message "$($MyInvocation.MyCommand): found extension: [$Extension]"
        Write-Output -InputObject $Extension
    }
    catch {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Failed to find file extension."
        Write-Output -InputObject "Unknown"
    }
}
