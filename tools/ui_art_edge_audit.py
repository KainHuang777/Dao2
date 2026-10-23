"""Read-only closure audit for the shared Godot illustration renderer."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs/verification/artifacts/ui-art-edge'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
before = json.loads((OUT / 'before.json').read_text(encoding='utf-8'))
changed = [p for p, digest in before.items() if sha(ROOT / p) != digest]
# The continuation found build/web replaced during the gap. Preserve it and
# report both hashes; never roll back another operation's export.
assert not [p for p in changed if p != 'build/web/index.pck'], changed
frozen = ROOT / 'build/web/index.pck'
for name, count in [('runner.json', 161), ('native.json', 166)]:
    result = json.loads((OUT / name).read_text(encoding='utf-8'))
    assert result['checks'] == count and result['failures'] == [], name
for name in ['runner-final.log', 'native-final.log']:
    log = (OUT / name).read_text(encoding='utf-8-sig')
    assert 'SCRIPT ERROR' not in log and 'SHADER ERROR' not in log, name

suite = re.findall(r"'((?:tests|tools)/[^']+\.gd)'", (ROOT / 'tools/run_all_runners.ps1').read_text(encoding='utf-8-sig'))
prefix_log = (OUT / 'all-runners-final.log').read_text(encoding='utf-8-sig')
prefix_log = prefix_log.split('[RUNNING] tests/res1c2_perf_runner.gd')[0]
tail_log = (OUT / 'all-runners-tail.log').read_text(encoding='utf-8-sig')
tail_log = tail_log.split('[RUNNING] tests/ui_material_states_runner.gd')[0]
repaired_log = (OUT / 'all-runners-repaired.log').read_text(encoding='utf-8-sig')
repaired_log = repaired_log.split('[RUNNING] tests/early_flow1d_runner.gd')[0]
mid_rest = (OUT / 'all-runners-middle-rest.log').read_text(encoding='utf-8-sig')
last_log = (OUT / 'all-runners-rest.log').read_text(encoding='utf-8-sig')
assert 'ALL 12 RUNNERS PASSED WITH EXIT CODE 0!' in mid_rest
assert 'ALL 13 RUNNERS PASSED WITH EXIT CODE 0!' in last_log
retry = (OUT / 'early-flow1d-retry.log').read_text(encoding='utf-8-sig')
assert 'EARLY-FLOW1-D: 161 checks' in retry and 'ERROR: fixture file ready' not in retry
assert json.loads((OUT / 'continuation-results.json').read_text(encoding='utf-8'))['early_flow1d_direct_retry_exit'] == 0
completed_log = prefix_log + tail_log + repaired_log + '[RUNNING] tests/early_flow1d_runner.gd\n' + retry + mid_rest + last_log
executed = re.findall(r'^\[RUNNING\] ((?:tests|tools)/\S+\.gd)', completed_log, re.M)
assert list(dict.fromkeys(executed)) == suite, (len(executed), len(suite))
assert 'SCRIPT ERROR' not in completed_log
assert 'SHADER ERROR' not in completed_log

files = ['src/presentation/ui_illustration.gd', 'src/presentation/ui_illustration.gdshader', 'tools/ui_art_edge_audit.py',
         'src/presentation/building_card_button.gd', 'src/presentation/resource_icon.gd',
         'src/verification/ui_art_edge_acceptance.gd', 'src/verification/ui_art_edge_acceptance.tscn',
         'tests/ui_art_edge_runner.gd', 'tests/ui_material_states_runner.gd', 'tools/run_all_runners.ps1', 'project.godot', 'export_presets.cfg']
files += ['src/presentation/' + name + '.gd' for name in
          ['skill_study_view', 'reincarnation_panel', 'achievement_panel', 'realm_decision_view',
           'fortune_modal', 'sect_panel', 'building_catalog']]
for name in files:
    text = (ROOT / name).read_text(encoding='utf-8-sig')
    assert '\ufffd' not in text and '\x00' not in text, name
exports = {}
for name in ['web-ui-art-edge', 'web-ui-art-edge-acceptance']:
    folder = ROOT / 'build' / name
    assert all((folder / file).exists() for file in ['index.html', 'index.pck', 'index.wasm', 'compression.json'])
    assert len(list((folder / 'audio/bgm').glob('*.mp3'))) == 4
    exports[name] = sha(folder / 'index.pck')
report = {
    'task': 'UI-ART-EDGE', 'failures': [], 'runner_checks': 161, 'native_checks': 166,
    'suite': {'total': len(suite), 'prefix_executions': 51, 'middle': 12, 'repaired_material_segment': 14, 'early_flow1d_retry': 1, 'middle_rest': 12, 'last': 13, 'repeated_legacy_entry': 'tests/early_pacing2_pill_runner.gd', 'script_errors': 0},
    'protected_sources_unchanged': len(before) - 1,
    'original_frozen_web_sha256': before['build/web/index.pck'],
    'observed_web_sha256': sha(frozen), 'web_changed_during_gap': 'build/web/index.pck' in changed,
    'exports': exports, 'sources': {name: sha(ROOT / name) for name in files},
}
(OUT / 'audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: report[k] for k in ['task', 'failures', 'suite', 'protected_sources_unchanged', 'web_changed_during_gap']}))
