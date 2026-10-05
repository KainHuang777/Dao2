"""Check saved browser reports and release/test pack isolation, not FPS or input."""
import ast
import hashlib
import json
import struct
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'docs/verification/artifacts'


def entries(path):
    with path.open('rb') as pack:
        magic, version, major, minor, patch, flags = struct.unpack('<6I', pack.read(24))
        assert magic == 0x43504447 and version in (3, 4) and not flags & 1
        _, directory = struct.unpack('<2Q', pack.read(16))
        pack.seek(directory)
        names = []
        for _ in range(struct.unpack('<I', pack.read(4))[0]):
            length = struct.unpack('<I', pack.read(4))[0]
            names.append(pack.read(length).rstrip(b'\0').decode('utf-8'))
            pack.read(36)
        return names


records = []
cases = defaultdict(list)
for line in (ART / 'res1-d2-web-browser.jsonl').read_text(encoding='utf-8').splitlines():
    raw = json.loads(line)
    status, payload = raw['report'].split('\n', 1)
    report = json.loads(payload)
    assert status == 'PASS' and not report['failures'], raw
    assert raw['url'].startswith('http://127.0.0.1:4259/?case=d2'), raw['url']
    cases[report['case']].append(report['checks'])
    records.append(report)
required = {'d2progress', 'd2retry', 'd2quota', 'd2indexreload',
            'd2quotareload', 'd2lock', 'd2denied', 'd2corrupt', 'd2migration'}
assert set(cases) == required
assert len(cases['d2progress']) >= 2
for case in ['d2indexreload', 'd2quotareload', 'd2lock']:
    assert len(cases[case]) >= 3, f'{case} needs real reloads/two tabs'

builds = {}
for name in ['web', 'res1d2', 'res1d2r1', 'res1d2-web', 'res1d2-web-live']:
    path = ROOT / 'build' / name / 'index.pck'
    builds[name] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bytes': path.stat().st_size}
for name, expected in {
    'web': '134334491bd68be37fec0cdc292916c5f93020fae986e7ae3a6ecfec5e216eba',
    'res1d2': 'f7bb896516d3616175faad682788fe03285553b3b5daf33269c1554cd4fa3fc9',
    'res1d2r1': 'e8a549e394fb26e1cf973de9b85786cf94604a2bd2e794727f76ab760d5f1f84',
}.items():
    assert builds[name]['sha256'] == expected, f'prior {name} pack changed'
normal = entries(ROOT / 'build/res1d2-web-live/index.pck')
probe = entries(ROOT / 'build/res1d2-web/index.pck')
assert not any('/verification/' in p or '/tests/' in p or 'dressed_reference' in p for p in normal)
assert any('res1d2_contract.gd' in p for p in probe)
for layer in ['herb_body.png', 'herb_landmark.png']:
    assert any(layer in p for p in normal)
for name in ['res1d2_web_server.py', 'res1d2_web_audit.py']:
    ast.parse((ROOT / 'tools' / name).read_text(encoding='utf-8'))
all_log = (ART / 'res1-d2-web-all-final.log').read_text(encoding='utf-8-sig')
assert 'ALL 53 RUNNERS PASSED WITH EXIT CODE 0' in all_log
summary = {'result': 'PASS', 'reports': len(records),
           'checks': sum(r['checks'] for r in records), 'cases': dict(cases),
           'builds': builds, 'normal_excludes_test_harness': True,
           'note': 'Automated Web normal-rule flow uses simulated seconds; normal mouse full playthrough/FPS/device gates remain pending.'}
(ART / 'res1-d2-web-summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
