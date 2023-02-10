
Write-Host "* Fetching latest CS:GO version..."
$uptodate = ConvertFrom-JSON( Invoke-WebRequest -Uri "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=0" )

$csgo_version = $uptodate.response.required_version
Write-Host "* Latest CS:GO version is $csgo_version."

Write-Host "========================="
Write-Host "BUILDING DOCKER CONTAINER"
Write-Host "========================="

docker build --file Dockerfile ../ -t sourceforks-gdc:latest --build-arg CSGOVERSION=$csgo_version

Write-Host "========================"
Write-Host "RUNNING GAMEDATA CHECKER"
Write-Host "========================"

$gamedatafiles = "sourceforks_antilag.games.txt"

foreach ($gamedata in $gamedatafiles)
{
    docker run --rm sourceforks-gdc:latest -f /test/gamedata/$gamedata -g csgo -e csgo -b /test/server/csgo/bin/server.so -w /test/server/csgo/bin/server.dll -x /test/server/bin/engine.so -y /test/server/bin/engine.dll -s /test/tools/gdc/symbols.txt > output.temp

    luajit parse_results.lua $gamedata
}

Write-Host "========================"
Write-Host "EXPORTING CS:GO BINARIES"
Write-Host "========================"

$export_binaries = "bin/engine.so", "bin/engine.dll", "csgo/bin/server.so", "csgo/bin/server.dll"

Write-Host "* Starting Export Container"
docker run --name sourceforks-exporter-dummy sourceforks-gdc:latest > output.temp

foreach ($binary in $export_binaries)
{
    Write-Host "* Exporting $binary"
    docker cp sourceforks-exporter-dummy:test/server/$binary ./bin
}

Write-Host "* Deleting Export Container"
docker rm sourceforks-exporter-dummy