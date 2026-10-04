"""Read-only export payload budget. gzip estimate is not a deployed server claim."""
from pathlib import Path
import gzip
import hashlib
import json
import argparse
import struct

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--build', choices=('web', 'island-preview', 'web-persistence'), default='island-preview')
args = parser.parse_args()
records = []
for name in ('index.js', 'index.wasm', 'index.pck'):
    data = (root/'build'/args.build/name).read_bytes()
    records.append({'file': name, 'bytes': len(data), 'gzip_bytes': len(gzip.compress(data, compresslevel=6, mtime=0)), 'sha256': hashlib.sha256(data).hexdigest()})
report = {'build': args.build, 'files': records, 'raw_bytes': sum(r['bytes'] for r in records),
          'gzip_estimate_bytes': sum(r['gzip_bytes'] for r in records),
          'download_budget_bytes': 30000000,
          'note': 'Deterministic gzip level6; HTTP transfer must be verified separately. No build files modified.'}
report['download_budget_pass'] = report['gzip_estimate_bytes'] <= report['download_budget_bytes']
manifest = root/'build'/args.build/'compression.json'
if manifest.exists():
    compressed = json.loads(manifest.read_text(encoding='utf-8'))
    for item, record in zip(compressed['files'], records):
        if item['file'] != record['file'] or item['sha256'] != record['sha256']:
            raise ValueError('Stale Brotli companion; regenerate compression')
        companion = (root/'build'/args.build/(item['file']+'.br')).read_bytes()
        if hashlib.sha256(companion).hexdigest() != item['br_sha256']:
            raise ValueError('Brotli companion hash mismatch')
        record['br_bytes'] = len(companion)
    report['br_bytes'] = sum(r['br_bytes'] for r in records)
    report['br_download_budget_pass'] = report['br_bytes'] <= report['download_budget_bytes']
    report['optional_audio_bytes'] = sum(r['bytes'] for r in compressed.get('audioFiles', []))
    report['br_including_all_audio_bytes'] = report['br_bytes'] + report['optional_audio_bytes']
# Read-only directory inventory, per Godot core/io/file_access_pack.cpp V3/V4.
with (root/'build'/args.build/'index.pck').open('rb') as pack:
    magic, version, major, minor, patch, flags = struct.unpack('<6I', pack.read(24))
    if magic != 0x43504447 or version not in (3, 4) or flags & 1:
        raise ValueError('Expected standalone unencrypted PCK V3/V4')
    base, directory = struct.unpack('<2Q', pack.read(16))
    pack.seek(directory)
    entries = []
    for _ in range(struct.unpack('<I', pack.read(4))[0]):
        length = struct.unpack('<I', pack.read(4))[0]
        path = pack.read(length).rstrip(b'\0').decode('utf-8')
        offset, size = struct.unpack('<2Q', pack.read(16))
        pack.read(20)
        entries.append({'path': path, 'bytes': size})
    report['largest_pack_entries'] = sorted(entries, key=lambda r:r['bytes'], reverse=True)[:25]
print(json.dumps(report, ensure_ascii=False, indent=2))
