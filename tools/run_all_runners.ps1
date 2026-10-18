param([string]$EnginePath = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe', [string]$StartAt = '')
$ErrorActionPreference = 'Stop'
$daoEngine = $EnginePath
$runners = @(
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


$passed = 0
$started = [string]::IsNullOrEmpty($StartAt)
if (-not $started -and $StartAt -notin $runners) { throw "Unknown runner: $StartAt" }
foreach ($r in $runners) {
	if ($r -eq $StartAt) { $started = $true }
	if (-not $started) { continue }
    Write-Host "[RUNNING] $r" -ForegroundColor Cyan
    & $daoEngine --headless --path . --script ("res://$r")
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Runner failed: $r with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    $passed++
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "ALL $passed RUNNERS PASSED WITH EXIT CODE 0!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
