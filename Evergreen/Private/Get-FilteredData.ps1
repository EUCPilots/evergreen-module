function Get-FilteredData {
    <#
        .SYNOPSIS
        Filters an array of objects using a JSON-based filter configuration file.

        .DESCRIPTION
        Get-FilteredData reads a JSON filter configuration from the file specified by -FilterPath and applies the configured filters to the array provided via -InputObject.
        The JSON file must include a "filters" array of filter objects and may include a top-level "logicalOperator" (defaults to "and").
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
        - If a referenced property does not exist on an input object, that comparison yields $null behavior according to the operator (typically treated as not matching).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String] $FilterPath,

        [Parameter(Mandatory = $true)]
        [System.Object[]] $InputObject
    )

    $filterConfig = Get-Content -Path $FilterPath -Raw | ConvertFrom-Json
    $logicalOp = if ($filterConfig.logicalOperator) { $filterConfig.logicalOperator } else { "and" }

    $results = $InputObject | Where-Object {
        $item = $_
        $matches = [System.Collections.ArrayList]::new()

        foreach ($filter in $filterConfig.filters) {
            $match = switch ($filter.operator) {
                "eq" { $item.$($filter.property) -eq $filter.value }
                "ne" { $item.$($filter.property) -ne $filter.value }
                "like" { $item.$($filter.property) -like $filter.value }
                "match" { $item.$($filter.property) -match $filter.value }
                "in" { $filter.value -contains $item.$($filter.property) }
                "gt" { $item.$($filter.property) -gt $filter.value }
                "lt" { $item.$($filter.property) -lt $filter.value }
                "ge" { $item.$($filter.property) -ge $filter.value }
                "le" { $item.$($filter.property) -le $filter.value }
                default { $item.$($filter.property) -eq $filter.value }
            }
            [void]$matches.Add([bool]$match)
        }

        if ($logicalOp -eq "and") {
            $matches -notcontains $false
        }
        else {
            $matches -contains $true
        }
    }

    return $results
}
