$Url = "https://www.airlockdigital.com/hubfs/Allowlist%20Auditor/Airlock%20Digital%20-%20Allowlisting%20Auditor%20V4.exe"
$Path = "$Env:ProgramFiles\AirLock"
New-Item -Path $Path -ItemType "Directory"
$params = @{
    URI             = $Url
    OutFile         = "$Path\Airlock Digital - Allowlisting Auditor V4.exe"
    UseBasicParsing = $true
}
Invoke-WebRequest @params


https://mobaxterm.mobatek.net/download.html
irm -Uri "https://mobaxterm.mobatek.net/lastver.php?pro=free&version=24%2E2&beta=0&wget=true" -UserAgent "MobaXterm" -UseBasicParsing

$params = @{
    Uri             = "https://mobaxterm.mobatek.net/lastver.php?pro=pro&version=24%2E2&beta=0&wget=true"
    Headers         = @{
        "User-Agent"    = "MobaXterm Pro"
        "Cache-Control" = "no-cache"
    }
}
Invoke-RestMethod @params


$params = @{
    Uri             = "https://www.vandyke.com/cgi-bin/dl_update.php"
    UseBasicParsing = $true
    UserAgent       = "VanDyke Update"
    ContentType     = "application/x-www-form-urlencoded"
    Method          = "POST"
    Headers         = @{
        'Cache-Control' = "no-cache"
    }
    Form            = @{
        data = "02|003-001-0000000000|9.3.2|2978|0||10-05-2024|WIN|x64|0|0|0"
    }
}
Invoke-RestMethod @params


$params = @{
    Uri             = "https://mobaxterm.mobatek.net/lastver.php?pro=non_pro&version=24%2E1&beta=0&wget=true"
    Headers         = @{
        "User-Agent"    = "MobaXterm"
        "Cache-Control" = "no-cache"
    }
}
Invoke-RestMethod @params
