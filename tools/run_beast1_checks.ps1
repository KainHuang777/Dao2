param([Parameter(Mandatory=$true)][string[]]$Only,[int]$TimeoutSeconds=45)
$ErrorActionPreference='Stop'
$daoWorkspace=Split-Path -Parent $PSScriptRoot
$daoEvidence=Join-Path $daoWorkspace ('docs/verification/artifacts/content-p2-beasts/runs/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $daoEvidence -Force | Out-Null
$env:TEMP=Join-Path $daoEvidence 'temp'
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
$env:DAO_TEST_STORAGE_ROOT=Join-Path $daoEvidence 'isolated-storage'
& "$PSScriptRoot/run_all_runners.ps1" -Only $Only -List *>&1 | Tee-Object -FilePath (Join-Path $daoEvidence 'selection.log')
$daoResult=0
try {
    & "$PSScriptRoot/run_all_runners.ps1" -Only $Only -TimeoutSeconds $TimeoutSeconds *>&1 | Tee-Object -FilePath (Join-Path $daoEvidence 'command.log')
} catch {
    $_ | Out-String | Tee-Object -FilePath (Join-Path $daoEvidence 'command.log') -Append
    $daoResult=1
}
Write-Output "[BEAST1 EVIDENCE] $daoEvidence result=$daoResult"
exit $daoResult
