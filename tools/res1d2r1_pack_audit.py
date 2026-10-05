"""Inspect isolated D2-R1 PCK directory and immutable prior build hashes."""
import hashlib
import json
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'build/res1d2r1/index.pck'
with path.open('rb') as pack:
    magic, version, major, minor, patch, flags = struct.unpack('<6I', pack.read(24))
    assert magic == 0x43504447 and version in (3, 4) and not flags & 1
    base, directory = struct.unpack('<2Q', pack.read(16))
    pack.seek(directory)
    entries = []
    for _ in range(struct.unpack('<I', pack.read(4))[0]):
        length = struct.unpack('<I', pack.read(4))[0]
        name = pack.read(length).rstrip(b'\0').decode('utf-8')
        offset, size = struct.unpack('<2Q', pack.read(16))
        pack.read(20)
        entries.append({'path': name, 'bytes': size})
paths = [entry['path'] for entry in entries]
assert all(any(f'herb_{layer}.png' in name for name in paths) for layer in ('body', 'landmark'))
assert not any('dressed_reference' in name for name in paths)
records = []
for build in ('res1d2r1', 'res1d2', 'web'):
    candidate = root / 'build' / build / 'index.pck'
    records.append({'build': build, 'bytes': candidate.stat().st_size,
                    'sha256': hashlib.sha256(candidate.read_bytes()).hexdigest()})
assert records[2]['sha256'] == '134334491bd68be37fec0cdc292916c5f93020fae986e7ae3a6ecfec5e216eba', 'AGY frozen build changed'
assert records[1]['sha256'] == 'f7bb896516d3616175faad682788fe03285553b3b5daf33269c1554cd4fa3fc9', 'prior D2 build changed'
report = {'result': 'PASS', 'engine': [major, minor, patch], 'builds': records,
          'danxia_pack_entries': [e for e in entries if 'res1d2' in e['path'] or 'herb_' in e['path']],
          'reference_images_excluded': True,
          'note': 'PCK inventory/hash evidence only; no new FPS/download/cold-boot acceptance'}
(root / 'docs/verification/artifacts/res1-d2-r1-pack.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('PASS: runtime layers present, references excluded, AGY and prior D2 PCK unchanged')
