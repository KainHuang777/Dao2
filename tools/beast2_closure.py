"""Preserve pre-existing test evidence for the authorized BEAST L3 closure."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'docs/verification/artifacts/content-p2-beasts-closure'
MANIFESTS=['assets/ui/beasts-painted/beast2-manifest.json','docs/verification/artifacts/content-p2-beasts-ui/art-manifest.json']
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return p.read_text(encoding='utf-8-sig')
def save(n,v): (D/n).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def backup():
 D.mkdir(parents=True,exist_ok=True)
 assert not (D/'before.json').exists(), 'Never overwrite baseline'
 files=list((ROOT/'docs/verification/artifacts').rglob('*.json'))+list((ROOT/'src/verification').glob('*.json'))
 files=[p for p in files if D not in p.parents and not any(x in p.parts for x in ['before-flat','generated-flat','logs','runs','prior-test-output'])]
 hashes={}
 for p in files:
  n=p.relative_to(ROOT).as_posix();t=D/'before-flat'/sha(p);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,t);hashes[n]=sha(p)
 save('before.json',hashes)
 assert all(sha(D/'before-flat'/h)==h for h in hashes.values())
 (D/'git-start.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=ROOT))
 for n in MANIFESTS:
  p=ROOT/n;obj=json.loads(read(p));save(p.name+'-before-acceptance.json',obj)
  obj.update(acceptance='ACCEPTED',acceptance_date='2026-10-26',user_quote='接受，再接整批 L3 收尾');p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 p=ROOT/'docs/design-data/content-p2-beasts-proposal.json';obj=json.loads(read(p));save('proposal-before-acceptance.json',obj)
 obj['acceptance_record']=dict(date='2026-10-26',quote='接受，再接整批 L3 收尾',art='ACCEPTED',cards='ACCEPTED',pacing='ACCEPTED')
 obj['approval']['art_acceptance']=True
 obj['status']='ACCEPTED_L3_IN_PROGRESS';p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print('BACKUP VERIFIED',len(hashes))
def restore():
 hashes=json.loads(read(D/'before.json'));changed=[]
 for n,h in hashes.items():
  if n in MANIFESTS:continue
  p=ROOT/n;b=D/'before-flat'/h;assert sha(b)==h
  if not p.exists() or sha(p)!=h:
   if p.exists():
    t=D/'generated-flat'/sha(p);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,t)
   shutil.copyfile(b,p);changed.append(n)
  assert sha(p)==h,n
 save('restored.json',dict(checked=len(hashes)-1,changed_archived_restored=changed,intentional_acceptance_metadata=MANIFESTS))
 print('RESTORED',len(changed))
def sources():
 files=[p for f in ['src','content','assets','scenes'] for p in (ROOT/f).rglob('*') if p.is_file() and 'src/verification/' not in p.relative_to(ROOT).as_posix()]
 save('candidate-source-hashes.json',{p.relative_to(ROOT).as_posix():sha(p) for p in files});print('SOURCES',len(files))
if __name__=='__main__':globals()[sys.argv[1]]()
