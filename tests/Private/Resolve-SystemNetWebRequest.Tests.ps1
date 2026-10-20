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
    $ReleaseBody = [System.Threading.ManualResetEvent]::new($false)
    $Server = [PowerShell]::Create()
    $null = $Server.AddScript({
        param ($Listener, $Requests, $ReleaseBody)

        while ($Listener.IsListening) {
            $Context = $Listener.GetContext()
            $Requests.Enqueue("$($Context.Request.HttpMethod) $($Context.Request.Url.AbsolutePath)")
            $Response = $Context.Response
            $Response.Headers.Add("X-Request-Method", $Context.Request.HttpMethod)
            $Path = $Context.Request.Url.AbsolutePath
            if ($Context.Request.HttpMethod -eq "HEAD" -and $Path -in @("/no-head", "/get-redirect", "/no-head-fails")) {
                $Response.StatusCode = 405
            }
            elseif ($Path -eq "/no-head-fails") {
                $Response.StatusCode = 403
            }
            elseif ($Path -eq "/not-found") {
                $Response.StatusCode = 404
            }
            elseif ($Path -eq "/get-redirect") {
                $Response.StatusCode = 302
                $Response.RedirectLocation = "/no-head"
            }
            elseif ($Context.Request.Url.AbsolutePath -eq "/redirect") {
                $Response.StatusCode = 302
                $Response.RedirectLocation = "/redirect-again"
            }
            elseif ($Context.Request.Url.AbsolutePath -eq "/redirect-again") {
                $Response.StatusCode = 307
                $Response.RedirectLocation = "/file"
            }
            else {
                $Response.StatusCode = 200
                $Response.ContentLength64 = 1073741824
                $Response.Headers.Add("Last-Modified", "Wed, 21 Oct 2015 07:28:00 GMT")
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

Describe -Name "Resolve-SystemNetWebRequest" {
    Context "Ensure Resolve-SystemNetWebRequest works as expected" {
        It "Explains HEAD resolution, advertised size and elapsed time without changing output" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri } {
                Mock Test-ProxyEnv { $false }
                $Records = @(Resolve-SystemNetWebRequest -Uri "$BaseUri/redirect" -UserAgent "" -Verbose 4>&1)
                $Output = @($Records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] })
                $Output.Count | Should -Be 1
                $Output[0].ResponseUri.AbsoluteUri | Should -Be "$BaseUri/file"
                $Messages = ($Records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
                $Messages | Should -Match "Request: HEAD"
                $Messages | Should -Match "Maximum automatic redirects: \[3\]"
                $Messages | Should -Match "Waiting for response headers; request timeout: \[\d+\] ms"
                $Messages | Should -Match "Response: HTTP \[200\]"
                $Messages | Should -Match "Advertised Content-Length: \[1073741824\].*not bytes downloaded"
                $Messages | Should -Match "Resolution finished in \[\d+\] ms"
            }
        }

        It "Resolves <Path> using HEAD and preserves response metadata" -TestCases @(
            @{ Path = "/file" }
            @{ Path = "/redirect" }
        ) {
            param ($Path)

            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; Path = $Path } {
                Mock Test-ProxyEnv { $false }
                $Results = @(Resolve-SystemNetWebRequest -Uri "$BaseUri$Path" -UserAgent "")

                $Results.Count | Should -Be 1
                $Response = $Results[0]
                $Response.ResponseUri | Should -BeOfType [System.Uri]
                $Response.ResponseUri.AbsoluteUri | Should -Be "$BaseUri/file"
                $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::OK)
                $Response.Headers["X-Request-Method"] | Should -Be "HEAD"
                $Response.ContentLength | Should -Be 1073741824
                $Response.LastModified.ToUniversalTime() | Should -Be ([DateTime]::new(2015, 10, 21, 7, 28, 0, [DateTimeKind]::Utc))
            }
        }

        It "Throws when the redirect limit is exceeded" {
            InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri } {
                Mock Test-ProxyEnv { $false }
                {
                    Resolve-SystemNetWebRequest -Uri "$BaseUri/redirect" -UserAgent "" -MaximumRedirection 1 -WarningAction SilentlyContinue
                } | Should -Throw
            }
        }

        It "Falls back to GET for <Path> and returns before the body finishes" -TestCases @(
            @{ Path = "/no-head"; ExpectedRequests = @("HEAD /no-head", "GET /no-head") }
            @{ Path = "/get-redirect"; ExpectedRequests = @("HEAD /get-redirect", "GET /get-redirect", "GET /no-head") }
        ) {
            param ($Path, $ExpectedRequests)

            InModuleScope -ModuleName "Evergreen" -Parameters @{
                BaseUri = $BaseUri; Requests = $Requests; ReleaseBody = $ReleaseBody; Path = $Path; ExpectedRequests = $ExpectedRequests
            } {
                Mock Test-ProxyEnv { $false }
                $null = $ReleaseBody.Reset()
                $Before = $Requests.Count
                $Timer = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    $Records = @(Resolve-SystemNetWebRequest -Uri "$BaseUri$Path" -UserAgent "" -Verbose 4>&1)
                    $Timer.Stop()
                    $Timer.ElapsedMilliseconds | Should -BeLessThan 5000
                    $Output = @($Records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] })
                    $Output.Count | Should -Be 1
                    $Output[0].ResponseUri.AbsoluteUri | Should -Be "$BaseUri/no-head"
                    $Output[0].ContentLength | Should -Be 1073741824
                    $Output[0].Headers["X-Request-Method"] | Should -Be "GET"
                    $Messages = ($Records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
                    $Messages | Should -Match "HEAD rejected with HTTP \[405\]"
                    $Messages | Should -Match "GET aborted after headers"
                    $RecordedRequests = @($Requests.ToArray() | Select-Object -Skip $Before)
                    ($RecordedRequests -join ",") | Should -Be ($ExpectedRequests -join ",")
                }
                finally {
                    $null = $ReleaseBody.Set()
                }
            }
        }

        It "Propagates failures for <Path> without additional retries" -TestCases @(
            @{ Path = "/no-head-fails"; ExpectedRequests = @("HEAD /no-head-fails", "GET /no-head-fails") }
            @{ Path = "/not-found"; ExpectedRequests = @("HEAD /not-found") }
        ) {
            param ($Path, $ExpectedRequests)

            InModuleScope -ModuleName "Evergreen" -Parameters @{
                BaseUri = $BaseUri; Requests = $Requests; Path = $Path; ExpectedRequests = $ExpectedRequests
            } {
                Mock Test-ProxyEnv { $false }
                $Before = $Requests.Count
                { Resolve-SystemNetWebRequest -Uri "$BaseUri$Path" -UserAgent "" -WarningAction SilentlyContinue } | Should -Throw
                $RecordedRequests = @($Requests.ToArray() | Select-Object -Skip $Before)
                ($RecordedRequests -join ",") | Should -Be ($ExpectedRequests -join ",")
            }
        }
    }
}
