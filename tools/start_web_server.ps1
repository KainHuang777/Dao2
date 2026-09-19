# Tools/start_web_server.ps1
# Starts Python local HTTP server on port 4175 with fixed origin for Web testing
$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\.."

$webDir = ".\build\web"
$indexFile = "$webDir\index.html"

if (-not (Test-Path $indexFile)) {
    Write-Host "[提示] 找不到 $indexFile，正在自動執行 Web Release 匯出..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $webDir -Force | Out-Null
    & ".\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release Web $indexFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Godot Web 匯出失敗。"
        exit 1
    }
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  修仙問道 v2 - 本地固定 Origin 測試伺服器" -ForegroundColor Cyan
Write-Host "  網址: http://127.0.0.1:4175/index.html" -ForegroundColor Green
Write-Host "  按 Ctrl+C 可停止伺服器" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan

Start-Process "http://127.0.0.1:4175/index.html"
python -m http.server 4175 --bind 127.0.0.1 --directory $webDir
