<#
    .SYNOPSIS
        Private Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

BeforeDiscovery {
}

BeforeAll {
    $PortListener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $PortListener.Start()
    $Port = $PortListener.LocalEndpoint.Port
    $PortListener.Stop()
    $BaseUri = "http://127.0.0.1:$Port"
    $Listener = [System.Net.HttpListener]::new()
    $Listener.Prefixes.Add("$BaseUri/")
    $Listener.Start()
    $Requests = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $ReleaseBody = [System.Threading.ManualResetEvent]::new($false)
    $Server = [PowerShell]::Create()
    $null = $Server.AddScript({
        param ($Listener, $Requests, $ReleaseBody)

        while ($Listener.IsListening) {
            $Context = $Listener.GetContext()
            $Path = $Context.Request.Url.AbsolutePath
            $Requests.Enqueue("$($Context.Request.HttpMethod) $Path")
            $Response = $Context.Response
            if ($Path -eq "/no-head" -or ($Context.Request.HttpMethod -eq "HEAD" -and $Path -like "/get-*")) {
                $Response.StatusCode = 405
            }
            elseif ($Path -eq "/get-redirect") {
                $Response.StatusCode = 302
                $Response.RedirectLocation = "/nested/redirect"
            }
            elseif ($Path -eq "/get-error") {
                $Response.StatusCode = 403
            }
            elseif ($Path -eq "/redirect") {
                $Response.StatusCode = 302
                $Response.RedirectLocation = "/nested/redirect"
            }
            elseif ($Path -eq "/nested/redirect") {
                $Response.StatusCode = 307
                $Response.RedirectLocation = "../file"
            }
            elseif ($Path -eq "/missing-location") {
                $Response.StatusCode = 302
            }
            elseif ($Path -eq "/not-found") {
                $Response.StatusCode = 404
            }
            else {
                $Response.StatusCode = 200
                $Response.ContentLength64 = 1073741824
                if ($Context.Request.HttpMethod -eq "GET") {
                    $Response.OutputStream.WriteByte(0)
                    $Response.OutputStream.Flush()
                    $null = $ReleaseBody.WaitOne(10000)
                }
            }
            $Response.Close()
        }
    }).AddArgument($Listener).AddArgument($Requests).AddArgument($ReleaseBody)
    $null = $Server.BeginInvoke()
}

AfterAll {
    $null = $ReleaseBody.Set()
    $Listener.Stop()
    $Listener.Close()
    $Server.Stop()
    $Server.Dispose()
    $ReleaseBody.Dispose()
}

