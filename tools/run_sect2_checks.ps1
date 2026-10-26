param([Parameter(Mandatory=$true)][string[]]$Only,[int]$TimeoutSeconds=45)
$ErrorActionPreference='Stop'
$daoWorkspace = Split-Path -Parent $PSScriptRoot
$daoEvidence = Join-Path $daoWorkspace ('docs/verification/artifacts/content-p2-sect-ui/runs/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $daoEvidence -Force | Out-Null
$env:DAO_TEST_STORAGE_ROOT = Join-Path $daoEvidence 'isolated-storage'
& "$PSScriptRoot/run_all_runners.ps1" -Only $Only -List *>&1 | Tee-Object -FilePath (Join-Path $daoEvidence 'selection.log')
$daoStart = Get-Date
$daoResult = 0
try {
    & "$PSScriptRoot/run_all_runners.ps1" -Only $Only -TimeoutSeconds $TimeoutSeconds *>&1 | Tee-Object -FilePath (Join-Path $daoEvidence 'command.log')
} catch {
    $_ | Out-String | Tee-Object -FilePath (Join-Path $daoEvidence 'command.log') -Append
    $daoResult = 1
} finally {
    # Keep stdout/stderr before the sandbox's temporary directory disappears.
    Get-ChildItem -LiteralPath $env:TEMP -Directory -Filter 'dao2_runners_*' | Where-Object { $_.CreationTime -ge $daoStart.AddSeconds(-1) } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $daoEvidence $_.Name) -Recurse
    }
}
Write-Output "[SECT2 EVIDENCE] $daoEvidence result=$daoResult"
exit $daoResult
