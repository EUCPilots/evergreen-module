
class LogFile {
    [System.String] $Parent = $(if (Test-IsElevated) { "$Env:SystemRoot\Logs\Evergreen" } else { "$Env:ProgramData\Evergreen\Logs" })
    [System.String] $FullName = ""

    LogFile([System.String] $Parent, [System.String] $FullName) {
        $this.Parent = $Parent
        $this.FullName = $FullName
    }
    
    # Parameterless constructor uses defaults
    LogFile() {
        $this.FullName = "$($this.Parent)\EvergreenBuild-$(Get-Date -Format "yyyy-MM-dd").log"
    }
}

function Test-IsElevated {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param()

    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-LogFilePath {
    [CmdletBinding()]
    param (
        [System.String] $Path
    )

    # Create the log file path
    if (-not(Test-Path -Path $Path)) {
        try {
            New-Item -Path $Path -ItemType "Directory" -ErrorAction "Stop" | Out-Null
        }
        catch {
            throw $_
        }
    }

    # Compress the log directory if it is not already compressed
    $Attributes = Get-Item -Path $Path | Select-Object -ExpandProperty "Attributes"
    if (-not($Attributes -band [IO.FileAttributes]::Compressed)) {

        # Compress the log directory; backslash needs to be escaped in the CIM query
        $EscPath = $Path -replace "\\", "\\"
        [void](Get-CimInstance -Query "SELECT * FROM CIM_Directory WHERE Name = '$EscPath'" | Invoke-CimMethod -MethodName "Compress")
    }
}

function Write-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [System.String] $Message,

        [Parameter(Position = 1, Mandatory = $false)]
        [ValidateSet(1, 2, 3)]
        [System.Int16] $LogLevel = 1
    )

    begin {
        # Log file path
        $LogFile = [LogFile]::new()
        Test-LogFilePath -Path $LogFile.Parent
    }

    process {
        # Build the line which will be recorded to the log file
        $TimeGenerated = $(Get-Date -Format "HH:mm:ss.ffffff")
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        $Thread = $([Threading.Thread]::CurrentThread.ManagedThreadId)
        $LineFormat = $Message, $TimeGenerated, (Get-Date -Format "yyyy-MM-dd"), "$($MyInvocation.ScriptName | Split-Path -Leaf -ErrorAction "SilentlyContinue"):$($MyInvocation.ScriptLineNumber)", $Context, $LogLevel, $Thread
        $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">' -f $LineFormat

        # Add content to the log file and output to the console
        Write-Information -MessageData "[$TimeGenerated] $Message" -InformationAction "Continue"
        Add-Content -Value $Line -Path $LogFile.FullName

        # Write-Warning for log level 2 or 3
        if ($LogLevel -eq 3 -or $LogLevel -eq 2) {
            Write-Warning -Message "[$TimeGenerated] $Message"
        }
    }
}

function Start-ProcessWithWait {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String] $FilePath,

        [Parameter(Position = 1)]
        [System.String[]] $ArgumentList
    )

    if (Test-Path -Path $FilePath -PathType "Leaf") {
        try {
            $params = @{
                FilePath     = $FilePath
                ArgumentList = $ArgumentList
                NoNewWindow  = $true
                PassThru     = $true
                Wait         = $false
            }
            $result = Start-Process @params
            do {
                Start-Sleep -Seconds 5
            } while (-not $result.HasExited)
            return $result.ExitCode
        }
        catch {
            Write-LogFile -Message "Execution error: $($_.Exception.Message)" -LogLevel 3
            return 1
        }
    }
    else {
        Write-LogFile -Message "File not found: $FilePath" -LogLevel 2
        return 1
    }
}

function Get-InstalledSoftware {
    $PropertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller",
    "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
    ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") | `
        ForEach-Object {
        Get-ItemProperty -Path $_ -Name $PropertyNames -ErrorAction "SilentlyContinue" | `
            . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
            Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher",
        "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } },
        "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
            Sort-Object -Property "Name", "Publisher"
    }
}

function ConvertTo-UninstallCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String] $UninstallString
    )
    begin {
        $regex = '(?i)"?([A-Z]:\\[^"]*?\.exe|[A-Za-z0-9._-]+\.exe)"?\s*((?:\S+\s*)*)'
    }
    process {
        if ($UninstallString -match $regex) {
            $Exe = $Matches[1]
            $Arguments = $Matches[2]
            [PSCustomObject]@{
                FilePath     = if ($Exe -match "msiexec.exe") { "$Env:SystemRoot\System32\msiexec.exe" } else { $Exe }
                ArgumentList = ($Arguments -replace '\s+', ' ').Trim()
            }
        }
        else {
            return $null
        }
    }
}

function Compare-Version {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $TargetVersion,

        [Parameter(Mandatory = $true)]
        [System.String] $CompareVersion
    )

    try {
        $verT = [System.Version] $TargetVersion
        $verC = [System.Version] $CompareVersion
        if ($verC -gt $verT) {
            return 1
        }
        elseif ($verC -lt $verT) {
            return -1
        }
        else {
            return 0
        }
    }
    catch {
        return $null
    }
}

Get-InstalledSoftware | ForEach-Object {
    if ($null -ne $_.UninstallString) {
        [PSCustomObject]@{
            Name             = $_.Name
            Version          = $_.Version
            UninstallCommand = (ConvertTo-UninstallCommand -UninstallString $_.UninstallString)
        }
    }
}
