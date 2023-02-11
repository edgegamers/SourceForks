Write-Host "========================="
Write-Host "BUILDING DOCKER CONTAINER"
Write-Host "========================="

docker build --file Dockerfile . -t sourceforks-smx:latest

Write-Host "==========================="
Write-Host "RUNNING SOURCEPAWN COMPILER"
Write-Host "==========================="

if (Test-Path -PathType Container plugins)
{
    Write-Host "* Clearing old plugins"
    Remove-Item -Path plugins -Recurse
}

Write-Host "* Creating output directory"
New-Item -Path plugins -Type Directory

$compile_list = Get-ChildItem -Path ./scripting -File | Foreach-Object {$_.BaseName}

foreach ($plugin in $compile_list)
{
    Write-Host "* Compiling $plugin"
    docker run --name="sourceforks-smx-session" sourceforks-smx:latest "${plugin}.sp"
    Write-Host "* Compiled! Copying $plugin"
    docker cp sourceforks-smx-session:scripting/${plugin}.smx plugins/
    Write-Host "* Closing Temporary Session"
    docker rm sourceforks-smx-session
    Write-Host "* Finished compiling $plugin"
}

