function Get-MicrosoftOneDrive {
    <#
        .SYNOPSIS
            Returns the current version and download URL for the Microsoft OneDrive sync client for Windows.

        .NOTES
            Site: https://stealthpuppy.com
            Author: Aaron Parker
            Twitter: @stealthpuppy
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]
        $res = (Get-FunctionResource -AppName ("$($MyInvocation.MyCommand)".Split("-"))[1])
    )

    # Step through each release URI
    foreach ($ring in $res.Get.Update.Uri.GetEnumerator()) {
        $params = @{
            Uri         = $res.Get.Update.Uri[$ring.Key]
            ContentType = $res.Get.Update.ContentType
            Raw         = $true
            ErrorAction = "Stop"
        }
        [System.XML.XMLDocument] $xmlDocument = Invoke-EvergreenWebRequest @params

        # Build an output object by selecting installer entries from the feed
        if ($xmlDocument -is [System.XML.XMLDocument]) {

            # Select the required node/s from the XML feed
            $nodes = Select-Xml -Xml $xmlDocument -XPath $res.Get.Update.XmlNode | Select-Object -ExpandProperty "node"

            # Find the latest version
            foreach ($node in $nodes) {
                if ([System.Boolean]($node.PSobject.Properties.name -match "^amd64binary$")) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): AMD64 binary for: $($node.currentversion) in: $($ring.Name)."
                    [PSCustomObject] @{
                        Version      = $node.currentversion
                        Ring         = $ring.Name
                        Throttle     = $node.throttle
                        Sha256       = ConvertFrom-Base64String -Base64String $node.amd64binary.sha256hash
                        Architecture = Get-Architecture -String $node.amd64binary.url
                        Type         = Get-FileType -File $node.amd64binary.url
                        URI          = $node.amd64binary.url
                    } | Write-Output
                }

                if ([System.Boolean]($node.PSobject.Properties.name -match "^arm64binary$")) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): ARM64 binary for: $($node.currentversion) in: $($ring.Name)."
                    [PSCustomObject] @{
                        Version      = $node.currentversion
                        Ring         = $ring.Name
                        Throttle     = $node.throttle
                        Sha256       = ConvertFrom-Base64String -Base64String $node.arm64binary.sha256hash
                        Architecture = Get-Architecture -String $node.arm64binary.url
                        Type         = Get-FileType -File $node.arm64binary.url
                        URI          = $node.arm64binary.url
                    } | Write-Output
                }

                if ([System.Boolean]($node.PSobject.Properties.name -match "^msixbinary$")) {
                    # Construct the output for MSIX; Return the custom object to the pipeline
                    Write-Verbose -Message "$($MyInvocation.MyCommand): MSIX binary for: $($node.currentversion) in: $($ring.Name)."
                    [PSCustomObject] @{
                        Version      = $node.currentversion
                        Ring         = $ring.Name
                        Throttle     = $node.throttle
                        Sha256       = if ($node.msixbinary.sha256hash) { ConvertFrom-Base64String -Base64String $node.msixbinary.sha256hash } else { "N/A" }
                        Architecture = Get-Architecture -String $node.msixbinary.url
                        Type         = Get-FileType -File $node.msixbinary.url
                        URI          = $node.msixbinary.url
                    } | Write-Output
                }

                # Construct the output for EXE; Return the custom object to the pipeline
                if ([System.Boolean]($node.PSobject.Properties.name -match "^binary$")) {
                    Write-Verbose -Message "$($MyInvocation.MyCommand): x86 binary for: $($node.currentversion) in: $($ring.Name)."
                    $PSObject = [PSCustomObject] @{
                        Version      = $node.currentversion
                        Ring         = $ring.Name
                        Throttle     = $node.throttle
                        Sha256       = ConvertFrom-Base64String -Base64String $node.binary.sha256hash
                        Architecture = "x86"
                        Type         = Get-FileType -File $node.binary.url
                        URI          = $node.binary.url
                    }
                    Write-Output -InputObject $PSObject
                }
            }
        }
    }
}
