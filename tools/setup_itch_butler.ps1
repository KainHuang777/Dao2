<# Download the official Windows x64 butler into ignored build/tools; no PATH/account changes. #>
param()
$ErrorActionPreference = 'Stop'
$daoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$daoToolDir = Join-Path $daoRoot 'build/tools/butler'
New-Item -ItemType Directory -Path $daoToolDir -Force | Out-Null
$daoButler = Join-Path $daoToolDir 'butler.exe'
if (-not (Test-Path -LiteralPath $daoButler -PathType Leaf)) {
    $daoArchive = Join-Path $daoToolDir 'butler.zip'
    Invoke-WebRequest -Uri 'https://broth.itch.zone/butler/windows-amd64/LATEST/archive/default' -OutFile $daoArchive -UseBasicParsing
    Expand-Archive -LiteralPath $daoArchive -DestinationPath $daoToolDir -Force
    $daoHash = (Get-FileHash -LiteralPath $daoArchive -Algorithm SHA256).Hash
    Write-Host "[DOWNLOAD] Official itch.io broth stable archive; SHA256=$daoHash"
}
& $daoButler version
if ($LASTEXITCODE -ne 0) { throw 'butler version check failed.' }
Write-Host '[NEXT] Run deploy_itch_web.bat -Action Login and complete the authorization yourself.'
