param(
    [int]$Samples = 120,
    [int]$IntervalSeconds = 5,
    [string]$Output = 'docs/verification/artifacts/res1-c2-degradation-gpu.jsonl'
)
$ErrorActionPreference = 'Stop'
# Read-only OS counters. Store process roles, never command lines or user paths.
for ($daoIndex = 0; $daoIndex -lt $Samples; $daoIndex++) {
    $daoRoles = @(Get-CimInstance Win32_Process -Filter "Name = 'ChatGPT.exe'" | ForEach-Object {
        $daoRole = if ($_.CommandLine -match '--type=([^ ]+)') { $Matches[1] } else { 'main' }
        @{ pid = $_.ProcessId; parent = $_.ParentProcessId; role = $daoRole }
    })
    $daoGpu = @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine |
        Where-Object UtilizationPercentage -gt 0 |
        Select-Object Name, UtilizationPercentage)
    @{ utc = [DateTime]::UtcNow.ToString('o'); roles = $daoRoles; gpu = $daoGpu } |
        ConvertTo-Json -Depth 5 -Compress | Add-Content -LiteralPath $Output -Encoding utf8
    Start-Sleep -Seconds $IntervalSeconds
}
