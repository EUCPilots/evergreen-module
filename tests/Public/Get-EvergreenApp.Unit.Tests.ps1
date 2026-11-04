<#
    .SYNOPSIS
        Offline tests for application loading and execution.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This is OK for the test files.")]
param ()

Describe -Tag "Get" -Name "Get-EvergreenApp deterministic execution" {
    BeforeAll {
        $script:AppsRoot = Join-Path $TestDrive "AppsCache"
        $null = New-Item -Path (Join-Path $script:AppsRoot "Apps") -ItemType Directory -Force
        @'
function Get-FixtureApp {
    param ($res, $Channel = "Stable")
    [PSCustomObject]@{
        Version = $res.Version
        Channel = $Channel
        URI = "https://example.test/setup.exe"
    }
}
'@ | Set-Content -LiteralPath (Join-Path $script:AppsRoot "Apps/Get-FixtureApp.ps1")
        'throw "Fixture dot-source failure"' |
            Set-Content -LiteralPath (Join-Path $script:AppsRoot "Apps/Get-BrokenApp.ps1")
        @'
function Get-FailingApp {
    param ($res)
    throw "Fixture application failure"
}
'@ | Set-Content -LiteralPath (Join-Path $script:AppsRoot "Apps/Get-FailingApp.ps1")
        Mock Get-EvergreenAppsPath -ModuleName Evergreen { Join-Path $TestDrive "AppsCache" }
        Mock Get-FunctionResource -ModuleName Evergreen { @{ Version = "1.2.3" } }
        Mock Write-AppNotFoundHelp -ModuleName Evergreen {}
        Mock Write-ErrorDetail -ModuleName Evergreen {}
        Mock Set-ProxyEnv -ModuleName Evergreen {}
        Mock Remove-ProxyEnv -ModuleName Evergreen {}
    }

    It "Loads a local function and passes its manifest and additional parameters through the output filter" {
        $Result = Get-EvergreenApp -Name FixtureApp -AppParams @{ Channel = "Beta" }

        $Result.Version | Should -Be "1.2.3"
        $Result.Channel | Should -Be "Beta"
        $Result.URI | Should -Be "https://example.test/setup.exe"
        Should -Invoke Get-FunctionResource -ModuleName Evergreen -Times 1 -Exactly -ParameterFilter { $AppName -eq "FixtureApp" }
    }

    It "Applies the application's local output filter" {
        $null = New-Item -Path (Join-Path $script:AppsRoot "Filters") -ItemType Directory -Force
        '{"filters":[{"property":"Channel","operator":"eq","value":"Stable"}]}' |
            Set-Content -LiteralPath (Join-Path $script:AppsRoot "Filters/FixtureApp.json")
        try {
            Get-EvergreenApp -Name FixtureApp -AppParams @{ Channel = "Beta" } | Should -BeNullOrEmpty
            (Get-EvergreenApp -Name FixtureApp).Channel | Should -Be "Stable"
        }
        finally {
            Remove-Item -LiteralPath (Join-Path $script:AppsRoot "Filters/FixtureApp.json")
        }
    }

    It "Sets proxy state once for pipeline input and clears it and certificate state on completion" {
        $Credential = [PSCredential]::new("proxy-user", [System.Security.SecureString]::new())
        $Result = @("FixtureApp", "FixtureApp") | Get-EvergreenApp -Proxy "http://proxy.test:8080" -ProxyCredential $Credential -SkipCertificateCheck

        @($Result).Count | Should -Be 2
        Should -Invoke Set-ProxyEnv -ModuleName Evergreen -Times 1 -Exactly -ParameterFilter {
            $Proxy -eq "http://proxy.test:8080" -and $ProxyCredential.UserName -eq "proxy-user"
        }
        Should -Invoke Remove-ProxyEnv -ModuleName Evergreen -Times 1 -Exactly
        InModuleScope Evergreen { $script:SkipCertificateCheck | Should -BeFalse }
    }

    It "Preserves <Message> and clears state on failure for <Name>" -TestCases @(
        @{ Name = "MissingApp"; Message = "*Failed to retrieve manifest*" }
        @{ Name = "BrokenApp"; Message = "*Fixture dot-source failure*" }
        @{ Name = "FailingApp"; Message = "*Fixture application failure*" }
    ) {
        param ($Name, $Message)

        { Get-EvergreenApp -Name $Name -Proxy "http://proxy.test:8080" -SkipCertificateCheck -WarningAction SilentlyContinue } |
            Should -Throw $Message
        Should -Invoke Set-ProxyEnv -ModuleName Evergreen -Times 1 -Exactly -ParameterFilter {
            $Proxy -eq "http://proxy.test:8080" -and -not $PesterBoundParameters.ContainsKey("ProxyCredential")
        }
        Should -Invoke Remove-ProxyEnv -ModuleName Evergreen -Times 1 -Exactly
        InModuleScope Evergreen { $script:SkipCertificateCheck | Should -BeFalse }
        if ($Name -eq "MissingApp") {
            Should -Invoke Write-AppNotFoundHelp -ModuleName Evergreen -Times 1 -Exactly
        }
        else {
            Should -Invoke Write-ErrorDetail -ModuleName Evergreen -Times 1 -Exactly
        }
    }

    It "Rejects proxy credentials without a proxy before loading an app" {
        { Get-EvergreenApp -Name FixtureApp -ProxyCredential ([PSCredential]::Empty) } | Should -Throw "*ProxyCredential requires Proxy*"
        Should -Invoke Get-FunctionResource -ModuleName Evergreen -Times 0 -Exactly
    }

    It "Rejects the reserved manifest parameter" {
        { Get-EvergreenApp -Name FixtureApp -AppParams @{ res = @{} } } | Should -Throw "*reserved key 'res'*"
        Should -Invoke Get-FunctionResource -ModuleName Evergreen -Times 0 -Exactly
    }

    It "Rejects unsafe application name <Name>" -TestCases @(
        @{ Name = "../FixtureApp" }
        @{ Name = "Apps\FixtureApp" }
        @{ Name = "Fixture*" }
        @{ Name = ".." }
        @{ Name = "Fixture:App" }
    ) {
        param ($Name)
        $Parameters = @{ Name = $Name }
        { Get-EvergreenApp @Parameters } | Should -Throw
        Should -Invoke Get-FunctionResource -ModuleName Evergreen -Times 0 -Exactly
    }
}
