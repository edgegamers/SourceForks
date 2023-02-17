
Write-Host "::::    =========================="
Write-Host "::::    TESTING GAMEDATA FOR CS:GO"
Write-Host "::::    =========================="

$base = Get-Location

Set-Location test
& ./test.ps1 -SUPPRESS_BUILD:$True

Write-Host "::::    ==========================="
Write-Host "::::    BUILDING INDIVIDUAL PLUGINS"
Write-Host "::::    ==========================="

Set-Location $base
Set-Location src
& ./build.ps1

Write-Host "::::    ============================"
Write-Host "::::    PACKAGING SOURCEFORKS ASSETS"
Write-Host "::::    ============================"

Set-Location $base

if (Test-Path -PathType Container package)
{
    Write-Host "* Clearing old package"
    Remove-Item -Path package -Recurse
}

Write-Host "* Creating package directory"
New-Item -Path package -Type Directory

Write-Host "* Creating directories"
New-Item -Path package/addons -Type Directory
New-Item -Path package/addons/sourcemod -Type Directory

Copy-Item -Recurse -Path gamedata -Destination package/addons/sourcemod
Remove-Item -Path package/addons/sourcemod/gamedata/partial -Recurse
# ^ Remove partial gamedatas

Copy-Item -Recurse -Path src/plugins -Destination package/addons/sourcemod
Copy-Item -Recurse -Path src/cfg -Destination package/

Write-Host "::::    =========================="
Write-Host "::::    COMPRESSING PACKAGE TO ZIP"
Write-Host "::::    =========================="

Compress-Archive -Force -Path package/* -DestinationPath sourceforks.zip
Write-Host "* Done!"