param([ValidateSet('full','export','rebase','compression')][string]$Step)
$ErrorActionPreference = 'Continue'
$daoEvidence = 'docs/verification/artifacts/content-p2-pills-closure'
if ($Step -eq 'full') {
    & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 1800 *> "$daoEvidence/full-command.log"
} elseif ($Step -eq 'export') {
    & .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web build/web-content-p2-pills/index.html *> "$daoEvidence/export.log"
} elseif ($Step -eq 'rebase') {
    & .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/pill2_closure_fixture.gd *> "$daoEvidence/rebase.log"
} else {
    & node tools/prepare_web_compression.mjs build/web-content-p2-pills *> "$daoEvidence/compression.log"
}
$daoExit = $LASTEXITCODE
$daoExit | Out-File -Encoding utf8 "$daoEvidence/$Step-exit.txt"
Write-Output "$Step exit=$daoExit"
exit $daoExit
