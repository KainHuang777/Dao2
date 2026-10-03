$ErrorActionPreference = 'Stop'
$daoProject = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $daoProject
try {
    $daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
    $daoVersion = & $daoEngine --version
    if ($LASTEXITCODE -ne 0 -or $daoVersion -ne '4.7.2.stable.official.ed1daf0bf') { throw "Unexpected Godot version: $daoVersion" }
    # Windows PowerShell wraps native stderr as NativeCommandError. Negative
    # corruption tests intentionally emit stderr; the native exit code is authoritative.
    $ErrorActionPreference = 'Continue'
    & $daoEngine --headless --path . --script res://tests/res1b_economy_runner.gd *> docs/verification/artifacts/res1-b-economy-final.log
    if ($LASTEXITCODE -ne 0) { throw 'RES1-B economy runner failed; inspect res1-b-economy-final.log' }
    foreach ($daoMode in @('seed', 'resume', 'verify')) {
        & $daoEngine --headless --path . --script res://tests/res1b_cross_process_runner.gd -- $daoMode *> "docs/verification/artifacts/res1-b-cross-process-$daoMode.log"
        if ($LASTEXITCODE -ne 0) { throw "RES1-B cross-process $daoMode failed" }
    }
    Write-Output 'PASS: RES1-B economy and three independent persistence processes. Logs: docs/verification/artifacts/res1-b-*.log'
} finally {
    Pop-Location
}
