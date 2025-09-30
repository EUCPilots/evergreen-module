using namespace System.Management.Automation
function Write-Message {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Information", "Warning", "Fail", "Pass")]
        [System.String] $MessageType = "Information"
    )

    switch ($MessageType) {
        "Information" {
            $ForegroundColor = "Black"
            $BackgroundColor = "DarkGreen"
            $Message = "[i] $Message"
        }
        "Warning" {
            $ForegroundColor = "Black"
            $BackgroundColor = "DarkYellow"
            $Message = "[!] $Message"
        }
        "Pass" {
            $ForegroundColor = "Black"
            $BackgroundColor = "DarkGreen"
            $Message = "[$(Get-Symbol -Symbol "Tick")] $Message"
        }
        "Fail" {
            $ForegroundColor = "White"
            $BackgroundColor = "DarkRed"
            $Message = "[$(Get-Symbol -Symbol "Cross")] $Message"
        }
    }

    try {
        # Ensure the message is padded to the console width
        $Width = [System.Console]::WindowWidth
    }
    catch {
        # Catch issues in headless environments (e.g. CI pipelines)
        # "The handle is invalid"
        $Width = 0
    }

    $Msg = [HostInformationMessage]@{
        Message         = "$($Message.PadRight($Width))"
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline       = $false
    }
    $params = @{
        MessageData       = $Msg
        InformationAction = "Continue"
        Tags              = "Evergreen"
    }
    Write-Information @params
}
