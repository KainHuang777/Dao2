$ErrorActionPreference='Stop'
$daoEvidence=Join-Path (Split-Path $PSScriptRoot -Parent) 'docs/verification/artifacts/content-p2-beasts-closure'
$env:TEMP=Join-Path $daoEvidence 'supplement-logs'
$env:TMP=$env:TEMP
$env:DAO_TEST_STORAGE_ROOT=Join-Path $daoEvidence 'supplement-isolated-storage'
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
& "$PSScriptRoot/run_all_runners.ps1" -Only content_p2_supply_progression_runner.gd -List *> "$daoEvidence/supplement-list.log"
$daoCode=0
# Both 600s attempts advanced normally into Era6. This single formal flow
# includes every level plus simulated lifespan exhaustion and reincarnation.
try { & "$PSScriptRoot/run_all_runners.ps1" -Only content_p2_supply_progression_runner.gd -Matrix full -TimeoutSeconds 1800 *> "$daoEvidence/supplement-command.log" }
catch { $_ | Out-String | Add-Content "$daoEvidence/supplement-command.log" -Encoding UTF8; $daoCode=1 }
$daoCode | Set-Content "$daoEvidence/supplement-exit.txt" -Encoding UTF8
Write-Output "supply supplement exit=$daoCode"
exit $daoCode
