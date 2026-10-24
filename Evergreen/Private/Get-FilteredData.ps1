function Get-FilteredData {
    <#
        .SYNOPSIS
        Filters an array of objects using a JSON-based filter configuration file.

        .DESCRIPTION
        Get-FilteredData reads a JSON filter configuration from the file specified by -FilterPath and applies the configured filters to the array provided via -InputObject.
        The JSON file must include a non-empty "filters" array of filter objects and may include a top-level "logicalOperator" (defaults to "and").
        Each filter object must specify:
            - property : the name of the property on each input object to evaluate
            - operator : one of the supported comparison operators (see below)
            - value    : the value to compare against (type depends on the operator and input objects)

        Supported operators:
            - eq    : equals (-eq)
            - ne    : not equals (-ne)
            - like  : wildcard string comparison (-like)
            - match : regular expression match (-match)
            - in    : value is contained in the filter.value array (filter.value should be an array)
            - gt    : greater than (-gt)
            - lt    : less than (-lt)
            - ge    : greater than or equal (-ge)
            - le    : less than or equal (-le)
        If an unknown operator is provided, equality (eq) is used as the default.

        The top-level logicalOperator may be "and" or "or". When "and" (default) all filter conditions must be true for an item to be included. When "or", an item is included if any filter condition is true.

        .PARAMETER FilterPath
        Path to the JSON file that contains the filter configuration. The file is read with Get-Content -Raw and parsed with ConvertFrom-Json.

        .PARAMETER InputObject
        An array of objects to filter. Each object's properties referenced by the filters must be accessible by property name.

        .INPUTS
        System.Object[] (an array of PSObjects or any objects with properties)

        .OUTPUTS
        System.Object[] — the subset of InputObject that match the provided filter configuration.

        .EXAMPLE
        # filters.json (example)
        # {
        #   "logicalOperator": "or",
        #   "filters": [
        #     { "property": "Status", "operator": "eq", "value": "Active" },
        #     { "property": "Name",   "operator": "like", "value": "*Test*" }
        #   ]
        # }
        Get-FilteredData -FilterPath 'C:\path\to\filters.json' -InputObject $items

        This returns items whose Status equals "Active" OR whose Name matches the wildcard "*Test*".

        .EXAMPLE
        # Using numeric comparison
        # {
        #   "filters": [
        #     { "property": "Age", "operator": "gt", "value": 30 },
        #     { "property": "Department", "operator": "in", "value": ["HR","IT"] }
        #   ]
        # }
        Get-FilteredData -FilterPath 'C:\path\to\numeric-filters.json' -InputObject $people

        This returns people older than 30 AND whose Department is either "HR" or "IT" (logicalOperator defaults to "and").

        .NOTES
        - The comparison semantics use PowerShell operators; ensure types in filter.value are appropriate (numbers vs strings).
        - For "in", supply an array for filter.value in the JSON.
        - "like" uses PowerShell wildcard patterns; "match" uses regular expressions.
        - If a referenced property does not exist on an input object, the filter does not match, including for "ne".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $FilterPath,

        [Parameter(Mandatory = $true)]
        [System.Object[]] $InputObject
    )

    begin {
        $filterConfig = Get-Content -LiteralPath $FilterPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $filterConfig -or $null -eq $filterConfig.PSObject.Properties["filters"]) {
            throw "Filter configuration '$FilterPath' must contain a 'filters' array."
        }

        if ($filterConfig.filters -isnot [System.Array] -or $filterConfig.filters.Count -eq 0) {
            throw "Filter configuration '$FilterPath' must contain a non-empty 'filters' array."
        }

        foreach ($filter in $filterConfig.filters) {
            if ($null -eq $filter -or
                $null -eq $filter.PSObject.Properties["property"] -or
                $filter.property -isnot [System.String] -or
                [System.String]::IsNullOrWhiteSpace($filter.property) -or
                $null -eq $filter.PSObject.Properties["value"]) {
                throw "Each filter in '$FilterPath' must include a non-empty string 'property' and a 'value'."
            }
        }

        $filterConfig.filters | ForEach-Object { Write-Verbose -Message "$($MyInvocation.MyCommand): Filter: $($_.property) $($_.operator) $($_.value)" }
        $logicalOp = if ($null -eq $filterConfig.PSObject.Properties["logicalOperator"] -or [System.String]::IsNullOrWhiteSpace($filterConfig.logicalOperator)) {
            "and"
        }
        else {
            $filterConfig.logicalOperator
        }
        if ($logicalOp -isnot [System.String] -or $logicalOp -notin @("and", "or")) {
            throw "Filter configuration '$FilterPath' has an invalid 'logicalOperator'. Use 'and' or 'or'."
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand): Logical Operator: $logicalOp"
    }

    process {
        $results = foreach ($item in $InputObject) {
            $itemMatches = $true
            foreach ($filter in $filterConfig.filters) {
                $hasProperty = $false
                if ($null -ne $item) {
                    if ($item -is [System.Collections.IDictionary]) {
                        if ($item.Contains($filter.property)) {
                            $hasProperty = $true
                            $value = $item[$filter.property]
                        }
                    }
                    else {
                        $property = $item.PSObject.Properties[$filter.property]
                        if ($null -ne $property) {
                            $hasProperty = $true
                            $value = $property.Value
                        }
                    }
                }

                if (-not $hasProperty) {
                    $match = $false
                }
                else {
                    $match = switch ($filter.operator) {
                        "eq" { $value -eq $filter.value }
                        "ne" { $value -ne $filter.value }
                        "like" { $value -like $filter.value }
                        "match" { $value -match $filter.value }
                        "in" { $filter.value -contains $value }
                        "gt" { $value -gt $filter.value }
                        "lt" { $value -lt $filter.value }
                        "ge" { $value -ge $filter.value }
                        "le" { $value -le $filter.value }
                        default { $value -eq $filter.value }
                    }
                }

                if ($logicalOp -eq "and" -and -not $match) {
                    $itemMatches = $false
                    break
                }
                if ($logicalOp -eq "or" -and $match) {
                    $itemMatches = $true
                    break
                }
                if ($logicalOp -eq "or") {
                    $itemMatches = $false
                }
            }

            if ($itemMatches) {
                $item
            }
        }

        # Return the filtered results
        return $results
    }
}
