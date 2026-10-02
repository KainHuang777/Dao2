$ErrorActionPreference = 'Stop'
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$runners = @(
    'tools/test_runner.gd',
    'tests/abode_state_runner.gd',
    'tests/living_abode_runner.gd',
    'tests/m0c_compat_v3_runner.gd',
    'tests/m1a_core_runner.gd',
    'tests/m1b_time_runner.gd',
    'tests/m1c_persistence_runner.gd',
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
    'tests/m4a_realm_runner.gd',
    'tests/bgm_era_playlist_runner.gd',
    'tests/m3b_chrono_runner.gd',
    'tests/m4b_scale_law_runner.gd',
    'tests/m5a_world_gen_runner.gd',
    'tests/m3b_fortune_runner.gd',
    'tests/m3b_fortune_ui_runner.gd',
    'tests/m5b_realm_content_runner.gd',
    'tests/m3b_spirit_beast_runner.gd'
)


$passed = 0
foreach ($r in $runners) {
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
