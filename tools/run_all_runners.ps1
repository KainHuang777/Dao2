<#
分級驗收（見 AGENTS.md「分級驗收」）：
  L1/L2 日常：  -Only 'content_p1_skills*','uix_r8*'   只跑受影響 runner，預設單一尺寸 1280x720
  L3 收尾：     -Full -Parallel 3                     全部 runner、全尺寸矩陣、並行；並行失敗會串行重跑確認
  全部單尺寸：  -Full -Matrix single -Parallel 3       全部 runner 只跑 1280x720（開發期全量驗證，非 L3 矩陣）
  預覽：        -Only 關鍵字 -List / -Full -List（不啟動引擎）
  無參數拒絕執行；-StartAt 必須搭配 -Only；-Full 不可搭配篩選。
#>
param(
    [string]$EnginePath = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe',
    [string]$StartAt = '',
    [string[]]$Only = @(),
    [switch]$Full,
    [switch]$List,
    [ValidateSet('auto', 'single', 'full')][string]$Matrix = 'auto',
    [ValidateRange(1, 8)][int]$Parallel = 1,
    [ValidateRange(1, 86400)][int]$TimeoutSeconds = 45
)
$ErrorActionPreference = 'Stop'
$daoEngine = $EnginePath
$matrix = if ($Matrix -ne 'auto') { $Matrix } elseif ($Full) { 'full' } else { 'single' }
$runners = @(
    'tests/world46_runner.gd',
    'tests/content_p2_story_sect_flow_runner.gd',
    'tests/content_p2_story_ui_runner.gd',
    'tests/content_p2_story_flow_runner.gd',
    'tests/content_p2_story_runner.gd',
    'tests/content_p2_story_save_runner.gd',
    'tests/content_p2_story_events_runner.gd',
    'tests/content_p2_beasts_ui_runner.gd',
    'tests/content_p2_beasts_flow_runner.gd',
    'tests/content_p2_beasts_runner.gd',
    'tests/content_p2_beasts_save_runner.gd',
    'tests/content_p2_sect_flow_runner.gd',
    'tests/content_p2_sect_ui_runner.gd',
    'tests/content_p2_sect_runner.gd',
    'tests/content_p2_sect_save_runner.gd',
    'tests/content_p2_pills_flow_runner.gd',
    'tests/content_p2_pills_ui_runner.gd',
    'tests/content_p2_pills_runner.gd',
    'tests/content_p2_pills_save_runner.gd',
    'tests/content_p2_talents_flow_runner.gd',
    'tests/content_p2_talents_ui_runner.gd',
    'tests/content_p2_talents_runner.gd',
	'tests/content_p2_supply_progression_runner.gd',
	'tests/content_p2_supply_ui_runner.gd',
	'tests/content_p2_supply_data_runner.gd',
	'tests/content_p2_supply_economy_runner.gd',
	'tests/content_p1_accept_runner.gd',
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
    'tests/sks_p2_core_runner.gd',
    'tests/sks_p2_flow_runner.gd',
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


$projectRoot = Split-Path $PSScriptRoot -Parent
$Only = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if (-not $Full -and $Only.Count -eq 0) { throw 'Select affected runners with -Only, or explicitly use -Full for L3. Use -List to preview.' }
if ($Full -and ($Only.Count -gt 0 -or $StartAt)) { throw '-Full requires the complete registry; do not combine with -Only or -StartAt.' }
foreach ($pattern in $Only) {
    if (-not @($runners | Where-Object { $_ -like "*$pattern*" }).Count) { throw "Unknown runner selector: $pattern" }
}
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
if (-not $Full -and $selected.Count -eq $runners.Count) { throw 'Selection covers the entire registry; use -Full explicitly for L3.' }
foreach ($r in $selected) {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $r))) { throw "Missing runner: $r" }
}
Write-Host "[MODE] matrix=$matrix runners=$($selected.Count) parallel=$Parallel" -ForegroundColor Yellow
if ($List) { $selected | ForEach-Object { Write-Output $_ }; return }
$resolvedEngine = (Resolve-Path -LiteralPath $daoEngine).Path
$logDir = Join-Path $env:TEMP ("dao2_runners_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $logDir | Out-Null
Write-Host "[LOGS] $logDir"
# Test output isolation: runners write under an ignored project folder, never into tracked evidence.
# A caller-provided DAO_TEST_STORAGE_ROOT is respected.
$storageRoot = if ($env:DAO_TEST_STORAGE_ROOT) { $env:DAO_TEST_STORAGE_ROOT } else { Join-Path $projectRoot ('.test-output\' + (Split-Path $logDir -Leaf)) }
New-Item -ItemType Directory -Force -Path $storageRoot | Out-Null
Write-Host "[STORAGE] $storageRoot"
$guardPaths = @('docs/verification/artifacts', 'src/verification')
function Get-GuardState {
    $s = & git -C $projectRoot status --porcelain -- @guardPaths 2>$null
    # Status already detects deletion/addition changes. Avoid expanding the moved
    # legacy backup deletions or asking Git to find renames among those files.
    $d = (& git -c core.safecrlf=false -C $projectRoot diff --no-renames --diff-filter=AM -- @guardPaths 2>$null | Out-String)
    $h = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($d)))
    @($s) + @("diff-sha256 $h")
}
$guardBefore = @(Get-GuardState)

function Stop-RunnerTree([int]$procId) {
    # CIM may be unavailable in a restricted desktop session. The engine is
    # launched directly, so stopping the owned process still enforces timeout.
    $children = @()
    try { $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $procId" -ErrorAction Stop) } catch { Write-Verbose "CIM unavailable; stopping directly owned engine PID $procId" }
    foreach ($c in $children) { Stop-RunnerTree $c.ProcessId }
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
}

$timings = @{}
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Invoke-Batch([string[]]$RunnerList, [int]$Slots, [string]$Attempt) {
    $queue = [System.Collections.Queue]::new($RunnerList)
    $running = @()
    $failed = @()
    try {
        while ($queue.Count -gt 0 -or $running.Count -gt 0) {
            while ($queue.Count -gt 0 -and $running.Count -lt $Slots) {
                $r = $queue.Dequeue()
                $log = Join-Path $logDir (($r -replace '[\\/]', '_') + ".$Attempt.log")
                $err = $log + '.err'
                Write-Host "[START:$Attempt] $r" -ForegroundColor Cyan
                # Child-only environment: no DAO_VIEWPORT_MATRIX leak into later commands.
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = $resolvedEngine
                $psi.Arguments = "--headless --path `"$projectRoot`" --script res://$r"
                $psi.WorkingDirectory = $projectRoot
                $psi.EnvironmentVariables['DAO_VIEWPORT_MATRIX'] = $matrix
                $psi.EnvironmentVariables['DAO_TEST_STORAGE_ROOT'] = $storageRoot
                $psi.UseShellExecute = $false
                $psi.CreateNoWindow = $true
                $psi.RedirectStandardOutput = $true
                $psi.RedirectStandardError = $true
                $psi.StandardOutputEncoding = $utf8
                $psi.StandardErrorEncoding = $utf8
                try {
                    $p = [System.Diagnostics.Process]::Start($psi)
                } catch {
                    [IO.File]::WriteAllText($log, "launch error: $($_.Exception.Message)", $utf8)
                    $timings[$r] = 0
                    $failed += $r
                    Write-Host "[FAIL:$Attempt] $r launch_error=True" -ForegroundColor Red
                    continue
                }
                $running += [pscustomobject]@{
                    Runner = $r; Proc = $p; Clock = [Diagnostics.Stopwatch]::StartNew()
                    Out = $p.StandardOutput.ReadToEndAsync(); Err = $p.StandardError.ReadToEndAsync()
                    Log = $log; ErrorLog = $err
                }
            }
            Start-Sleep -Milliseconds 100
            foreach ($j in @($running)) {
                $timedOut = -not $j.Proc.HasExited -and $j.Clock.Elapsed.TotalSeconds -gt $TimeoutSeconds
                if (-not $j.Proc.HasExited -and -not $timedOut) { continue }
                if ($timedOut) {
                    Stop-RunnerTree $j.Proc.Id
                    if (-not $j.Proc.WaitForExit(5000)) {
                        $j.Proc.Kill()
                        $null = $j.Proc.WaitForExit(2000)
                    }
                } else {
                    $j.Proc.WaitForExit()
                }
                $stdout = $j.Out.GetAwaiter().GetResult()
                $stderr = $j.Err.GetAwaiter().GetResult()
                [IO.File]::WriteAllText($j.Log, $stdout, $utf8)
                [IO.File]::WriteAllText($j.ErrorLog, $stderr, $utf8)
                $timings[$j.Runner] = $j.Clock.Elapsed.TotalSeconds
                $code = if ($j.Proc.HasExited) { $j.Proc.ExitCode } else { -1 }
                $combined = $stdout + "`n" + $stderr
                $scriptError = $combined -match '(?m)^\s*SCRIPT ERROR:'
                $failureMarker = $combined -match '(?m)^\s*(?:FAIL(?:ED)?\s*[:：]|\[FAIL\])'
                $results = [regex]::Matches($stdout, '(?m)^\s*RUNNER_RESULT\s+(.+?)\s*$')
                $resultPass = $results.Count -eq 1 -and $results[0].Groups[1].Value -match '^status=PASS\s+exit=0$'
                if ($timedOut -or $code -ne 0 -or $scriptError -or $failureMarker -or -not $resultPass) {
                    $failed += $j.Runner
                    Write-Host "[FAIL:$Attempt] $($j.Runner) exit=$code timeout=$timedOut script_error=$scriptError failure_marker=$failureMarker result_lines=$($results.Count) result=$resultPass" -ForegroundColor Red
                    Write-Host $combined
                } else {
                    Write-Host "[PASS:$Attempt] $($j.Runner) ($([math]::Round($j.Clock.Elapsed.TotalSeconds, 1))s) result=pass"
                }
                $j.Proc.Dispose()
                $running = @($running | Where-Object { $_ -ne $j })
            }
        }
    } finally {
        foreach ($j in $running) {
            if (-not $j.Proc.HasExited) { Stop-RunnerTree $j.Proc.Id }
            $j.Proc.Dispose()
        }
    }
    return $failed
}

$failed = @(Invoke-Batch $selected $Parallel 'initial')
if ($Parallel -gt 1 -and $failed.Count -gt 0) {
    Write-Host "[RETRY-SERIAL] $($failed.Count) runner(s); same timeout applies" -ForegroundColor Yellow
    $failed = @(Invoke-Batch $failed 1 'serial-retry')
}
$guardAfter = @(Get-GuardState)
$guardDiff = @(Compare-Object $guardBefore $guardAfter | ForEach-Object { $_.InputObject })
if ($guardDiff.Count -gt 0) {
    Write-Host "[GUARD] evidence directories changed during run ($($guardDiff.Count)):" -ForegroundColor Red
    $guardDiff | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    throw 'Runner wrote into tracked evidence directories; route its output through DAO_TEST_STORAGE_ROOT.'
}
Write-Host '--- slowest 8 runners (s) ---'
$timings.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 8 | ForEach-Object { Write-Host ("{0,8:N1}  {1}" -f $_.Value, $_.Key) }
if ($failed.Count -gt 0) { throw "Runner verification failed: $($failed -join ', '). Logs: $logDir" }
Write-Host "SELECTED $($selected.Count) RUNNERS PASSED (matrix=$matrix). Logs: $logDir" -ForegroundColor Green
