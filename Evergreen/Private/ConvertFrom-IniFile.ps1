function ConvertFrom-IniFile {
    <#
        .SYNOPSIS
            Converts content from a INI file into a hashtable
            Source: https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/
    #>
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
        $InputObject
    )

    process {
        try {
            $TempFile = New-TemporaryFile -WhatIf:$WhatIfPreference
            Out-File -FilePath $TempFile -InputObject $InputObject
            Write-Verbose -Message "$($MyInvocation.MyCommand): Write INI content to: $TempFile."
        }
        catch {
            throw $_
        }

        try {
            $Ini = @{}
            Write-Verbose -Message "$($MyInvocation.MyCommand): Convert INI content from: $TempFile."
            switch -Regex -File $TempFile {
                "^\[(.+)\]" {
                    # Section
                    $Section = $matches[1]
                    $Ini[$Section] = @{}
                    $CommentCount = 0
                }
                "^(;.*)$" {
                    # Comment
                    $Value = $matches[1]
                    $CommentCount = $CommentCount + 1
                    $Name = "Comment" + $CommentCount
                    $Ini[$Section][$Name] = $Value
                }
                "(.+?)\s*=(.*)" {
                    # Key
                    $Name, $Value = $matches[1..2]
                    $Ini[$Section][$Name] = $Value
                }
            }
            return $Ini
        }
        catch {
            throw $_
        }
        finally {
            Write-Verbose -Message "$($MyInvocation.MyCommand): Delete $TempFile."
            Remove-Item -Path $TempFile -ErrorAction "SilentlyContinue" -WarningAction "SilentlyContinue"
        }
    }
}
