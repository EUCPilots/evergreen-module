using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic

function Measure-PascalCase {
    <#
    .SYNOPSIS
        The variables names should be in PascalCase.

    .DESCRIPTION
        Variable names should use a consistent capitalization style, i.e. : PascalCase.
        In PascalCase, only the first letter is capitalized. Or, if the variable name is made of multiple concatenated words,
        only the first letter of each concatenated word is capitalized.
        To fix a violation of this rule, please consider using PascalCase for variable names.

    .EXAMPLE
        Measure-PascalCase -ScriptBlockAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]

    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

    .NOTES
        https://msdn.microsoft.com/en-us/library/dd878270(v=vs.85).aspx
        https://msdn.microsoft.com/en-us/library/ms229043(v=vs.110).aspx
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    process {
        $Results = @()
        try {
            #region Define predicates to find ASTs.
            [ScriptBlock]$Predicate = {
                param ([System.Management.Automation.Language.Ast]$Ast)
                [bool]$ReturnValue = $false
                if ($Ast -is [System.Management.Automation.Language.AssignmentStatementAst]) {
                    [System.Management.Automation.Language.AssignmentStatementAst]$VariableAst = $Ast
                    if ($VariableAst.Left.VariablePath.UserPath -cnotmatch '^([A-Z][a-z]+)+$') {
                        $ReturnValue = $true
                    }
                }
                return $ReturnValue
            }
            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]]$Violations = $ScriptBlockAst.FindAll($Predicate, $true)
            if ($Violations.Count -ne 0) {
                foreach ($Violation in $Violations) {
                    $Result = New-Object `
                        -TypeName "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                        -ArgumentList "$((Get-Help $MyInvocation.MyCommand.Name).Description.Text)", $Violation.Extent, $PSCmdlet.MyInvocation.InvocationName, Information, $null
                    $Results += $Result
                }
            }
            return $Results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Measure-PascalCase
