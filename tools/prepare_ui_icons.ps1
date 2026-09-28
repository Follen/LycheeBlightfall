# Convert the selected imagegen PNGs for WoW; preserve alpha and original artwork.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
foreach ($name in @('launcher','talent','thanks')) {
    $source = Join-Path $projectRoot "assets/footer-icons/$name.png"
    $target = Join-Path $projectRoot "addon/LycheeBlightfall_Core/Media/$name.tga"
    ffmpeg -hide_banner -loglevel error -y -i $source -vf scale=128:128 -pix_fmt bgra -c:v targa -rle 0 -frames:v 1 $target
    if ($LASTEXITCODE -ne 0) { throw "Icon conversion failed: $name" }
}
