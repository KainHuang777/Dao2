param([ValidateSet('full','export','compression','rebase')][string]$Step)
$ErrorActionPreference='Stop'
$daoEvidence=Join-Path (Split-Path $PSScriptRoot -Parent) 'docs/verification/artifacts/content-p2-beasts-closure'
$env:TEMP=Join-Path $daoEvidence 'logs'
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
$env:DAO_TEST_STORAGE_ROOT=Join-Path $daoEvidence 'isolated-storage'
$daoResult=0
try {
 if ($Step -eq 'full') {
  & "$PSScriptRoot/run_all_runners.ps1" -Full -List *> "$daoEvidence/full-list.log"
  # Known formal lifespan/supply flows take 2–6 minutes, longer under three engines.
  & "$PSScriptRoot/run_all_runners.ps1" -Full -Parallel 3 -TimeoutSeconds 600 *> "$daoEvidence/full-command.log"
 } elseif ($Step -eq 'export') {
  New-Item -ItemType Directory -Path build/web-content-p2-beasts -Force | Out-Null
  & .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web build/web-content-p2-beasts/index.html *> "$daoEvidence/export.log"
  $daoResult=$LASTEXITCODE
 } elseif ($Step -eq 'rebase') {
  & .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/beast2_closure_fixture.gd *> "$daoEvidence/rebase.log"
  $daoResult=$LASTEXITCODE
 } else {
  & node tools/prepare_web_compression.mjs build/web-content-p2-beasts *> "$daoEvidence/compression.log"
  $daoResult=$LASTEXITCODE
 }
} catch { $_ | Out-String | Add-Content -Encoding utf8 "$daoEvidence/$Step-command.log"; $daoResult=1 }
$daoResult | Out-File -Encoding utf8 "$daoEvidence/$Step-exit.txt"
Write-Output "$Step exit=$daoResult"
exit $daoResult
