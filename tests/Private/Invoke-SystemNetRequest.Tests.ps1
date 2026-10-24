<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
    $Listener = [System.Net.HttpListener]::new()
    $PortListener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $PortListener.Start()
    $Port = $PortListener.LocalEndpoint.Port
    $PortListener.Stop()
    $BaseUri = "http://127.0.0.1:$Port"
    $Listener.Prefixes.Add("$BaseUri/")
    $Listener.Start()

    $Requests = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $Server = [PowerShell]::Create()
    $null = $Server.AddScript({
        param ($Listener, $Requests)

        while ($Listener.IsListening) {
            $Context = $Listener.GetContext()
            $Response = $Context.Response
            $Path = $Context.Request.Url.AbsolutePath
            $Requests.Enqueue($Path)
            $Body = [System.Text.Encoding]::UTF8.GetBytes("response text")
            $Response.ContentType = "text/plain"
            if ($Path -eq "/redirect") {
                $Response.StatusCode = 302
                $Response.RedirectLocation = "/redirect-again"
            }
            elseif ($Path -eq "/redirect-again") {
                $Response.StatusCode = 307
                $Response.RedirectLocation = "/text"
            }
            elseif ($Path -eq "/not-found") {
                $Response.StatusCode = 404
            }
            elseif ($Path -eq "/authentication") {
                $Response.StatusCode = 401
                $Response.Headers.Add("WWW-Authenticate", "Negotiate")
            }
            elseif ($Path -eq "/latin1") {
                $Response.ContentType = 'text/plain; charset="iso-8859-1"'
                $Body = [byte[]]@(99, 97, 102, 233)
            }
            elseif ($Path -eq "/utf8") {
                $Body = [System.Text.Encoding]::UTF8.GetBytes("caf$([char]233)")
            }
            elseif ($Path -eq "/bom") {
                $Body = [byte[]]([System.Text.Encoding]::Unicode.GetPreamble() +
                    [System.Text.Encoding]::Unicode.GetBytes("caf$([char]233)"))
            }
            elseif ($Path -eq "/invalid-charset") {
                $Response.ContentType = "text/plain; charset=not-a-real-encoding"
            }
            elseif ($Path -eq "/user-agent") {
                $Body = [System.Text.Encoding]::UTF8.GetBytes("UserAgent=[$($Context.Request.UserAgent)]")
            }
            elseif ($Path -eq "/empty") {
                $Body = [byte[]]@()
            }
            $Response.ContentLength64 = $Body.Length
            try {
                if ($Path -eq "/slow-headers") {
                    Start-Sleep -Seconds 2
                }
                if ($Path -eq "/slow-body") {
                    $Response.OutputStream.Write($Body, 0, 1)
                    $Response.OutputStream.Flush()
                    Start-Sleep -Seconds 2
                    $Response.OutputStream.Write($Body, 1, $Body.Length - 1)
                }
                elseif ($Body.Length -gt 0) {
                    $Response.OutputStream.Write($Body, 0, $Body.Length)
                }
                $Response.Close()
            }
            catch [System.Net.HttpListenerException] {
                # Timeout tests intentionally disconnect before the server finishes.
                $Response.Abort()
            }
        }
    }).AddArgument($Listener).AddArgument($Requests)
    $null = $Server.BeginInvoke()
}

AfterAll {
    $Listener.Stop()
    $Listener.Close()
    $Server.Stop()
    $Server.Dispose()
}

