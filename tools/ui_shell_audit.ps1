$ErrorActionPreference = 'Stop'
$daoRoot = Split-Path -Parent $PSScriptRoot
$daoPaths = @(
    'src/presentation/ui_shell_policy.gd',
    'src/presentation/ui_shell_state.gd',
    'src/presentation/feature_navigation.gd',
    'src/presentation/abode_hud_controller.gd',
    'src/presentation/abode_modal_manager.gd',
    'src/abode/living_abode.gd',
    'src/presentation/feature_unlocks.gd',
    'src/presentation/fortune_modal.gd',
    'src/simulation/fortune_system.gd'
)
$daoRecords = foreach ($daoRelative in $daoPaths) {
    $daoPath = Join-Path $daoRoot $daoRelative
    $daoLines = [IO.File]::ReadAllLines($daoPath, [Text.Encoding]::UTF8)
    $daoFunction = ''
    $daoFindings = for ($daoIndex = 0; $daoIndex -lt $daoLines.Length; $daoIndex++) {
        $daoLine = $daoLines[$daoIndex]
        if ($daoLine -match '^(?:static )?func ([^(]+)') { $daoFunction = $Matches[1] }
        if ($daoLine -match '(header|resource_ribbon|hint_panel)\.visible\s*=|\.reparent\(|feature_navigation\.(open|home|back)|^func (_toggle_|_on_settings|_on_more|_unhandled_key|_on_.*sequence)|pending_encounter') {
            [ordered]@{ line = $daoIndex + 1; function = $daoFunction; source = $daoLine.Trim() }
        }
    }
    [ordered]@{ path = $daoRelative; sha256 = (Get-FileHash -LiteralPath $daoPath -Algorithm SHA256).Hash; findings = @($daoFindings) }
}
$daoOutput = Join-Path $daoRoot 'docs/verification/artifacts/ui-shell-0/source-audit.json'
$daoJson = [ordered]@{ task = 'UI-SHELL-0'; date = '2026-10-22'; scope = 'Static source inventory; not runtime reachability or browser evidence'; files = @($daoRecords) } | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($daoOutput, $daoJson + "`n", [Text.UTF8Encoding]::new($false))
Write-Output ('UI-SHELL audit: {0} source hashes -> {1}' -f $daoRecords.Count, $daoOutput)
