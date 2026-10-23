Import-Module ./Evergreen/Evergreen.psd1 -Force -Verbose

foreach ($file in (Get-ChildItem -Path "./Evergreen/Private/*.ps1")) {
    . $file.FullName
}

foreach ($file in (Get-ChildItem -Path "./Evergreen/Shared/*.ps1")) {
    . $file.FullName
}
