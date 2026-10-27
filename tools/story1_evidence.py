"""Preserve existing JSON evidence before selected regressions, then seal and restore changes."""
import hashlib, json, shutil, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
base=root/'.tmp/story1-original-flat'
out=root/'docs/verification/artifacts/content-p2-story'
sha=lambda b:hashlib.sha256(b).hexdigest()
if sys.argv[1]=='backup':
    assert not base.exists(), 'Snapshot already exists; do not overwrite'
    manifest={}
    for folder in ['docs/verification','src/verification']:
        for path in (root/folder).rglob('*.json'):
            if path.is_relative_to(out): continue
            rel=path.relative_to(root)
            base.mkdir(parents=True,exist_ok=True)
            dest=base/(sha(str(rel).encode())+'.json')
            data=path.read_bytes(); dest.write_bytes(data); manifest[str(rel)]=sha(data)
    (base/'manifest.json').write_text(json.dumps(manifest),encoding='utf-8')
    print('Preserved',len(manifest),'existing JSON files')
elif sys.argv[1]=='restore':
    manifest=json.loads((base/'manifest.json').read_text(encoding='utf-8'))
    changed=[]
    for rel,digest in manifest.items():
        path=root/rel
        if not path.exists() or sha(path.read_bytes())!=digest:
            if path.exists():
                dest=out/'regression-generated'/rel; dest.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(path,dest)
            shutil.copyfile(base/(sha(rel.encode())+'.json'),path); changed.append(rel)
    assert all(sha((root/rel).read_bytes())==digest for rel,digest in manifest.items())
    out.mkdir(parents=True,exist_ok=True)
    (out/'json-restoration.json').write_text(json.dumps({'checked':len(manifest),'changed_sealed_then_restored':changed,'all_original_hashes_match':True},indent=2),encoding='utf-8')
    print('Verified',len(manifest),'original JSON files; sealed/restored',len(changed))
