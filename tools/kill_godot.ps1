[CmdletBinding()]
param(
    [switch]$All,
    [switch]$DryRun
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$localGodotDir = Join-Path $projectRoot "tools\godot"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Dao2 - Godot Process Cleaner Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$processes = Get-Process -Name "*godot*" -ErrorAction SilentlyContinue

if (-not $processes -or $processes.Count -eq 0) {
    Write-Host "[INFO] No running Godot processes found in system." -ForegroundColor Green
    exit 0
}

$targets = @()

foreach ($proc in $processes) {
    $procPath = $null
    try {
        $procPath = $proc.Path
    } catch {
        # ignore access error
    }

    $isLocal = $false
    if ($procPath -and $procPath.StartsWith($localGodotDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        $isLocal = $true
    }

    if ($All -or $isLocal) {
        $cpuTime = 0
        try {
            if ($proc.CPU) { $cpuTime = [math]::Round($proc.CPU, 2) }
        } catch {
            $cpuTime = 0
        }

        $targets += [PSCustomObject]@{
            Id          = $proc.Id
            ProcessName = $proc.ProcessName
            Path        = $procPath
            CPU         = $cpuTime
            IsLocal     = $isLocal
            Process     = $proc
        }
    }
}

if ($targets.Count -eq 0) {
    Write-Host "[INFO] Other Godot processes are running, but none belong to this project ($localGodotDir)." -ForegroundColor Yellow
    Write-Host "       To terminate ALL Godot processes, run with: .\tools\kill_godot.ps1 -All" -ForegroundColor Gray
    exit 0
}

Write-Host ("Found {0} matching Godot process(es):" -f $targets.Count) -ForegroundColor Yellow
foreach ($t in $targets) {
    Write-Host ("  [PID: {0,6}] {1} (CPU: {2}s) -> {3}" -f $t.Id, $t.ProcessName, $t.CPU, $t.Path)
}

if ($DryRun) {
    Write-Host "`n[DryRun Mode] No processes were terminated." -ForegroundColor Magenta
    exit 0
}

Write-Host "`nTerminating process(es)..." -ForegroundColor Cyan
$killedCount = 0
foreach ($t in $targets) {
    try {
        Stop-Process -Id $t.Id -Force -ErrorAction Stop
        Write-Host ("  [KILLED] PID {0} ({1})" -f $t.Id, $t.ProcessName) -ForegroundColor Green
        $killedCount++
    } catch {
        Write-Warning ("  [FAILED] Could not terminate PID {0}: {1}" -f $t.Id, $_)
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host ("  Successfully terminated {0} Godot process(es)!" -f $killedCount) -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
