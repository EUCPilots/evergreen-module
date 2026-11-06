@{
    CustomRulePath      = @(
        ".rules/LowercaseKeyword.psm1"
    )
    IncludeDefaultRules = $true
    Severity            = @("Error", "Warning")
    ExcludeRules        = @("PSAvoidUsingWriteHost")
    Rules        = @{
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }
        PSUseCompatibleSyntax  = @{
            Enable = $true
            TargetVersions = @(
                '7.4'
                '5.1'
            )
        }
    }
}
