"""Audit current UI1-C browser evidence and export isolation; no device claims."""
import ast
import hashlib
import json
import struct
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'docs/verification/artifacts/res1-ui1-c'


def pack_entries(path):
    with path.open('rb') as pack:
        magic, version, _, _, _, flags = struct.unpack('<6I', pack.read(24))
        assert magic == 0x43504447 and version in (3, 4) and not flags & 1
        _, directory = struct.unpack('<2Q', pack.read(16))
        pack.seek(directory)
        result = []
        for _ in range(struct.unpack('<I', pack.read(4))[0]):
            length = struct.unpack('<I', pack.read(4))[0]
            result.append(pack.read(length).rstrip(b'\0').decode('utf-8'))
            pack.read(36)
        return result


def audit():
    cases = defaultdict(list)
    records = []
    for line in (ART / 'browser.jsonl').read_text(encoding='utf-8').splitlines():
        raw = json.loads(line)
        status, payload = raw['report'].split('\n', 1)
        report = json.loads(payload)
        assert status == 'PASS' and not report['failures'], raw
        assert raw['url'].startswith('http://127.0.0.1:4293/?case=d2'), raw['url']
        cases[report['case']].append(report['checks'])
        records.append(report)
    required = {'d2progress', 'd2retry', 'd2quota', 'd2indexreload',
                'd2quotareload', 'd2lock', 'd2denied', 'd2corrupt', 'd2migration'}
    assert set(cases) == required, set(cases)
    assert len(cases['d2progress']) == 2, cases
    for case in ['d2indexreload', 'd2quotareload', 'd2lock']:
        assert len(cases[case]) == 3, f'{case} needs reload/owner-secondary-takeover evidence'
    assert len(records) == 16, len(records)
    builds = {}
    for name in ['web', 'res1-ui1-c-probe']:
        path = ROOT / 'build' / name / 'index.pck'
        builds[name] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bytes': path.stat().st_size}
    normal = pack_entries(ROOT / 'build/web/index.pck')
    probe = pack_entries(ROOT / 'build/res1-ui1-c-probe/index.pck')
    assert not any('/verification/' in p or '/tests/' in p for p in normal)
    for script in ['manufacturing_panel.gd', 'island_transport_panel.gd']:
        assert any(script in p for p in normal), script
    assert any('res1d2_contract.gd' in p for p in probe)
    for script in ['res1d2_web_server.py', 'res1_ui1c_audit.py']:
        ast.parse((ROOT / 'tools' / script).read_text(encoding='utf-8'))
    log = (ART / 'all-runners.log').read_text(encoding='utf-8-sig')
    assert 'ALL 56 RUNNERS PASSED WITH EXIT CODE 0' in log
    assert 'SCRIPT ERROR' not in log
    result = {'result': 'PASS', 'reports': len(records), 'checks': sum(r['checks'] for r in records),
              'cases': dict(cases), 'builds': builds, 'normal_excludes_test_harness': True,
              'note': 'Automated command flow includes simulated seconds/MemoryAdapter diagnostics. Live UI, rAF performance and physical touch are separate evidence.'}
    (ART / 'audit.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False))


if __name__ == '__main__':
    audit()
