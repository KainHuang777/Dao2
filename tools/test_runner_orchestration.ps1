# Isolated CLI contract tests; fake engine never loads Godot or player data.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$testDir = Join-Path $env:TEMP ('dao2_orchestration_test_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDir | Out-Null
$fake = Join-Path $testDir 'fake-engine.exe'
Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Threading;
public class FakeEngine {
    public static int Main(string[] args) {
        string mode = Environment.GetEnvironmentVariable("DAO_TEST_MODE");
        Console.WriteLine("matrix=" + Environment.GetEnvironmentVariable("DAO_VIEWPORT_MATRIX"));
        if (mode == "timeout") Thread.Sleep(10000);
        if (mode == "script-error") Console.Error.WriteLine("SCRIPT ERROR: synthetic failure");
        if (mode == "fail") return 7;
        if (mode == "retry") {
            string marker = Environment.GetEnvironmentVariable("DAO_TEST_MARKER");
            if (!File.Exists(marker)) { File.WriteAllText(marker, "first"); return 9; }
        }
        return 0;
    }
}
"@ -OutputAssembly $fake -OutputType ConsoleApplication
$script:checks = 0
function Check([bool]$condition, [string]$label) {
    if (-not $condition) { throw "FAIL: $label" }
    $script:checks++
    Write-Host "PASS: $label"
}
function Run([string[]]$options) {
    $ErrorActionPreference = 'Continue'
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File "$root/tools/run_all_runners.ps1" @options 2>&1
    return @{ Code = $LASTEXITCODE; Text = ($output -join "`n") }
}
$previousMatrix = $env:DAO_VIEWPORT_MATRIX
$previousMode = $env:DAO_TEST_MODE
$previousMarker = $env:DAO_TEST_MARKER
try {
    $env:DAO_VIEWPORT_MATRIX = 'caller-sentinel'
    $r = Run @()
    Check ($r.Code -ne 0 -and $r.Text.Contains('Select affected runners')) 'empty invocation refuses full suite'
    $r = Run @('-Only', 'm1a_core,typo_selector', '-List')
    Check ($r.Code -ne 0 -and $r.Text.Contains('Unknown runner selector')) 'each selector validated'
    $r = Run @('-Only', '*', '-List')
    Check ($r.Code -ne 0 -and $r.Text.Contains('entire registry')) 'broad selector cannot bypass explicit Full'
    $r = Run @('-Full', '-Only', 'm1a_core', '-List')
    Check ($r.Code -ne 0) 'Full rejects partial selection'
    $r = Run @('-Only', ' m1a_core , recipe_row ', '-List')
    Check ($r.Code -eq 0 -and $r.Text.Contains('runners=2') -and $r.Text.Contains('matrix=single')) 'trimmed comma selectors and preview'
    $r = Run @('-Full', '-List', '-EnginePath', 'nonexistent.exe')
    Check ($r.Code -eq 0 -and $r.Text.Contains('matrix=full')) 'Full preview never starts engine'
    $env:DAO_TEST_MODE = 'pass'
    $r = Run @('-Only', 'm1a_core', '-EnginePath', $fake)
    Check ($r.Code -eq 0 -and $r.Text.Contains('SELECTED 1')) 'serial successful engine'
    $logMatch = [regex]::Match($r.Text, '\[LOGS\] ([^\r\n]+)')
    $engineLog = Get-Content -Raw -LiteralPath (Join-Path $logMatch.Groups[1].Value 'tests_m1a_core_runner.gd.initial.log')
    Check ($engineLog.Contains('matrix=single')) 'child engine receives single matrix'
    Check ($env:DAO_VIEWPORT_MATRIX -eq 'caller-sentinel') 'caller matrix preserved'
    $env:DAO_TEST_MODE = 'script-error'
    $r = Run @('-Only', 'm1a_core', '-EnginePath', $fake)
    Check ($r.Code -ne 0 -and $r.Text.Contains('script_error=True')) 'SCRIPT ERROR with exit zero fails'
    $env:DAO_TEST_MODE = 'timeout'
    $r = Run @('-Only', 'm1a_core', '-EnginePath', $fake, '-TimeoutSeconds', '1')
    if (-not $r.Text.Contains('timeout=True')) { Write-Host $r.Text }
    Check ($r.Code -ne 0 -and $r.Text.Contains('timeout=True')) 'serial watchdog terminates hung engine'
    $r = Run @('-Only', 'm1a_core', '-EnginePath', $fake, '-Parallel', '2', '-TimeoutSeconds', '1')
    Check ($r.Code -ne 0 -and $r.Text.Contains('RETRY-SERIAL') -and $r.Text.Contains('FAIL:serial-retry') -and $r.Text.Contains('timeout=True')) 'parallel timeout and retry watchdog both enforced'
    $env:DAO_TEST_MODE = 'retry' 
    $env:DAO_TEST_MARKER = Join-Path $testDir 'retry.marker'
    $r = Run @('-Only', 'm1a_core', '-EnginePath', $fake, '-Parallel', '2')
    Check ($r.Code -eq 0 -and $r.Text.Contains('RETRY-SERIAL') -and $r.Text.Contains('PASS:serial-retry')) 'parallel failure retries serially'
    $env:DAO_TEST_MODE = 'fail'
    $r = Run @('-Only', 'm1a_core', '-EnginePath', $fake, '-Parallel', '2')
    Check ($r.Code -ne 0 -and $r.Text.Contains('exit=7') -and $r.Text.Contains('FAIL:serial-retry')) 'confirmed retry failure stays failed'
    $env:DAO_TEST_MODE = 'pass'
    $r = Run @('-Only', 'm1a_core,recipe_row', '-EnginePath', $fake, '-Parallel', '2')
    Check ($r.Code -eq 0 -and $r.Text.Contains('SELECTED 2')) 'parallel queue runs two selected entries'
    Write-Host "PASS: $script:checks orchestration checks; artifacts=$testDir"
} finally {
    $env:DAO_VIEWPORT_MATRIX = $previousMatrix
    $env:DAO_TEST_MODE = $previousMode
    $env:DAO_TEST_MARKER = $previousMarker
}
