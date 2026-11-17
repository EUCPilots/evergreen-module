Describe -Name "Set-ObjectProperty" {
    It "Outputs the original object without updating a matching property under WhatIf" {
        InModuleScope -ModuleName "Evergreen" {
            $Object = [PSCustomObject]@{ Status = "Pending" }

            $Result = $Object | Set-ObjectProperty -PropertyName "Status" -CurrentValue "Pending" -Value "Complete" -WhatIf

            [object]::ReferenceEquals($Result, $Object) | Should -BeTrue
            $Object.Status | Should -BeExactly "Pending"
        }
    }

    It "Updates only matching properties when confirmation is suppressed" {
        InModuleScope -ModuleName "Evergreen" {
            $Objects = @(
                [PSCustomObject]@{ Status = "Pending" }
                [PSCustomObject]@{ Status = "Skipped" }
            )

            $Result = @($Objects | Set-ObjectProperty -PropertyName "Status" -CurrentValue "Pending" -Value "Complete" -Confirm:$false)

            $Result.Count | Should -Be 2
            $Objects[0].Status | Should -BeExactly "Complete"
            $Objects[1].Status | Should -BeExactly "Skipped"
        }
    }
}
