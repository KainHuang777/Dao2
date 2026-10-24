"""Read-only preservation investigation; writes evidence only, never rebases history."""
import base64
import hashlib
import json
from pathlib import Path
import subprocess
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p1-story'
def sha(data):
    return hashlib.sha256(data).hexdigest()
def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))
def differences(a, b, prefix=''):
    if type(a) is not type(b):
        return [prefix]
    if isinstance(a, dict):
        return [p for key in sorted(a.keys() | b.keys()) for p in
                ([prefix+'/'+key] if key not in a or key not in b else differences(a[key], b[key], prefix+'/'+key))]
    if isinstance(a, list):
        return [prefix] if a != b else []
    return [prefix] if a != b else []

baseline = read(OUT/'baseline-hashes.json')
web = ROOT/'build/web'
web_changes = []
for path, old in baseline.items():
    if path.startswith('build/web/'):
        target = ROOT/path
        current = sha(target.read_bytes())
        if current != old:
            web_changes.append({'path': path, 'baseline_sha256': old, 'current_sha256': current,
                'mtime_utc': datetime.fromtimestamp(target.stat().st_mtime, timezone.utc).isoformat()})
compression = read(web/'compression.json')
integrity = []
for entry in compression['files']:
    raw = (web/entry['file']).read_bytes()
    packed = (web/(entry['file']+'.br')).read_bytes()
    result = subprocess.run(['node', '-e', "const fs=require('fs'),z=require('zlib');process.exit(z.brotliDecompressSync(fs.readFileSync(process.argv[1]+'.br')).equals(fs.readFileSync(process.argv[1]))?0:1)", str(web/entry['file'])], check=False)
    integrity.append({'file': entry['file'], 'raw_hash_ok': sha(raw) == entry['sha256'],
        'compressed_hash_ok': sha(packed) == entry['br_sha256'], 'roundtrip_ok': result.returncode == 0})
for entry in compression['audioFiles']:
    integrity.append({'file': entry['file'], 'raw_hash_ok': sha((web/entry['file']).read_bytes()) == entry['sha256']})
matches = []
frozen = web/'index.pck'
for candidate in sorted((ROOT/'build').glob('*/index.pck')):
    if candidate.parent == web or candidate.stat().st_size != frozen.stat().st_size:
        continue
    if sha(candidate.read_bytes()) == sha(frozen.read_bytes()):
        matches.append(candidate.relative_to(ROOT).as_posix())
path = 'src/verification/content_p1_skills_fixture.json'
prior = base64.b64decode(read(ROOT/'build/story-fixture-backup.json')[path])
current = (ROOT/path).read_bytes()
committed = subprocess.check_output(['git','show','700d11e:'+path], cwd=ROOT)
old_json, new_json = json.loads(prior), json.loads(current)
restoration = next(x for x in read(OUT/'fixture-restoration.json')['files'] if x['path'] == path)
fixture = {'path': path, 'backup_sha256': sha(prior), 'backup_matches_original_record': sha(prior) == restoration['restored_sha256'],
    'current_sha256': sha(current), 'equals_commit_700d11e': current == committed,
    'changed_json_paths': differences(old_json, new_json),
    'old_rules_version': old_json.get('rules_version'), 'new_rules_version': new_json.get('rules_version'),
    'old_content_version': old_json.get('content_version'), 'new_content_version': new_json.get('content_version')}
historical = read(OUT/'delivery-audit-before-art-acceptance.json')
checks = {'four_web_differences_reproduced': len(web_changes) == 4,
    'all_frozen_compression_checks_pass': all(all(v for k,v in row.items() if k.endswith('_ok')) for row in integrity),
    'original_fixture_backup_verified': fixture['backup_matches_original_record'],
    'current_fixture_is_committed': fixture['equals_commit_700d11e'],
    'historical_two_failures_retained': len(historical['failures']) == 2}
report = {'task': 'CONTENT-P1-STORY', 'scope': 'L1 static preservation review; no engine/browser/export rerun',
    'web_changes': web_changes, 'frozen_integrity': integrity, 'identical_candidate_pcks': matches,
    'fixture': fixture, 'checks': checks,
    'failures': [k for k,v in checks.items() if not v],
    'preservation_verdict': 'HISTORICAL_BASELINE_VIOLATION_REPRODUCED_NOT_REBASED',
    'attribution': 'Current bytes and committed fixture are verified. Filesystem timestamps and equal hashes do not identify the actor or command. No complete attribution is available.',
    'policy': 'Preserve current files and original baselines. Historical delivery audit stays failed; no reset, restore, export or inferred user waiver.'}
(OUT/'baseline-review.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'checks': checks, 'failures': report['failures'], 'identical_candidate_pcks': matches,
    'fixture_changed_paths': fixture['changed_json_paths']}, ensure_ascii=False))
raise SystemExit(bool(report['failures']))
