"""ATM-LIFE-C delivery audit; sources/builds read only, task manifest written."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs/verification/artifacts/atm-life-c'
SOURCES = [
    'src/domain/life_echo.gd', 'src/domain/life_report.gd',
    'src/presentation/life_report_view.gd', 'src/verification/life_echo_fixture.gd',
    'src/verification/life_echo_acceptance.gd', 'src/verification/life_echo_acceptance.tscn',
    'tests/life_echo_runner.gd', 'tests/life_echo_ui_runner.gd',
    'tools/run_all_runners.ps1', 'tools/life_echo_audit.py', 'project.godot', 'export_presets.cfg',
    'assets/fonts/runtime/manifest.json', 'README.md', 'ROADMAP.md', 'docs/ai-handoff.md',
    'docs/development-status.md', 'docs/07-responsive-ui-web-spec.md', 'docs/19-ui-ux-guidelines.md',
    'docs/26-cultivation-life-atmosphere-research.md', 'docs/27-life-report-and-decision-ux-integration-plan.md',
    'docs/decisions/ADR-017-life-event-echoes.md', 'docs/verification/atm-life-c.md',
    'docs/verification/m2-d.md', 'updata.txt'
]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    sources, links = [], []
    for name in SOURCES:
        path = ROOT / name
        text = path.read_text(encoding='utf-8-sig')
        sources.append({'path': name, 'sha256': sha(path)})
        if path.suffix == '.gd':
            uid = path.with_suffix('.gd.uid')
            assert uid.read_text(encoding='utf-8').startswith('uid://')
            sources.append({'path': uid.relative_to(ROOT).as_posix(), 'sha256': sha(uid)})
        if name in ['docs/verification/atm-life-c.md', 'docs/decisions/ADR-017-life-event-echoes.md']:
            for link in re.findall(r'\]\(([^)]+)\)', text):
                if '://' in link or link.startswith('#'): continue
                target = (path.parent / link.split('#')[0]).resolve()
                assert target == OUT / 'final-manifest.json' or target.exists(), link
                links.append(link)
    prefix = (OUT / 'logs/all-corrected.log').read_text(encoding='utf-8-sig', errors='replace')
    tail = (OUT / 'logs/all-resume.log').read_text(encoding='utf-8-sig', errors='replace')
    expected = re.findall(r"'((?:tests/|tools/test_runner)[^']*\.gd)'", (ROOT / 'tools/run_all_runners.ps1').read_text(encoding='utf-8-sig'))
    boundary = expected.index('tests/life_report_runner.gd')
    assert re.findall(r'\[RUNNING\] ([^\r\n]+)', prefix) == expected[:boundary + 1]
    assert list(dict.fromkeys(re.findall(r'\[RUNNING\] ([^\r\n]+)', tail))) == expected[boundary:]
    assert f'ALL {len(expected)-boundary} RUNNERS PASSED WITH EXIT CODE 0!' in tail
    assert 'SCRIPT ERROR' not in prefix + tail
    for name, suite, count in [('core-verified-117.log', 'ATM-LIFE-C', 117), ('ui-verified.log', 'ATM-LIFE-C-UI', 25)]:
        raw = (OUT / 'logs' / name).read_text(encoding='utf-8-sig')
        rows = [json.loads(line) for line in raw.splitlines() if line.startswith('{')]
        assert any(row.get('suite') == suite and row.get('checks') == count and row.get('failures') == [] for row in rows)
        assert 'SCRIPT ERROR' not in raw
    builds = []
    for name in ['web-atm-life-c', 'atm-life-c-acceptance']:
        build = ROOT / 'build' / name
        compression = json.loads((build / 'compression.json').read_text(encoding='utf-8'))
        for row in compression['files'] + compression['audioFiles']:
            assert sha(build / row['file']) == row['sha256']
            if 'br_sha256' in row: assert sha(build / (row['file'] + '.br')) == row['br_sha256']
        assert len(compression['audioFiles']) == 4
        builds.append({'path': 'build/' + name, 'pck_sha256': sha(build / 'index.pck')})
    frozen = sha(ROOT / 'build/web/index.pck')
    assert frozen == '7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400'
    images = sorted(path.name for path in OUT.glob('*.png'))
    assert len(images) == 7
    browser = json.loads((OUT / 'browser-observations.json').read_text(encoding='utf-8'))
    assert browser['observations']['reload_archive_exactly_equal'] and browser['observations']['frozen_echo_count'] == 3
    exits = json.loads((OUT / 'command-exits.json').read_text(encoding='utf-8'))
    assert exits['all_first_segment'] == 1
    assert all(value == 0 for key, value in exits.items() if key != 'all_first_segment')
    result = {'task': 'ATM-LIFE-C', 'date': '2026-10-23', 'ok': True, 'fixed_runners': len(expected),
              'passed_prefix': boundary, 'passed_tail': len(expected)-boundary, 'final_script_errors': 0,
              'superseded_failures': ['assertions/release fixture', 'old biography int/float equality', 'initial UI locked route', 'initial parse/parity fixture'],
              'sources': sources, 'links': links, 'native_images': images, 'builds': builds,
              'frozen_web_sha256': frozen, 'browser': browser, 'command_exits': exits}
    (OUT / 'final-manifest.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'ok': True, 'fixed_runners': len(expected), 'utf8_files': len(sources), 'links': len(links), 'native_images': len(images)}))

if __name__ == '__main__':
    main()
