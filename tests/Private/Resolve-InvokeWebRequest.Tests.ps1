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
    $OtherPortListener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $OtherPortListener.Start()
    $OtherPort = $OtherPortListener.LocalEndpoint.Port
    $OtherPortListener.Stop()
    $OtherBaseUri = "http://127.0.0.1:$OtherPort"
    $Listener = [System.Net.HttpListener]::new()
    $Listener.Prefixes.Add("$BaseUri/")
    $Listener.Start()
    $OtherListener = [System.Net.HttpListener]::new()
    $OtherListener.Prefixes.Add("$OtherBaseUri/")
    $OtherListener.Start()
    $Requests = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $RequestMetadata = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $OtherRequests = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $ReleaseBody = [System.Threading.ManualResetEvent]::new($false)
    $Server = [PowerShell]::Create()
    $null = $Server.AddScript({
        param ($Listener, $Requests, $RequestMetadata, $ReleaseBody, $OtherBaseUri)

        while ($Listener.IsListening) {
            $Context = $Listener.GetContext()
            $Path = $Context.Request.Url.AbsolutePath
            $Requests.Enqueue("$($Context.Request.HttpMethod) $Path")
            $RequestMetadata.Enqueue("$($Context.Request.UserAgent)|$($Context.Request.Headers['X-Test'])|$($Context.Request.Headers['Authorization'])")
            $Response = $Context.Response
            if ($Path -eq "/cross-origin") {
                $Response.StatusCode = 302
                $Response.RedirectLocation = "$OtherBaseUri/auth-target"
            }
            elseif ($Path -eq "/no-head" -or ($Context.Request.HttpMethod -eq "HEAD" -and $Path -like "/get-*")) {
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
    }).AddArgument($Listener).AddArgument($Requests).AddArgument($RequestMetadata).AddArgument($ReleaseBody).AddArgument($OtherBaseUri)
    $null = $Server.BeginInvoke()
    $OtherServer = [PowerShell]::Create()
    $null = $OtherServer.AddScript({
        param ($Listener, $Requests)

        while ($Listener.IsListening) {
            $Context = $Listener.GetContext()
            $Requests.Enqueue("$($Context.Request.HttpMethod) $($Context.Request.Url.AbsolutePath)|$($Context.Request.Headers['Authorization'])")
            $Context.Response.StatusCode = 200
            $Context.Response.Close()
        }
    }).AddArgument($OtherListener).AddArgument($OtherRequests)
    $null = $OtherServer.BeginInvoke()
}

AfterAll {
    $null = $ReleaseBody.Set()
    $Listener.Stop()
    $Listener.Close()
    $OtherListener.Stop()
    $OtherListener.Close()
    $Server.Stop()
    $Server.Dispose()
    $OtherServer.Stop()
    $OtherServer.Dispose()
    $ReleaseBody.Dispose()
}

Describe -Name "Resolve-InvokeWebRequest" {
    It "Explains HEAD resolution and redirect behavior without logging header values" {
        InModuleScope -ModuleName "Evergreen" -Parameters @{ BaseUri = $BaseUri; RequestMetadata = $RequestMetadata } {
            Mock Test-ProxyEnv { $false }
            $Before = $RequestMetadata.Count
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
            @($RequestMetadata.ToArray() | Select-Object -Skip $Before) | Should -Be @("||secret-value")
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

    It "Passes the user agent and custom headers" {
        InModuleScope -ModuleName "Evergreen" -Parameters @{
            BaseUri = $BaseUri; Requests = $Requests; RequestMetadata = $RequestMetadata
        } {
            Mock Test-ProxyEnv { $false }
            $Before = $Requests.Count
            Resolve-InvokeWebRequest -Uri "$BaseUri/file" -UserAgent "ResolverTest" -Headers @{ "X-Test" = "value" } |
                Should -Be "$BaseUri/file"
            $Recorded = @($Requests.ToArray() | Select-Object -Skip $Before)
            $Recorded | Should -Be @("HEAD /file")
            $Metadata = @($RequestMetadata.ToArray())[-1]
            $Metadata | Should -Be "ResolverTest|value|"
        }
    }

    It "Forwards Authorization on same-origin redirects and strips it on cross-origin redirects" {
        InModuleScope -ModuleName "Evergreen" -Parameters @{
            BaseUri = $BaseUri; OtherBaseUri = $OtherBaseUri; Requests = $Requests
            RequestMetadata = $RequestMetadata; OtherRequests = $OtherRequests
        } {
            Mock Test-ProxyEnv { $false }
            $BeforeRequests = $Requests.Count
            $BeforeMetadata = $RequestMetadata.Count
            Resolve-InvokeWebRequest -Uri "$BaseUri/redirect" -UserAgent "" -Headers @{ Authorization = "Bearer test-token" } -MaximumRedirection 1 |
                Should -Be "$BaseUri/file"
            @($RequestMetadata.ToArray() | Select-Object -Skip $BeforeMetadata) |
                Should -Be @("||Bearer test-token", "||Bearer test-token")
            @($Requests.ToArray() | Select-Object -Skip $BeforeRequests) |
                Should -Be @("HEAD /redirect", "HEAD /nested/redirect")

            $BeforeOtherRequests = $OtherRequests.Count
            Resolve-InvokeWebRequest -Uri "$BaseUri/cross-origin" -UserAgent "" -Headers @{ Authorization = "Bearer test-token" } -MaximumRedirection 1 |
                Should -Be "$OtherBaseUri/auth-target"
            @($OtherRequests.ToArray() | Select-Object -Skip $BeforeOtherRequests) |
                Should -Be @("HEAD /auth-target|")
        }
    }

    It "Reports connection failures as non-terminating errors by default" {
        InModuleScope -ModuleName "Evergreen" {
            Mock Test-ProxyEnv { $false }
            $RequestErrors = @()
            $Result = @(Resolve-InvokeWebRequest -Uri "http://127.0.0.1:1" -UserAgent "" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -ErrorVariable RequestErrors)
            $Result.Count | Should -Be 0
            $RequestErrors.Count | Should -BeGreaterThan 0
            $RequestErrors[-1].Exception.Message | Should -Not -BeNullOrEmpty
            $Records = @(Resolve-InvokeWebRequest -Uri "http://127.0.0.1:1" -UserAgent "" -Verbose -WarningAction SilentlyContinue -ErrorAction SilentlyContinue 4>&1)
            $Messages = ($Records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Message -join "`n"
            $Messages | Should -Match "Resolution failed before an HTTP response was received"
            $Messages | Should -Match "Resolution finished in \[\d+\] ms"
        }
    }
}
