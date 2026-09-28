# Tools/start_web_server.ps1
# Starts Python local HTTP server on port 4175 with fixed origin for Web testing
param (
    [switch]$ForceExport = $false
)
$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\.."

$webDir = ".\build\web"
$indexFile = "$webDir\index.html"
$pckFile = "$webDir\index.pck"

$needExport = $ForceExport -or (-not (Test-Path $indexFile)) -or (-not (Test-Path $pckFile))

if (-not $needExport) {
    $pckTime = (Get-Item $pckFile).LastWriteTime
    $latestSrc = Get-ChildItem -Path @(".\src", ".\scenes", ".\project.godot") -Recurse -File -ErrorAction SilentlyContinue |
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

# Clean up any dangling process on port 4175 before starting
$oldConns = Get-NetTCPConnection -LocalPort 4175 -State Listen -ErrorAction SilentlyContinue
if ($oldConns) {
    foreach ($conn in $oldConns) {
        $oldPid = $conn.OwningProcess
        if ($oldPid -gt 0) {
            Write-Host "[INFO] Releasing port 4175 from existing process PID $oldPid..." -ForegroundColor Yellow
            Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Milliseconds 300
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Dao2 - Local Fixed Origin Web Server" -ForegroundColor Cyan
Write-Host "  URL: http://127.0.0.1:4175/index.html" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan

# Open browser shortly after server starts listening
Start-Job -ScriptBlock {
    Start-Sleep -Milliseconds 800
    Start-Process "http://127.0.0.1:4175/index.html"
} | Out-Null

python -m http.server 4175 --bind 127.0.0.1 --directory $webDir

