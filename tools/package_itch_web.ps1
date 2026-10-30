# Tools/package_itch_web.ps1
# Packages the Godot Web export into an itch.io compatible zip archive.
param (
    [string]$OutputDir = "build",
    [string]$ZipName = "dao2-itch-web.zip",
    [switch]$ForceExport = $false
)

$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\.."

$webDir = ".\build\web"
$indexFile = "$webDir\index.html"
$pckFile = "$webDir\index.pck"

# 1. Ensure latest export exists
$needExport = $ForceExport -or (-not (Test-Path $indexFile)) -or (-not (Test-Path $pckFile))

if (-not $needExport) {
    $pckTime = (Get-Item $pckFile).LastWriteTime
    $latestSrc = Get-ChildItem -Path @(".\src", ".\scenes", ".\assets", ".\content", ".\project.godot", ".\export_presets.cfg") -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latestSrc -and ($latestSrc.LastWriteTime -gt $pckTime)) {
        Write-Host "[INFO] Source files updated, exporting Web..." -ForegroundColor Yellow
        $needExport = $true
    }
}

if ($needExport) {
    Write-Host "[INFO] Exporting Godot Web Release..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $webDir -Force | Out-Null
    & ".\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release Web $indexFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Godot Web Export Failed."
        exit 1
    }
    Write-Host "[SUCCESS] Web Release exported successfully!" -ForegroundColor Green
}

# 2. Ensure Audio is in place
$webAudioDir = Join-Path $webDir 'audio/bgm'
New-Item -ItemType Directory -Path $webAudioDir -Force | Out-Null
$webAudioCatalog = Get-Content -LiteralPath assets/audio/bgm/library.json -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($track in $webAudioCatalog) {
    if ($track.filename -notmatch '^0[1-4]_[A-Za-z_]+\.mp3$') { throw 'Invalid BGM filename' }
    $src = Join-Path 'src/BGM' $track.filename
    $dst = Join-Path $webAudioDir $track.filename
    if (-not (Test-Path $dst) -or ((Get-Item $src).LastWriteTime -gt (Get-Item $dst).LastWriteTime)) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

# 3. Create staging directory for itch.io (clean distribution)
$stagingDir = Join-Path $OutputDir "itch-staging"
if (Test-Path $stagingDir) {
    Remove-Item -Path $stagingDir -Recurse -Force
}
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

Write-Host "[INFO] Staging files for itch.io..." -ForegroundColor Cyan

# Files to copy (exclude .br, .import, compression.json, logs)
$filesToCopy = Get-ChildItem -Path $webDir -Recurse -File | Where-Object {
    $_.Extension -ne ".br" -and
    $_.Extension -ne ".import" -and
    $_.Extension -ne ".log" -and
    $_.Name -ne "compression.json"
}

$fullWeb = (Resolve-Path $webDir).Path
foreach ($file in $filesToCopy) {
    $relPath = $file.FullName.Substring($fullWeb.Length).TrimStart('\', '/')
    $targetPath = Join-Path $stagingDir $relPath
    $targetParent = [System.IO.Path]::GetDirectoryName($targetPath)
    if (-not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    Copy-Item -LiteralPath $file.FullName -Destination $targetPath -Force
}

# 4. Create ZIP archive
$targetZip = Join-Path $OutputDir $ZipName
if (Test-Path $targetZip) {
    Remove-Item -Path $targetZip -Force
}

Write-Host "[INFO] Compressing into $targetZip ..." -ForegroundColor Cyan
# Compress using System.IO.Compression with fastest or optimal level
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stagingDir, $targetZip, [System.IO.Compression.CompressionLevel]::Fastest, $false)

# Clean staging directory
Remove-Item -Path $stagingDir -Recurse -Force

# 5. Summary
$zipItem = Get-Item $targetZip
$sizeMB = [math]::Round($zipItem.Length / 1MB, 2)
Write-Host "===================================================" -ForegroundColor Green
Write-Host "  itch.io Package Ready!" -ForegroundColor Green
Write-Host "  File: $($zipItem.FullName)" -ForegroundColor White
Write-Host "  Size: $sizeMB MB" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Green
