@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\deploy_itch_web.ps1" %*
if errorlevel 1 (
  echo Deployment failed. Read the error above.
  pause
  exit /b 1
)
pause
