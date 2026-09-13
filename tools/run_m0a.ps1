[CmdletBinding()]
param(
    [string]$EnginePath = (Join-Path $PSScriptRoot 'godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$cycleProbeRoot = Join-Path $projectRoot 'probes\cycle'

if (-not (Test-Path -LiteralPath $EnginePath)) {
    throw "Godot 4.7.2 executable was not found: $EnginePath"
}

function Invoke-GodotStep {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string[]]$GodotArguments
    )
    Write-Host "[M0-A] $Name"
    & $EnginePath --headless --path $ProjectPath @GodotArguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Invoke-GodotStep -Name 'Root project import' -ProjectPath $projectRoot -GodotArguments @('--import')
Invoke-GodotStep -Name 'Root storage and font fixture' -ProjectPath $projectRoot -GodotArguments @('--script', 'res://tools/test_runner.gd')
Invoke-GodotStep -Name 'Abode state fixture' -ProjectPath $projectRoot -GodotArguments @('--script', 'res://tests/abode_state_runner.gd')
Invoke-GodotStep -Name 'Abode scene fixture' -ProjectPath $projectRoot -GodotArguments @('--script', 'res://tests/living_abode_runner.gd')
Invoke-GodotStep -Name 'Living abode startup' -ProjectPath $projectRoot -GodotArguments @('--quit-after', '3')

Invoke-GodotStep -Name 'Cycle probe import' -ProjectPath $cycleProbeRoot -GodotArguments @('--import')
Invoke-GodotStep -Name 'Cycle probe fixture' -ProjectPath $cycleProbeRoot -GodotArguments @('--script', 'res://tests/cycle_probe_runner.gd')

New-Item -ItemType Directory -Path (Join-Path $projectRoot 'build\web') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot 'build\web-probe') -Force | Out-Null
Invoke-GodotStep -Name 'Living abode Web export' -ProjectPath $projectRoot -GodotArguments @('--export-release', 'Web', (Join-Path $projectRoot 'build\web\index.html'))
Invoke-GodotStep -Name 'Cycle probe Web export' -ProjectPath $cycleProbeRoot -GodotArguments @('--export-release', 'Web', (Join-Path $projectRoot 'build\web-probe\index.html'))

Write-Host '[M0-A] CLI checks and both Web exports passed.'
Write-Host '[M0-A] Serve the living abode on http://127.0.0.1:4175 and the isolated cycle probe on http://127.0.0.1:4176.'
