<#
分級驗收（見 AGENTS.md「分級驗收」）：
  L1/L2 日常：  -Only 'content_p1_skills*','uix_r8*'   只跑受影響 runner，預設單一尺寸 1280x720
  L3 收尾：     -Full -Parallel 3                     全部 runner、全尺寸矩陣、並行；並行失敗會串行重跑確認
  舊用法：      無參數＝全量串行單尺寸；-StartAt 續跑
#>
param(
    [string]$EnginePath = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe',
    [string]$StartAt = '',
    [string[]]$Only = @(),
    [switch]$Full,
    [int]$Parallel = 1,
    [int]$TimeoutSeconds = 45
)
$ErrorActionPreference = 'Stop'
$daoEngine = $EnginePath
$env:DAO_VIEWPORT_MATRIX = if ($Full) { 'full' } else { 'single' }
$runners = @(
	'tests/content_p1_story_runner.gd',
	'tests/content_p1_story_events_runner.gd',
	'tests/content_p1_story_progression_runner.gd',
	'tests/content_p1_story_ui_runner.gd',
	'tests/content_p1_sect_progression_runner.gd',
	'tests/content_p1_sect_runner.gd',
	'tests/content_p1_sect_ui_runner.gd',
	'tests/content_p1_pills_runner.gd',
	'tests/content_p1_pills_ui_runner.gd',
	'tests/ui_art_edge_runner.gd',
	'tests/content_p1_talents_runner.gd',
	'tests/content_p1_talents_ui_runner.gd',
	'tests/content_p1_skills_runner.gd',
	'tests/content_p1_skills_progression_runner.gd',
	'tests/content_p1_skills_ui_runner.gd',
	'tests/life_echo_runner.gd',
	'tests/life_echo_ui_runner.gd',
	'tests/life_history_runner.gd',
	'tests/life_history_ui_runner.gd',
	'tests/resource_accounts_runner.gd',
	'tests/resource_accounts_ui_runner.gd',
	'tests/decision_receipt_runner.gd',
	'tests/decision_ui_runner.gd',
	'tests/life_report_runner.gd',
	'tests/life_report_ui_runner.gd',
	'tests/life_ledger_runner.gd',
	'tests/ui_shell_matrix_runner.gd',
	'tests/ui_shell_integration_runner.gd',
	'tests/ui_shell_policy_runner.gd',
	'tests/mfg3_inline_runner.gd',
	'tests/mfg_controller_runner.gd',
	'tests/recipe_row_runner.gd',
	'tests/tribc_integration_runner.gd',
	'tests/trib0_outcome_runner.gd',
	'tests/reincarnation_motion_runner.gd',
	'tests/uix_r11_decisions_ui_runner.gd',
	'tests/uix_r10_fortune_ui_runner.gd',
    'tests/hud_readiness_life_runner.gd',
    'tests/uix_r9_sect_ui_runner.gd',
    'tests/uix_r4_building_cards_runner.gd',
    'tests/uix_r2_hud_runner.gd',
    'tests/gather_guidance_highlight_runner.gd',
    'tests/early_pacing_runner.gd',
    'tests/early_pacing2_runner.gd',
    'tests/early_pacing2_pill_runner.gd',
    'tools/test_runner.gd',
    'tests/abode_state_runner.gd',
    'tests/living_abode_runner.gd',
    'tests/m0c_compat_v3_runner.gd',
    'tests/m1a_core_runner.gd',
    'tests/res1a_processing_runner.gd',
    'tests/res1b_economy_runner.gd',
    'tests/res1c_progression_runner.gd',
    'tests/res1d2_integration_runner.gd',
    'tests/res1d2_world_runner.gd',
    'tests/res1_ui1a_runner.gd',
    'tests/res1_ui1b_runner.gd',
    'tests/res1c2_offline_runner.gd',
    'tests/offline_closed_form_parity_runner.gd',
    'tests/res1c2_perf_runner.gd',
    'tests/resource_feedback_runner.gd',
    'tests/m1b_time_runner.gd',
    'tests/m1c_persistence_runner.gd',
    'tests/web_persistence_fault_runner.gd',
    'tests/m1d_offline_runner.gd',
    'tests/m1e_import_runner.gd',
    'tests/m2a_abode_runner.gd',
    'tests/m2b_breakthrough_runner.gd',
    'tests/island_breakthrough_runner.gd',
    'tests/m2c_nine_realms_runner.gd',
    'tests/m2d_responsive_ui_runner.gd',
    'tests/ui_material_states_runner.gd',
    'tests/text_transition_runner.gd',
    'tests/m2d_slice_release_runner.gd',
    'tests/m3a_reincarnation_runner.gd',
    'tests/m3a_reincarnation_ui_runner.gd',
    'tests/m3b_alchemy_runner.gd',
    'tests/m3b_alchemy_ui_runner.gd',
    'tests/m3b_sect_runner.gd',
    'tests/m3b_sect_ui_runner.gd',
    'tests/buff_system_runner.gd',
    'tests/debug_features_runner.gd',
    'tests/core_positive_flow_runner.gd',
    'tests/early_flow1b_runner.gd',
    'tests/early_flow1c_runner.gd',
    'tests/early_flow1d_runner.gd',
    'tests/m4a_realm_runner.gd',
    'tests/m4a_session_integration_runner.gd',
    'tests/bgm_era_playlist_runner.gd',
    'tests/m3b_chrono_runner.gd',
    'tests/m4b_scale_law_runner.gd',
    'tests/m5a_world_gen_runner.gd',
    'tests/m3b_fortune_runner.gd',
    'tests/m3b_fortune_ui_runner.gd',
    'tests/m5b_realm_content_runner.gd',
    'tests/feature_navigation_runner.gd',
    'tests/skills_b1_runner.gd',
    'tests/sks_p1_runner.gd',
    'tests/early_v1b_talents_runner.gd',
    'tests/early_v1c_skills_runner.gd',
    'tests/uix_r8_skills_ui_runner.gd',
    'tests/m3b_spirit_beast_runner.gd',
    'tests/abode_scenery_runner.gd',
    'tests/abode_scenery_ui_runner.gd',
    'tests/m3b_achievement_runner.gd',
    'tests/debug_autobuild_and_time_runner.gd',
    'tests/debug_actions_runner.gd',
    'tests/runtime_inspector_runner.gd',
    'tests/simulation_sandbox_runner.gd',
    'tests/uix_r1_components_runner.gd',
    'tests/batch_a_pills_runner.gd'
)


$Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$started = [string]::IsNullOrEmpty($StartAt)
if (-not $started -and $StartAt -notin $runners) { throw "Unknown runner: $StartAt" }
$selected = @()
foreach ($r in $runners) {
    if ($r -eq $StartAt) { $started = $true }
    if (-not $started) { continue }
    if ($Only.Count -gt 0 -and -not ($Only | Where-Object { $r -like "*$_*" })) { continue }
    $selected += $r
}
if ($selected.Count -eq 0) { throw 'No runner matched the selection' }
Write-Host "[MODE] matrix=$($env:DAO_VIEWPORT_MATRIX) runners=$($selected.Count) parallel=$Parallel" -ForegroundColor Yellow

function Stop-RunnerTree([int]$procId) {
    $children = Get-CimInstance Win32_Process -Filter "ParentProcessId = $procId" -ErrorAction SilentlyContinue
    foreach ($c in $children) {
        Stop-RunnerTree $c.ProcessId
    }
    try { Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue } catch {}
}

$timings = @{}
function Invoke-Serial([string[]]$list) {
    foreach ($r in $list) {
        Write-Host "[RUNNING] $r" -ForegroundColor Cyan
        $sw = [Diagnostics.Stopwatch]::StartNew()
        & $daoEngine --headless --path . --script ("res://$r")
        $code = $LASTEXITCODE
        $timings[$r] = $sw.Elapsed.TotalSeconds
        if ($code -ne 0) {
            Write-Error "Runner failed: $r with exit code $code"
            exit $code
        }
    }
}

if ($Parallel -le 1) {
    Invoke-Serial $selected
} else {
    $logDir = Join-Path $env:TEMP 'dao2_runners'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $resolvedEngine = (Resolve-Path $daoEngine).Path
    $queue = [System.Collections.Queue]::new($selected)
    $running = @()
    $failed = @()
    while ($queue.Count -gt 0 -or $running.Count -gt 0) {
        while ($queue.Count -gt 0 -and $running.Count -lt $Parallel) {
            $r = $queue.Dequeue()
            $log = Join-Path $logDir (($r -replace '[\\/]', '_') + '.log')
            $err = $log + '.err'
            Write-Host "[START] $r" -ForegroundColor Cyan
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "cmd.exe"
            $psi.Arguments = "/c `"`"$resolvedEngine`" --headless --path . --script res://$r > `"$log`" 2> `"$err`"`""
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $p = [System.Diagnostics.Process]::Start($psi)
            $running += [pscustomobject]@{ Runner = $r; Proc = $p; Started = Get-Date }
        }
        Start-Sleep -Milliseconds 300
        foreach ($j in @($running)) {
            $elapsed = ((Get-Date) - $j.Started).TotalSeconds
            if ($j.Proc.HasExited) {
                $code = $j.Proc.ExitCode
                $timings[$j.Runner] = $elapsed
                if ($code -ne 0) {
                    $failed += $j.Runner
                    Write-Host "[FAIL-PARALLEL] $($j.Runner) exit $code" -ForegroundColor Yellow
                }
                $running = @($running | Where-Object { $_ -ne $j })
            } elseif ($elapsed -gt $TimeoutSeconds) {
                Write-Host "[TIMEOUT-PARALLEL] $($j.Runner) exceeded ${TimeoutSeconds}s, killing..." -ForegroundColor Red
                Stop-RunnerTree $j.Proc.Id
                $timings[$j.Runner] = $elapsed
                $failed += $j.Runner
                $running = @($running | Where-Object { $_ -ne $j })
            }
        }
    }
    if ($failed.Count -gt 0) {
        Write-Host "[RETRY-SERIAL] $($failed.Count) runner(s) failed in parallel; rerun serially to confirm" -ForegroundColor Yellow
        Invoke-Serial $failed
    }
}

Write-Host '--- slowest 8 runners (s) ---'
$timings.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 8 | ForEach-Object { Write-Host ("{0,8:N1}  {1}" -f $_.Value, $_.Key) }
Write-Host "========================================" -ForegroundColor Green
Write-Host "ALL $($selected.Count) RUNNERS PASSED WITH EXIT CODE 0! (matrix=$($env:DAO_VIEWPORT_MATRIX))" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