Describe -Name "Resolve-InvokeWebRequest" {
    It "Explains HEAD resolution and redirect behavior without logging header values" {
        InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri } {
            Mock Test-ProxyEnv { $false }
            $Records = @(Resolve-InvokeWebRequest -Uri "$BaseUri/redirect" -UserAgent "" -Headers @{ Authorization = "secret-value" } -Verbose 4>&1)
            $Output = @($Records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] })
            $Output.Count | Should -Be 1
            $Output[0] | Should -Be "$BaseUri/nested/redirect"
            $Messages = ($Records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
            $Messages | Should -Match "Request: HEAD"
            $Messages | Should -Match "custom headers: \[1\]"
            $Messages | Should -Match "Response: HTTP \[302\]"
            $Messages | Should -Match "Returning redirect target without requesting it"
            $Messages | Should -Match "Resolution finished in \[\d+\] ms"
            $Messages | Should -Not -Match "secret-value"
        }
    }

    It "Resolves <Path> with redirect limit <Limit> to <Expected>" -TestCases @(
        @{ Path = "/redirect"; Limit = 0; Expected = "/nested/redirect" }
        @{ Path = "/redirect"; Limit = 1; Expected = "/file" }
        @{ Path = "/redirect"; Limit = 3; Expected = "/file" }
        @{ Path = "/nested/redirect"; Limit = 0; Expected = "/file" }
        @{ Path = "/file"; Limit = 0; Expected = "/file" }
    ) {
        param ($Path, $Limit, $Expected)

        InModuleScope -ModuleName "Evergreen" -Parameters @{
            BaseUri = $BaseUri; Path = $Path; Limit = $Limit; Expected = $Expected
        } {
            Mock Test-ProxyEnv { $false }
            $Result = @(Resolve-InvokeWebRequest -Uri "$BaseUri$Path" -UserAgent "" -MaximumRedirection $Limit -ErrorAction Stop)
            $Result.Count | Should -Be 1
            $Result[0] | Should -BeOfType [System.String]
            $Result[0] | Should -Be "$BaseUri$Expected"
        }
    }

    It "Uses HEAD and does not request the redirect target by default" {
        InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Requests = $Requests } {
            Mock Test-ProxyEnv { $false }
            $Before = $Requests.Count
            $null = Resolve-InvokeWebRequest -Uri "$BaseUri/redirect" -UserAgent "" -ErrorAction Stop
            $Recorded = @($Requests.ToArray() | Select-Object -Skip $Before)
            $Recorded.Count | Should -Be 1
            $Recorded[0] | Should -Be "HEAD /redirect"
        }
    }

    It "Reports an error for <Path> without retrying with GET" -TestCases @(
        @{ Path = "/not-found" }
        @{ Path = "/missing-location" }
    ) {
        param ($Path)

        InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Path = $Path; Requests = $Requests } {
            Mock Test-ProxyEnv { $false }
            $Before = $Requests.Count
            {
                Resolve-InvokeWebRequest -Uri "$BaseUri$Path" -UserAgent "" -WarningAction SilentlyContinue -ErrorAction Stop
            } | Should -Throw
            $Recorded = @($Requests.ToArray() | Select-Object -Skip $Before)
            $Recorded.Count | Should -Be 1
            $Recorded[0] | Should -Be "HEAD $Path"
        }
    }

    It "Uses headers-only GET for <Path> with redirect limit <Limit>" -TestCases @(
        @{ Path = "/get-redirect"; Limit = 0; Expected = "/nested/redirect"; Count = 2 }
        @{ Path = "/get-redirect"; Limit = 1; Expected = "/file"; Count = 3 }
        @{ Path = "/get-redirect"; Limit = 3; Expected = "/file"; Count = 4 }
        @{ Path = "/get-file"; Limit = 0; Expected = "/get-file"; Count = 2 }
    ) {
        param ($Path, $Limit, $Expected, $Count)

        InModuleScope -ModuleName "Evergreen" -Parameters @{
            BaseUri = $BaseUri; Requests = $Requests; ReleaseBody = $ReleaseBody
            Path = $Path; Limit = $Limit; Expected = $Expected; Count = $Count
        } {
            Mock Test-ProxyEnv { $false }
            $Before = $Requests.Count
            $null = $ReleaseBody.Reset()
            $Timer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $Result = @(Resolve-InvokeWebRequest -Uri "$BaseUri$Path" -UserAgent "ResolverTest" -Headers @{ "X-Test" = "value" } -MaximumRedirection $Limit -ErrorAction Stop)
                $Timer.ElapsedMilliseconds | Should -BeLessThan 5000
                $Result.Count | Should -Be 1
                $Result[0] | Should -Be "$BaseUri$Expected"
                $Recorded = @($Requests.ToArray() | Select-Object -Skip $Before)
                $Recorded.Count | Should -Be $Count
                $Recorded[0] | Should -Be "HEAD $Path"
                $Recorded[1] | Should -Be "GET $Path"
            }
            finally {
                $null = $ReleaseBody.Set()
            }
        }
    }

    It "Reports a failed GET fallback for <Path> without retrying again" -TestCases @(
        @{ Path = "/no-head" }
        @{ Path = "/get-error" }
    ) {
        param ($Path)

        InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Path = $Path; Requests = $Requests } {
            Mock Test-ProxyEnv { $false }
            $Before = $Requests.Count
            { Resolve-InvokeWebRequest -Uri "$BaseUri$Path" -UserAgent "" -WarningAction SilentlyContinue -ErrorAction Stop } | Should -Throw
            $Recorded = @($Requests.ToArray() | Select-Object -Skip $Before)
            ($Recorded -join ",") | Should -Be "HEAD $Path,GET $Path"
        }
    }

    It "Passes HEAD, user agent, headers and proxy credentials to Invoke-WebRequest" {
        InModuleScope -ModuleName "Evergreen" {
            Mock Test-ProxyEnv { $true }
            Mock Test-PSCore { $true }
            $OriginalProxy = $script:EvergreenProxy
            $OriginalCreds = $script:EvergreenProxyCreds
            $script:EvergreenProxy = [System.Uri]"http://proxy.example:8080"
            $script:EvergreenProxyCreds = [PSCredential]::new("test", (ConvertTo-SecureString "test" -AsPlainText -Force))
            try {
                Mock Invoke-WebRequest {
                    $Message = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::OK)
                    $Message.RequestMessage = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Head, "https://example.com/file")
                    [PSCustomObject]@{ BaseResponse = $Message }
                }
                Resolve-InvokeWebRequest -Uri "https://example.com/file" -UserAgent "ResolverTest" -Headers @{ "X-Test" = "value" } |
                    Should -Be "https://example.com/file"
                Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                    $Method -eq "Head" -and $UserAgent -eq "ResolverTest" -and
                    $Headers["X-Test"] -eq "value" -and $Proxy -eq $script:EvergreenProxy -and
                    $ProxyCredential -eq $script:EvergreenProxyCreds
                }
            }
            finally {
                $script:EvergreenProxy = $OriginalProxy
                $script:EvergreenProxyCreds = $OriginalCreds
            }
        }
    }

    It "Handles a <Status> response using the PowerShell Core=<Core> response format" -TestCases @(
        @{ Core = $true; Status = 200 }
        @{ Core = $true; Status = 302 }
        @{ Core = $false; Status = 200 }
        @{ Core = $false; Status = 302 }
    ) {
        param ($Core, $Status)

        InModuleScope -ModuleName "Evergreen" -Parameters @{ Core = $Core; Status = $Status } {
            Mock Test-ProxyEnv { $false }
            Mock Test-PSCore { $Core }
            $BaseResponse = [PSCustomObject]@{
                StatusCode     = $Status
                ResponseUri    = [System.Uri]"https://example.com/nested/source"
                RequestMessage = [PSCustomObject]@{ RequestUri = [System.Uri]"https://example.com/nested/source" }
                Headers        = @{ Location = "../target" }
                Disposed       = $false
            }
            $BaseResponse | Add-Member -MemberType ScriptMethod -Name Dispose -Value { $this.Disposed = $true }
            Mock Invoke-WebRequest { [PSCustomObject]@{ BaseResponse = $BaseResponse } }

            $Expected = if ($Status -eq 302) { "https://example.com/target" } else { "https://example.com/nested/source" }
            Resolve-InvokeWebRequest -Uri "https://example.com/nested/source" -UserAgent "" -ErrorAction Stop |
                Should -Be $Expected
            $BaseResponse.Disposed | Should -BeTrue
        }
    }

    It "Reports connection failures as non-terminating errors by default" {
        InModuleScope -ModuleName "Evergreen" {
            Mock Test-ProxyEnv { $false }
            Mock Invoke-WebRequest { throw [System.Net.WebException]::new("Connection timed out") }
            $RequestErrors = @()
            $Result = @(Resolve-InvokeWebRequest -Uri "https://example.com" -UserAgent "" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -ErrorVariable RequestErrors)
            $Result.Count | Should -Be 0
            $RequestErrors.Count | Should -BeGreaterThan 0
            $RequestErrors[-1].Exception.Message | Should -Match "Connection timed out"
            $Records = @(Resolve-InvokeWebRequest -Uri "https://example.com" -UserAgent "" -Verbose -WarningAction SilentlyContinue -ErrorAction SilentlyContinue 4>&1)
            $Messages = ($Records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
            $Messages | Should -Match "Resolution failed before an HTTP response was received"
            $Messages | Should -Match "Resolution finished in \[\d+\] ms"
        }
    }
}
