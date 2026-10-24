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

    begin {
        $Lines = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($Line in $InputObject) {
            $null = $Lines.Add([string]$Line)
        }
    }

    end {
        $Ini = @{}
        $Section = ""
        $Ini[$Section] = @{}
        $CommentCount = 0

        Write-Verbose -Message "$($MyInvocation.MyCommand): Convert INI content."
        switch -Regex ($Lines) {
            "^\[(.+)\]" {
                # Section
                $Section = $matches[1]
                if (-not $Ini.ContainsKey($Section)) {
                    $Ini[$Section] = @{}
                }
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
}