Describe -Name "Invoke-SystemNetRequest" {
    Context "Ensure Invoke-SystemNetRequest works as expected" {
        It "Reads <Path> into exactly one string" -TestCases @(
            @{ Path = "/text"; Expected = "response text" }
            @{ Path = "/redirect"; Expected = "response text" }
            @{ Path = "/latin1"; Expected = "caf$([char]233)" }
            @{ Path = "/utf8"; Expected = "caf$([char]233)" }
            @{ Path = "/bom"; Expected = "caf$([char]233)" }
            @{ Path = "/empty"; Expected = "" }
        ) {
            param ($Path, $Expected)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Path = $Path; Expected = $Expected } {
                Mock Test-ProxyEnv { $false }
                $Results = @(Invoke-SystemNetRequest -Uri "$BaseUri$Path" -UserAgent "")
                $Results.Count | Should -Be 1
                $Results[0] | Should -BeOfType [System.String]
                $Results[0] | Should -BeExactly $Expected
            }
        }

        It "Allows an omitted user agent or sends an explicit value" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri } {
                Mock Test-ProxyEnv { $false }
                Mock Get-EvergreenUserAgent { "DefaultAgent" }
                Invoke-SystemNetRequest -Uri "$BaseUri/user-agent" -UserAgent "" | Should -BeExactly "UserAgent=[]"
                Invoke-SystemNetRequest -Uri "$BaseUri/user-agent" -UserAgent "TestAgent" | Should -BeExactly "UserAgent=[TestAgent]"
                Invoke-SystemNetRequest -Uri "$BaseUri/user-agent" | Should -BeExactly "UserAgent=[DefaultAgent]"
            }
        }

        It "Throws for <Path> and remains usable after the error" -TestCases @(
            @{ Path = "/not-found"; Limit = 3 }
            @{ Path = "/redirect"; Limit = 1 }
            @{ Path = "/invalid-charset"; Limit = 3 }
        ) {
            param ($Path, $Limit)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Path = $Path; Limit = $Limit } {
                Mock Test-ProxyEnv { $false }
                {
                    Invoke-SystemNetRequest -Uri "$BaseUri$Path" -UserAgent "" -MaximumRedirection $Limit -WarningAction SilentlyContinue
                } | Should -Throw
                Invoke-SystemNetRequest -Uri "$BaseUri/text" -UserAgent "" | Should -BeExactly "response text"
            }
        }

        It "Does not negotiate origin authentication by default" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Requests = $Requests } {
                Mock Test-ProxyEnv { $false }
                $Before = $Requests.Count
                { Invoke-SystemNetRequest -Uri "$BaseUri/authentication" -UserAgent "" -WarningAction SilentlyContinue } |
                    Should -Throw
                $RecordedRequests = @($Requests.ToArray() | Select-Object -Skip $Before)
                $RecordedRequests.Count | Should -Be 1
                $RecordedRequests[0] | Should -Be "/authentication"
            }
        }

        It "Accepts opt-in origin credentials without an explicit proxy" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri } {
                Mock Test-ProxyEnv { $false }
                Invoke-SystemNetRequest -Uri "$BaseUri/text" -UserAgent "" -UseDefaultCredentials |
                    Should -BeExactly "response text"
            }
        }

        It "Preserves proxy authentication with explicit credentials: <HasProxyAuthentication>" -TestCases @(
            @{ HasProxyAuthentication = $false }
            @{ HasProxyAuthentication = $true }
        ) {
            param ([System.Boolean] $HasProxyAuthentication)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; HasProxyAuthentication = $HasProxyAuthentication } {
                $PreviousProxy = Get-Variable -Name EvergreenProxy -Scope Script -ErrorAction SilentlyContinue | Select-Object -Property Value
                $PreviousCredentials = Get-Variable -Name EvergreenProxyCreds -Scope Script -ErrorAction SilentlyContinue | Select-Object -Property Value
                $Proxy = [System.Net.WebProxy]::new()
                Mock Test-ProxyEnv { $true }
                Mock Test-ProxyEnv { $HasProxyAuthentication } -ParameterFilter { $Creds }
                Mock New-Object { $Proxy } -ParameterFilter { $TypeName -eq "System.Net.WebProxy" }
                try {
                    $script:EvergreenProxy = $BaseUri
                    $script:EvergreenProxyCreds = [System.Management.Automation.PSCredential]::new(
                        "proxy-user", [System.Security.SecureString]::new())
                    Invoke-SystemNetRequest -Uri "$BaseUri/text" -UserAgent "" -UseDefaultCredentials |
                        Should -BeExactly "response text"
                    $Proxy.Address.AbsoluteUri | Should -Be "$BaseUri/"
                    if ($HasProxyAuthentication) {
                        $Proxy.UseDefaultCredentials | Should -BeFalse
                        $Proxy.Credentials | Should -BeOfType [System.Net.NetworkCredential]
                        $Proxy.Credentials.UserName | Should -BeExactly "proxy-user"
                    }
                    else {
                        $Proxy.UseDefaultCredentials | Should -BeTrue
                    }
                }
                finally {
                    if ($null -ne $PreviousProxy) {
                        $script:EvergreenProxy = $PreviousProxy.Value
                    }
                    else {
                        Remove-Variable -Name EvergreenProxy -Scope Script
                    }
                    if ($null -ne $PreviousCredentials) {
                        $script:EvergreenProxyCreds = $PreviousCredentials.Value
                    }
                    else {
                        Remove-Variable -Name EvergreenProxyCreds -Scope Script
                    }
                }
            }
        }

        It "Rejects invalid URI <Uri> before configuring a request" -TestCases @(
            @{ Uri = "relative/path" }
            @{ Uri = "ftp://example.com/file" }
            @{ Uri = "file:///C:/test.txt" }
            @{ Uri = "http://" }
        ) {
            param ($Uri)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ Uri = $Uri } {
                Mock Test-ProxyEnv { $false }
                { Invoke-SystemNetRequest -Uri $Uri -UserAgent "" -WarningAction SilentlyContinue } |
                    Should -Throw "*absolute HTTP or HTTPS URI*"
                Should -Invoke Test-ProxyEnv -Times 0 -Exactly
            }
        }

        It "Rejects invalid numeric parameters" -TestCases @(
            @{ Parameters = @{ MaximumRedirection = 0 } }
            @{ Parameters = @{ MaximumRedirection = -1 } }
            @{ Parameters = @{ TimeoutSec = 0 } }
            @{ Parameters = @{ TimeoutSec = 2147484 } }
            @{ Parameters = @{ ReadWriteTimeoutSec = -1 } }
            @{ Parameters = @{ ReadWriteTimeoutSec = 2147484 } }
        ) {
            param ($Parameters)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ Parameters = $Parameters } {
                { Invoke-SystemNetRequest -Uri "http://127.0.0.1/" -UserAgent "" @Parameters } | Should -Throw
            }
        }

        It "Bounds the wait for <Path>" -TestCases @(
            @{ Path = "/slow-headers"; Parameters = @{ TimeoutSec = 1 } }
            @{ Path = "/slow-body"; Parameters = @{ ReadWriteTimeoutSec = 1 } }
        ) {
            param ($Path, $Parameters)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Path = $Path; Parameters = $Parameters } {
                Mock Test-ProxyEnv { $false }
                $Timer = [System.Diagnostics.Stopwatch]::StartNew()
                {
                    Invoke-SystemNetRequest -Uri "$BaseUri$Path" -UserAgent "" @Parameters -WarningAction SilentlyContinue
                } | Should -Throw
                $Timer.Stop()
                $Timer.ElapsedMilliseconds | Should -BeLessThan 1900
                # Let the single-threaded server finish before the next test.
                Start-Sleep -Milliseconds 1500
            }
        }

        It "Redacts credentials, queries and fragments from verbose and warning messages" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri } {
                Mock Test-ProxyEnv { $false }
                $Uri = $BaseUri.Replace("http://", "http://secret-user:secret-password@") + "/not-found?token=secret-token#secret-fragment"
                $Warnings = @()
                $Messages = @()
                try {
                    Invoke-SystemNetRequest -Uri $Uri -UserAgent "" -Verbose -WarningVariable Warnings -WarningAction SilentlyContinue 4>&1 |
                        ForEach-Object { $Messages += $_.ToString() }
                }
                catch {
                    $_.Exception | Should -Not -BeNullOrEmpty
                }
                $Warnings.Count | Should -Be 2
                $Diagnostics = ($Messages + $Warnings) -join "`n"
                $Diagnostics | Should -Match ([regex]::Escape("$BaseUri/not-found"))
                $Diagnostics | Should -Not -Match "secret-"
            }
        }

        It "Disposes the reader and stream when ReadToEnd fails: <FailRead>" -TestCases @(
            @{ FailRead = $false }
            @{ FailRead = $true }
        ) {
            param ($FailRead)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; FailRead = $FailRead } {
                Mock Test-ProxyEnv { $false }
                $Reader = [PSCustomObject]@{ Stream = $null; Disposed = $false; FailRead = $FailRead }
                $Reader | Add-Member -MemberType ScriptMethod -Name ReadToEnd -Value {
                    if ($this.FailRead) {
                        throw [System.IO.IOException]::new("Test read failure")
                    }
                    return "test content"
                }
                $Reader | Add-Member -MemberType ScriptMethod -Name Dispose -Value {
                    $this.Disposed = $true
                    $this.Stream.Dispose()
                }
                Mock New-Object {
                    $Reader.Stream = $ArgumentList[0]
                    return $Reader
                } -ParameterFilter { $TypeName -eq "System.IO.StreamReader" }
                if ($FailRead) {
                    { Invoke-SystemNetRequest -Uri "$BaseUri/text" -UserAgent "" -WarningAction SilentlyContinue } |
                        Should -Throw "*Test read failure*"
                }
                else {
                    Invoke-SystemNetRequest -Uri "$BaseUri/text" -UserAgent "" | Should -BeExactly "test content"
                }
                $Reader.Disposed | Should -BeTrue
                $Reader.Stream.CanRead | Should -BeFalse
            }
        }

        It "Disposes the stream if reader construction fails" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri } {
                Mock Test-ProxyEnv { $false }
                $State = @{ Stream = $null }
                Mock New-Object {
                    $State.Stream = $ArgumentList[0]
                    throw [System.IO.IOException]::new("Test constructor failure")
                } -ParameterFilter { $TypeName -eq "System.IO.StreamReader" }
                { Invoke-SystemNetRequest -Uri "$BaseUri/text" -UserAgent "" -WarningAction SilentlyContinue } |
                    Should -Throw "*Test constructor failure*"
                $State.Stream.CanRead | Should -BeFalse
            }
        }
    }
}
