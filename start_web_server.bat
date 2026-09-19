@echo off
chcp 65001 >nul
title 修仙問道 v2 - 本地測試伺服器 (Port 4175)

cd /d "%~dp0"

echo ===================================================
echo   修仙問道 v2 - 本地 Web 測試伺服器
echo ===================================================
echo.

if not exist "build\web\index.html" (
    echo [提示] 找不到 build\web\index.html 匯出檔，正在自動執行 Godot Web 匯出...
    if not exist "build\web" mkdir "build\web"
    ".\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release Web "build\web\index.html"
    if errorlevel 1 (
        echo [錯誤] Web 匯出失敗，請檢查 Godot 引擎配置。
        pause
        exit /b 1
    )
    echo [成功] Web 匯出完成！
    echo.
)

echo [1/2] 正在啟動伺服器：http://127.0.0.1:4175
echo [2/2] 開啟預設瀏覽器進入遊戲...
echo.
echo ===================================================
echo   固定 Origin 測試網址：
echo   http://127.0.0.1:4175/index.html
echo.
echo   - 關閉此視窗或按 Ctrl + C 可停止伺服器
echo ===================================================
echo.

start http://127.0.0.1:4175/index.html

python -m http.server 4175 --bind 127.0.0.1 --directory "build\web"

pause
