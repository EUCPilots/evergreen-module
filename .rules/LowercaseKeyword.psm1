using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic

function Measure-LowercaseKeyword {
    <#
    .SYNOPSIS
        PowerShell keywords and constants should be in lowercase.

    .DESCRIPTION
        PowerShell keywords (function, if, foreach, etc.) and constants ($true, $false, $null) 
        should use lowercase for consistency and best practices.

    .EXAMPLE
        Measure-LowercaseKeyword -ScriptBlockAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]

    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    process {
        $Results = @()
        
        # Define keywords and constants we want to check
        $Keywords = @('function', 'foreach', 'if', 'else', 'elseif', 'return', 'switch', 'param', 
                     'begin', 'process', 'end', 'in', 'do', 'while', 'until', 'for', 'trap', 
                     'throw', 'catch', 'try', 'finally', 'data', 'dynamicparam', 'break', 
                     'continue', 'exit', 'class', 'enum', 'using', 'namespace')
        $Constants = @('$true', '$false', '$null')

        try {
            # Get all tokens from the script
            $Tokens = @()
            $ParseErrors = @()
            [void][System.Management.Automation.Language.Parser]::ParseInput(
                $ScriptBlockAst.ToString(), 
                [ref]$Tokens, 
                [ref]$ParseErrors
            )

            if ($ParseErrors.Count -gt 0) {
                return $Results
            }

            # Track processed token positions to avoid duplicates
            $ProcessedTokens = @{}

            foreach ($Token in $Tokens) {
                $TokenText = $Token.Text
                $LowerTokenText = $TokenText.ToLower()
                
                # Create a unique key for this token position
                $TokenKey = "$($Token.Extent.StartLineNumber):$($Token.Extent.StartColumnNumber):$TokenText"
                
                # Skip if we've already processed this exact token at this position
                if ($ProcessedTokens.ContainsKey($TokenKey)) {
                    continue
                }

                # Check keywords (check text content directly to be more reliable)
                if ($Keywords -contains $LowerTokenText -and $TokenText -cne $LowerTokenText) {
                    $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message  = "Keyword '$TokenText' should be lowercase ('$LowerTokenText')."
                        Extent   = $Token.Extent
                        RuleName = $PSCmdlet.MyInvocation.InvocationName
                        Severity = 'Warning'
                    }
                    $ProcessedTokens[$TokenKey] = $true
                }
                # Check constants
                elseif ($Constants -contains $LowerTokenText -and $TokenText -cne $LowerTokenText) {
                    $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message  = "Constant '$TokenText' should be lowercase ('$LowerTokenText')."
                        Extent   = $Token.Extent
                        RuleName = $PSCmdlet.MyInvocation.InvocationName
                        Severity = 'Warning'
                    }
                    $ProcessedTokens[$TokenKey] = $true
                }
            }

            return $Results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Measure-LowercaseKeyword
