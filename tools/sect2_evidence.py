"""Preserve existing test JSON bytes across bounded SECT-1 runners."""
import hashlib, json, shutil, sys, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'docs/verification/artifacts/content-p2-sect'
OUT.mkdir(parents=True,exist_ok=True)
MANIFEST = OUT/'baseline.json'
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
if sys.argv[1]=='capture':
    backup=ROOT/'sect1-baseline.tmp'
    backup.mkdir(parents=True,exist_ok=False)
    files={}
    for folder in ['docs/verification','src/verification']:
        for p in (ROOT/folder).rglob('*.json'):
            if OUT in p.parents: continue
            rel=p.relative_to(ROOT).as_posix()
            h=digest(p)
            shutil.copyfile(p,backup/h); files[rel]=h
    MANIFEST.write_text(json.dumps({'backup':str(backup),'files':files},indent=2),encoding='utf-8')
    print('Captured',len(files),'existing JSON files')
else:
    manifest=json.loads(MANIFEST.read_text(encoding='utf-8')); backup=Path(manifest['backup'])
    changed=[]
    for rel,h in manifest['files'].items():
        p=ROOT/rel
        if not p.exists() or digest(p)!=h:
            assert digest(backup/h)==h
            dest=OUT/'prior-test-output'/digest(p) if p.exists() else OUT/'prior-test-output'/h
            dest.parent.mkdir(parents=True,exist_ok=True)
            if p.exists(): shutil.copyfile(p,dest)
            shutil.copyfile(backup/h,p); changed.append(rel)
    assert all(digest(ROOT/r)==h for r,h in manifest['files'].items())
    (OUT/'restore.json').write_text(json.dumps({'checked':len(manifest['files']),'archived_then_restored':changed},indent=2),encoding='utf-8')
    print('Verified originals',len(manifest['files']),'restored',len(changed))
