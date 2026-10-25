InModuleScope -ModuleName "Evergreen" {
    Describe "Repository helper <Function>" -ForEach @(
        @{
            "Function" = "Get-GitHubRepoRelease"
            Uri = "https://api.github.com/repos/ActiveState/OpenKomodoIDE/releases/latest"
            TagsUri = "https://api.github.com/repos/aws/aws-cli/tags"
            Schema = "GitHub"
            IsTagHelper = $false
        }
        @{
            "Function" = "Get-CodebergRepoRelease"
            Uri = "https://codeberg.org/api/v1/repos/eduVPN/windows/releases/latest"
            TagsUri = "https://codeberg.org/api/v1/repos/eduVPN/windows/tags"
            Schema = "Codeberg"
            IsTagHelper = $false
        }
        @{
            "Function" = "Get-GitLabRepoRelease"
            Uri = "https://gitlab.com/api/v4/projects/123/releases/permalink/latest"
            TagsUri = "https://gitlab.com/api/v4/projects/123/repository/tags"
            Schema = "GitLab"
            IsTagHelper = $false
        }
        @{
            "Function" = "Get-GitHubRepoTag"
            Uri = "https://api.github.com/repos/aws/aws-cli/tags"
            TagsUri = "https://api.github.com/repos/aws/aws-cli/tags"
            Schema = "GitHubTags"
            IsTagHelper = $true
        }
    ) {
        BeforeAll {
            $SavedResources = $script:resourceStrings
            $SavedGitHubToken = $env:GITHUB_TOKEN
            $SavedGhToken = $env:GH_TOKEN
            $SavedGitLabToken = $env:GITLAB_TOKEN
        }

        AfterAll {
            $script:resourceStrings = $SavedResources
            $env:GITHUB_TOKEN = $SavedGitHubToken
            $env:GH_TOKEN = $SavedGhToken
            $env:GITLAB_TOKEN = $SavedGitLabToken
        }

        BeforeEach {
            $script:resourceStrings = Get-Content -LiteralPath (Join-Path $PSScriptRoot "..\..\Evergreen\Evergreen.json") -Raw | ConvertFrom-Json
            $env:GITHUB_TOKEN = "test-github-secret"
            $env:GH_TOKEN = "test-gh-secret"
            $env:GITLAB_TOKEN = "test-gitlab-secret"
            $ResponseProperties = @{}
            foreach ($Property in $script:resourceStrings.Properties.$Schema) {
                $ResponseProperties[$Property] = $null
            }
            $ResponseProperties.name = "v1.2.3"
            $ResponseProperties.tag_name = "v1.2.3"
            $ResponseProperties.created_at = "2026-07-01T10:00:00Z"
            $ResponseProperties.released_at = "2026-07-02T09:00:00Z"
            $Asset = [PSCustomObject]@{
                browser_download_url = "https://example.com/eduVPNClient_x64.msi"
                direct_asset_url = "https://example.com/eduVPNClient_x64.msi"
                url = "https://example.com/fallback.msi"
                size = 12345
            }
            $ResponseProperties.assets = if ($Schema -eq "GitLab") {
                [PSCustomObject]@{ links = @($Asset); sources = @() }
            }
            else {
                @($Asset)
            }
            $Response = [PSCustomObject]$ResponseProperties
            Mock Get-GitHubRateLimit { [PSCustomObject]@{ remaining = 100 } }
            Mock Get-EvergreenUserAgent { "Evergreen-Pester-Agent" }
            Mock Test-ProxyEnv { $false }
            Mock Invoke-RestMethod { $Response }
            Mock Get-Platform { "Windows" }
            Mock Get-Architecture { "x64" }
            Mock Get-InstallerType { "Default" }
        }

        It "Preserves output properties and values" {
            $Result = & $Function -Uri $Uri
            if ($IsTagHelper) {
                $Result.PSObject.Properties.Name | Should -Be @("Tag")
                $Result.Tag | Should -Be "1.2.3"
            }
            else {
                $Expected = @("Version", "Date", "Architecture", "InstallerType", "Type", "URI")
                if ($Schema -ne "GitLab") { $Expected += "Size" }
                @($Result.PSObject.Properties.Name | Sort-Object) | Should -Be @($Expected | Sort-Object)
                $Result.Version | Should -Be "1.2.3"
                $Result.Date | Should -BeOfType ([datetime])
                $Result.Architecture | Should -Be "x64"
                $Result.InstallerType | Should -Be "Default"
                $Result.Type | Should -Be "msi"
                $Result.URI | Should -Be $Asset.browser_download_url
                if ($Schema -ne "GitLab") { $Result.Size | Should -Be 12345 }
            }
        }

        It "Falls back to the original version when the regex does not match" {
            $Response.name = "nightly"
            $Response.tag_name = "nightly"
            $Result = & $Function -Uri $Uri
            if ($IsTagHelper) { $Result.Tag | Should -Be "nightly" }
            else { $Result.Version | Should -Be "nightly" }
        }

        It "Falls back to the original version when there is no capture group" {
            $Result = & $Function -Uri $Uri -MatchVersion "\d+\.\d+\.\d+"
            if ($IsTagHelper) { $Result.Tag | Should -Be "v1.2.3" }
            else { $Result.Version | Should -Be "v1.2.3" }
        }

        It "Surfaces invalid regex patterns" {
            { & $Function -Uri $Uri -MatchVersion "[" } | Should -Throw
        }

        It "Rejects empty and null API responses" {
            Mock Invoke-RestMethod { @() }
            { & $Function -Uri $Uri } | Should -Throw "*returned no releases or tags*"
            Mock Invoke-RestMethod { $null }
            { & $Function -Uri $Uri } | Should -Throw "*returned no releases or tags*"
        }

        It "Rejects null items within an API response" {
            Mock Invoke-RestMethod { ,@($Response, $null) }
            { & $Function -Uri $Uri } | Should -Throw "*null release or tag*"
        }

        It "Rejects blank version values" {
            $Response.name = " "
            $Response.tag_name = " "
            { & $Function -Uri $Uri } | Should -Throw "*version is empty*"
        }

        It "Rejects missing required properties but accepts additional properties" {
            $Response | Add-Member -NotePropertyName future_api_field -NotePropertyValue "extra"
            { & $Function -Uri $Uri } | Should -Not -Throw
            $Missing = $script:resourceStrings.Properties.$Schema[0]
            $Response.PSObject.Properties.Remove($Missing)
            { & $Function -Uri $Uri } | Should -Throw "*Required properties missing*$Missing*"
        }

        It "Does not include token values in verbose output" {
            $Messages = & $Function -Uri $Uri -Verbose 4>&1 | Out-String
            $Messages | Should -Not -Match "test-github-secret|test-gh-secret|test-gitlab-secret"
            if ($Schema -eq "GitLab") {
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Headers["PRIVATE-TOKEN"] -eq "test-gitlab-secret" }
            }
            elseif ($Function -like "Get-GitHub*") {
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Headers.Authorization -eq "token test-github-secret" }
            }
        }

        It "Rejects other hosts and unsupported endpoint suffixes" {
            { & $Function -Uri ($Uri -replace "https://[^/]+", "https://example.com") } | Should -Throw
            { & $Function -Uri "$Uri/unsupported/path" } | Should -Throw
            { & $Function -Uri "$Uri#fragment" } | Should -Throw
        }

        It "Accepts explicit single-page query parameters" {
            { & $Function -Uri "${Uri}?per_page=10&page=2" } | Should -Not -Throw
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
        }

        It "Preserves API item order and count" {
            $Second = $Response.PSObject.Copy()
            $Second.name = "v2.0.0"
            $Second.tag_name = "v2.0.0"
            Mock Invoke-RestMethod { @($Response, $Second) }
            $Result = @(& $Function -Uri $Uri)
            $Result.Count | Should -Be 2
            if ($IsTagHelper) { $Result.Tag | Should -Be @("1.2.3", "2.0.0") }
            else { $Result.Version | Should -Be @("1.2.3", "2.0.0") }
        }

        It "Propagates HTTP errors" {
            Mock Invoke-RestMethod { throw "HTTP request failed" }
            { & $Function -Uri $Uri } | Should -Throw "*HTTP request failed*"
        }

        It "Preserves GitHub rate-limit sentinel objects" -Skip:($Function -notlike "Get-GitHub*") {
            Mock Get-GitHubRateLimit { [PSCustomObject]@{ remaining = 0 } }
            $Result = & $Function -Uri $Uri
            $Result.Version | Should -Be "RateLimited"
            $Result.URI | Should -Be "https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting"
            Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        }

        It "Uses GH_TOKEN when GITHUB_TOKEN is absent" -Skip:($Function -notlike "Get-GitHub*") {
            $env:GITHUB_TOKEN = $null
            $null = & $Function -Uri $Uri
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Headers.Authorization -eq "token test-gh-secret" }
        }

        It "Uses GH_TOKEN when GITHUB_TOKEN is whitespace" -Skip:($Function -notlike "Get-GitHub*") {
            $env:GITHUB_TOKEN = " "
            $null = & $Function -Uri $Uri
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Headers.Authorization -eq "token test-gh-secret" }
        }

        It "Omits authentication headers when no nonempty token is available" {
            $env:GITHUB_TOKEN = " "
            $env:GH_TOKEN = " "
            $env:GITLAB_TOKEN = " "
            $null = & $Function -Uri $Uri
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $null -eq $Headers }
        }

        It "Returns only the first version when requested" -Skip:$IsTagHelper {
            $Second = $Response.PSObject.Copy()
            $Second.tag_name = "v9.8.7"
            Mock Invoke-RestMethod { @($Response, $Second) }
            $Result = & $Function -Uri $Uri -ReturnVersionOnly -VersionReplace @("\.", "_")
            $Result.PSObject.Properties.Name | Should -Be @("Version")
            $Result.Version | Should -Be "1_2_3"
        }

        It "Uses the tags schema and name field for tag endpoints with query strings" -Skip:$IsTagHelper {
            $TagProperties = @{}
            foreach ($Property in $script:resourceStrings.Properties.GitHubTags) {
                $TagProperties[$Property] = $null
            }
            $TagProperties.name = "v4.5.6"
            Mock Invoke-RestMethod { [PSCustomObject]$TagProperties }
            $Result = & $Function -Uri "${TagsUri}/?per_page=10" -ReturnVersionOnly
            $Result.Version | Should -Be "4.5.6"
        }

        It "Honors an explicitly false version-only switch" -Skip:$IsTagHelper {
            $Result = & $Function -Uri $Uri -ReturnVersionOnly:$false
            $Result.URI | Should -Be $Asset.browser_download_url
        }

        It "Applies replacements in asset mode and permits an empty replacement string" -Skip:$IsTagHelper {
            $Result = & $Function -Uri $Uri -VersionReplace @("\.", "")
            $Result.Version | Should -Be "123"
        }

        It "Rejects malformed replacements" -Skip:$IsTagHelper {
            { & $Function -Uri $Uri -VersionReplace @("only-pattern") } | Should -Throw
            { & $Function -Uri $Uri -VersionReplace @("a", "b", "c") } | Should -Throw
            { & $Function -Uri $Uri -VersionReplace $null } | Should -Throw
            { & $Function -Uri $Uri -VersionReplace @(".*", "") } | Should -Throw "*empty version*"
        }

        It "Respects custom version fields" -Skip:$IsTagHelper {
            $Response | Add-Member -NotePropertyName custom_version -NotePropertyValue "release-9.8.7"
            $Result = & $Function -Uri $Uri -VersionTag custom_version
            $Result.Version | Should -Be "9.8.7"
        }

        It "Preserves URL-based manifest filters and Windows-only selection" -Skip:$IsTagHelper {
            @(& $Function -Uri $Uri -Filter "eduVPNClient_.*(exe|msi)$").Count | Should -Be 1
            @(& $Function -Uri $Uri -Filter "\.exe$").Count | Should -Be 0
            Mock Get-Platform { "Linux" }
            @(& $Function -Uri $Uri).Count | Should -Be 0
        }

        It "Preserves optional GitHub SHA256 output" -Skip:($Function -ne "Get-GitHubRepoRelease") {
            $Asset | Add-Member -NotePropertyName digest -NotePropertyValue "sha256:abcdef"
            $Result = & $Function -Uri $Uri
            $Result.Sha256 | Should -Be "abcdef"
        }

        It "Does not confuse a release whose tag is named tags with the tags endpoint" -Skip:($Schema -notin @("Codeberg", "GitHub")) {
            $ReleaseUri = $Uri -replace "/releases/latest$", "/releases/tags/tags"
            $Response.name = "A different release title"
            $Result = & $Function -Uri $ReleaseUri -ReturnVersionOnly
            $Result.Version | Should -Be "1.2.3"
        }

        It "Rejects release endpoints in the tag-only helper" -Skip:(-not $IsTagHelper) {
            { & $Function -Uri ($Uri -replace "/tags$", "/releases/latest") } | Should -Throw
        }
    }
}
