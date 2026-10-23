"""Restore previously accepted generated fixtures after the fixed regression suite."""
from pathlib import Path
import base64, hashlib, json
ROOT=Path(__file__).resolve().parents[1]
backup=json.loads((ROOT/'build/p1-pill-fixture-backup.json').read_text(encoding='utf-8-sig'))
previous=json.loads((ROOT/'docs/verification/artifacts/content-p1-pills/fixture-restoration.json').read_text(encoding='utf-8-sig'))['restored']
guards=json.loads((ROOT/'docs/verification/artifacts/content-p1-sect-design/session-start.json').read_text(encoding='utf-8-sig'))['protected']
report=[]
for key in previous:
    path=ROOT/Path(key.replace('\\','/'))
    raw=base64.b64decode(backup[key])
    expected=guards.get(path.relative_to(ROOT).as_posix())
    if expected: assert hashlib.sha256(raw).hexdigest()==expected,key
    report.append({'path':path.relative_to(ROOT).as_posix(),'generated_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'restored_sha256':hashlib.sha256(raw).hexdigest(),'source':'accepted PILL restoration source'})
    path.write_bytes(raw)
path=ROOT/'src/verification/content_p1_pills_fixture.json'
raw=(ROOT/'build/sect-prior-pills-fixture.json').read_bytes()
assert hashlib.sha256(raw).hexdigest()==guards[path.relative_to(ROOT).as_posix()]
report.append({'path':path.relative_to(ROOT).as_posix(),'generated_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'restored_sha256':hashlib.sha256(raw).hexdigest(),'source':'previous accepted ContentP1PillsAcceptance PCK, extracted outside loose project root'})
path.write_bytes(raw)
(ROOT/'docs/verification/artifacts/content-p1-sect/fixture-restoration.json').write_text(json.dumps({'restored':report,'count':len(report)},ensure_ascii=False,indent=2),encoding='utf-8')
print('Restored',len(report),'previous generated fixtures; source fixture hashes verified.')
