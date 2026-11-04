@{
    Severity     = @('Error', 'Warning')
    Rules        = @{
        PSUseCompatibleCmdlets = @{
            Compatibility = @(
                'desktop-5.1.14393.206-windows'
                'core-6.1.0-windows'
                'core-6.1.0-linux'
                'core-6.1.0-linux-arm'
                'core-6.1.0-macos'
            )
        }
        PSUseCompatibleSyntax  = @{
            TargetedVersions = @(
                '7.4'
                '6.0'
                '5.1'
            )
        }
    }
    ExcludeRules = @('PSAvoidUsingWriteHost')
}