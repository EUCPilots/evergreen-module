Write-Host "Importing Evergreen module..."
Import-Module ./Evergreen/Evergreen.psd1 -Force

Write-Host "Importing private scripts..."
foreach ($file in (Get-ChildItem -Path "./Evergreen/Private/*.ps1")) { 
    . $file.FullName
}
Write-Host "Importing shared scripts..."
foreach ($file in (Get-ChildItem -Path "./Evergreen/Shared/*.ps1")) {
    . $file.FullName
}

Write-Host "Evergreen apps path: $(Get-EvergreenAppsPath)"