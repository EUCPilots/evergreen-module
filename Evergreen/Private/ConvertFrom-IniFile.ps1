function ConvertFrom-IniFile {
    <#
        .SYNOPSIS
            Converts content from an INI file into a hashtable
            Source: https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/
        .OUTPUTS
            System.Collections.Hashtable
            A hashtable keyed by section name, with a hashtable of entries for each section.
            Entries before the first section are stored under the empty section name.
        .PARAMETER InputObject
            INI content as a multiline string, an array of lines, or piped lines.
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
        foreach ($Item in $InputObject) {
            foreach ($Line in ([string]$Item -split '\r\n|\n|\r')) {
                $null = $Lines.Add($Line)
            }
        }
    }

    end {
        $Ini = @{}
        $Section = ""
        $CommentCount = 0

        Write-Verbose -Message "$($MyInvocation.MyCommand): Convert INI content."
        switch -Regex ($Lines) {
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
                if (-not $Ini.ContainsKey($Section)) {
                    $Ini[$Section] = @{}
                }
                $Ini[$Section][$Name] = $Value
            }
            "(.+?)\s*=(.*)" {
                # Key
                $Name, $Value = $matches[1..2]
                if (-not $Ini.ContainsKey($Section)) {
                    $Ini[$Section] = @{}
                }
                $Ini[$Section][$Name] = $Value
            }
        }
        return $Ini
    }
}
