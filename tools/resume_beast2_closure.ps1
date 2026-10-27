$ErrorActionPreference='Stop'
$daoEvidence=Join-Path (Split-Path $PSScriptRoot -Parent) 'docs/verification/artifacts/content-p2-beasts-closure'
$daoLog=Get-Content "$daoEvidence/full-command.log" -Raw -Encoding UTF8
$daoPassed=@([regex]::Matches($daoLog,'(?m)^\[PASS:(?:initial|serial-retry)\] (\S+)') | ForEach-Object {$_.Groups[1].Value})
$daoRegistry=@(Get-Content "$daoEvidence/full-list.log" -Encoding UTF8 | Where-Object {$_ -match '\.gd$'})
$daoRemaining=@($daoRegistry | Where-Object {$_ -notin $daoPassed})
$daoRemaining | Set-Content "$daoEvidence/resume-selection.txt" -Encoding UTF8
$env:TEMP=Join-Path $daoEvidence 'host-logs'
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
$env:DAO_TEST_STORAGE_ROOT=Join-Path $daoEvidence 'host-isolated-storage'
& "$PSScriptRoot/run_all_runners.ps1" -Only $daoRemaining -List *> "$daoEvidence/resume-list.log"
$daoCode=0
try { & "$PSScriptRoot/run_all_runners.ps1" -Only $daoRemaining -Matrix full -Parallel 3 -TimeoutSeconds 600 *> "$daoEvidence/resume-command.log" }
catch { $_ | Out-String | Add-Content "$daoEvidence/resume-command.log" -Encoding UTF8; $daoCode=1 }
$daoCode | Set-Content "$daoEvidence/resume-exit.txt" -Encoding UTF8
Write-Output "resume count=$($daoRemaining.Count) exit=$daoCode"
exit $daoCode
