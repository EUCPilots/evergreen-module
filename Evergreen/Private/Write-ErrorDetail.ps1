function Write-ErrorDetail {
    <#
        .SYNOPSIS
            Writes the details of an ErrorRecord to the warning stream, including the exception type and message,
            the function name, script file and line number where the error occurred, and the full script stack trace.
            Used to surface the origin of errors thrown from app, shared and private functions.
    #>
    [OutputType([System.Void])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord] $ErrorRecord,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String] $LastFrame
    )

    process {
        # Report the exception type and message
        Write-Warning -Message "Error: [$($ErrorRecord.Exception.GetType().FullName)] $($ErrorRecord.Exception.Message)"

        # Report where the error originated - function name, script file and line number
        $Invocation = $ErrorRecord.InvocationInfo
        if ($null -ne $Invocation -and $Invocation.ScriptLineNumber -gt 0) {
            $FunctionName = if ($null -ne $Invocation.MyCommand -and -not [System.String]::IsNullOrWhiteSpace($Invocation.MyCommand.Name)) {
                $Invocation.MyCommand.Name
            }
            else {
                "<ScriptBlock>"
            }
            $ScriptName = if ([System.String]::IsNullOrWhiteSpace($Invocation.ScriptName)) { "<No file>" } else { $Invocation.ScriptName }
            Write-Warning -Message "Error source: '$FunctionName' in '$ScriptName' at line $($Invocation.ScriptLineNumber), char $($Invocation.OffsetInLine)."
            if (-not [System.String]::IsNullOrWhiteSpace($Invocation.Line)) {
                Write-Warning -Message "Error line: $($Invocation.Line.Trim())"
            }
        }

        # Report the full script stack trace - each frame includes the function name, script file and line number
        if (-not [System.String]::IsNullOrWhiteSpace($ErrorRecord.ScriptStackTrace)) {
            Write-Warning -Message "Stack trace:"
            foreach ($Frame in ($ErrorRecord.ScriptStackTrace -split "\r?\n")) {
                Write-Warning -Message "    $Frame"

                # Stop after the specified function so that frames from the caller's context are not displayed
                if ($PSBoundParameters.ContainsKey("LastFrame") -and $Frame -match "^at $LastFrame[<,]") {
                    break
                }
            }
        }
    }
}
