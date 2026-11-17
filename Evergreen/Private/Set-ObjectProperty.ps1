<#
    .SYNOPSIS
        Replaces an object's property value when it matches the expected value.
    .DESCRIPTION
        Updates the object in place and outputs it whether or not a change is made.
        Use -WhatIf to preview matching updates or -Confirm to approve each update.
#>
function Set-ObjectProperty {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject]$InputObject,

        [Parameter(Mandatory)]
        [string]$PropertyName,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [object]$CurrentValue,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [object]$Value
    )

    process {
        $property = $InputObject.PSObject.Properties[$PropertyName]
        if ($null -eq $property) {
            throw "Property '$PropertyName' does not exist on the input object."
        }

        if ([System.Management.Automation.LanguagePrimitives]::Equals($property.Value, $CurrentValue, $true) -and
            $PSCmdlet.ShouldProcess($property.Name, "Set object property")) {
            $property.Value = $Value
        }

        $InputObject
    }
}
