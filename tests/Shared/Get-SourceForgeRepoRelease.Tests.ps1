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
}

Describe -Name "Get-SourceForgeRepoRelease" {
    Context "Validate function returns expected object" {
        It "Returns an object with expected properties" {
            InModuleScope -ModuleName "Evergreen" {
                $Uri = "https://sourceforge.net/projects/sevenzip/best_release.json"
                $Download = @{
                    "Folder"         = "7-Zip"
                    "Feed"           = "https://sourceforge.net/projects/sevenzip/rss?path="
                    "XPath"          = "//item"
                    "FilterProperty" = "link"
                    "ContentType"    = "application/rss+xml; charset=utf-8"
                    "Uri"            = "https://nchc.dl.sourceforge.net/project/sevenzip"
                }
                $params = @{
                    Uri          = $Uri
                    Download     = $Download
                    MatchVersion = "(\d+(\.\d+){1,3})"
                }
                $object = Get-SourceForgeRepoRelease @params
                $object.Version.Length | Should -BeGreaterThan 0
                $object.Architecture.Length | Should -BeGreaterThan 0
                $object.Type.Length | Should -BeGreaterThan 0
                $object.Size.Length | Should -BeGreaterThan 0
                $object.Md5.Length | Should -BeGreaterThan 0
                $object.FileName.Length | Should -BeGreaterThan 0
                $object.URI.Length | Should -BeGreaterThan 0
            }
        }
    }
}
