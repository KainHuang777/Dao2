"""Preserve mutable test evidence and audit the SECT batch closure."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys, re
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'docs/verification/artifacts/content-p2-sect-closure'
MANIFESTS=['assets/ui/sects-painted/sect2-manifest.json','docs/verification/artifacts/content-p2-sect-ui/art-manifest.json']
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return p.read_text(encoding='utf-8-sig')
def save(n,v): (D/n).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def backup():
 D.mkdir(parents=True,exist_ok=True)
 assert not (D/'before.json').exists(), 'Never replace baseline'
 files=list((ROOT/'docs/verification/artifacts').rglob('*.json'))+list((ROOT/'src/verification').glob('*.json'))
 # Prior closure archives are immutable evidence, not test output targets.
 files=[p for p in files if D not in p.parents and not any(x in p.parts for x in ['before-flat','generated-flat','logs','runs'])]
 hashes={}
 for p in files:
  n=p.relative_to(ROOT).as_posix(); t=D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json');t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,t);hashes[n]=sha(p)
 save('before.json',hashes)
 assert all(sha(D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json'))==h for n,h in hashes.items())
 (D/'git-start.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=ROOT))
 for n in MANIFESTS:
  p=ROOT/n;obj=json.loads(read(p));save(p.name+'-before-acceptance.json',obj)
  obj.update(acceptance='ACCEPTED',acceptance_date='2026-10-25',user_quote='接受現版兩圖、卡片與目前節奏');p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 p=ROOT/'docs/design-data/content-p2-sect-proposal.json';obj=json.loads(read(p));save('proposal-before-acceptance.json',obj)
 obj['acceptance_record']=dict(date='2026-10-25',quote='接受現版兩圖、卡片與目前節奏',art='ACCEPTED',cards='ACCEPTED',pacing='ACCEPTED')
 obj['status']='ACCEPTED_L3_IN_PROGRESS';p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 save('closure-decision.json',dict(date='2026-10-25',user_quote='接受現版兩圖、卡片與目前節奏',batch='IN_PROGRESS'))
 print('BACKUP VERIFIED',len(hashes))
def restore():
 hashes=json.loads(read(D/'before.json'));changed=[]
 for n,h in hashes.items():
  if n in MANIFESTS:continue
  p=ROOT/n;b=D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json');assert sha(b)==h
  t=D/'generated-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json')
  if not p.exists() or sha(p)!=h:
   if p.exists():t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,t)
   shutil.copyfile(b,p)
  if t.exists():changed.append(n)
  assert sha(p)==h,n
 save('restored.json',dict(checked=len(hashes)-1,changed_archived_restored=changed,intentional_acceptance_metadata=MANIFESTS))
 print('RESTORED',len(changed))
def logs():
 for p in D.glob('*command.log'):
  for m in re.finditer(r'\[LOGS\] ([^\r\n]+)',read(p)):
   s=Path(m[1].strip())
   if s.exists():shutil.copytree(s,D/'logs'/s.name,dirs_exist_ok=True)
 print('LOGS ARCHIVED')
def sources():
 files=[p for f in ['src','content','assets','scenes'] for p in (ROOT/f).rglob('*') if p.is_file() and 'src/verification/' not in p.relative_to(ROOT).as_posix()]
 save('candidate-source-hashes.json',{p.relative_to(ROOT).as_posix():sha(p) for p in files});print('SOURCES',len(files))
def audit():
 checks=[];failures=[]
 def check(ok,label):
  checks.append(label)
  if not ok:failures.append(label)
 full=read(D/'full-command.log');supplement=read(D/'final-supplement-command.log')
 runners=[x.strip() for x in read(D/'full-list.log').splitlines() if x.strip().endswith('.gd')]
 check(len(runners)==len(set(runners))==129,'129 unique registry runners')
 check(read(D/'full-exit.txt').strip()=='1','original Full exit1 retained')
 check(read(D/'final-supplement-exit.txt').strip()=='1','five-runner supplement original exit1 retained')
 check(read(D/'supply-complete-exit.txt').strip()=='0','single supply completion exit0')
 check('[MODE] matrix=full runners=129 parallel=3' in full,'Full matrix attempted')
 supplement_ids=re.findall(r'^\[START:initial\] (\S+)',supplement,re.M)
 for runner in runners:
  cmd=read(D/'supply-recovered-command.log') if runner=='tests/content_p2_supply_progression_runner.gd' else (supplement if runner in supplement_ids else full)
  attempt='serial-retry' if '[PASS:serial-retry] '+runner in cmd else 'initial'
  check('[PASS:'+attempt+'] '+runner in cmd,'PASS '+runner)
  match=re.search(r'\[LOGS\] ([^\r\n]+)',cmd)
  folder=D/'logs'/Path(match[1].strip()).name
  p=folder/(runner.replace('/','_')+'.'+attempt+'.log');e=Path(str(p)+'.err')
  check(p.exists() and e.exists(),'raw logs '+runner)
  if p.exists() and e.exists():check('SCRIPT ERROR:' not in read(p)+read(e),'no SCRIPT ERROR '+runner)
 for step in ['export','compression','rebase','presentation-parity','font-check','title-final']:check(read(D/(step+'-exit.txt')).strip()=='0',step+' exit0')
 check('state_equal=true' in read(D/'rebase.log'),'earned state unchanged on reseal')
 package=json.loads(read(ROOT/'build/web-content-p2-sect/compression.json'))
 for row in package['files']:
  check(sha(ROOT/'build/web-content-p2-sect'/row['file'])==row['sha256'],'candidate '+row['file'])
  check(sha(ROOT/'build/web-content-p2-sect'/(row['file']+'.br'))==row['br_sha256'],'Brotli '+row['file'])
 check(len(package['audioFiles'])==4,'four BGM companions')
 for row in package['audioFiles']:check(sha(ROOT/'build/web-content-p2-sect'/row['file'])==row['sha256'],'audio '+row['file'])
 for n,h in json.loads(read(D/'candidate-source-hashes.json')).items():check(sha(ROOT/n)==h,'source '+n)
 for n in MANIFESTS:
  manifest=json.loads(read(ROOT/n));check(manifest['acceptance']=='ACCEPTED','art acceptance '+n)
  for row in manifest['assets']:
   check(sha(ROOT/row['runtime'])==sha(ROOT/row['original'])==row['sha256'],'immutable PNG '+row['id'])
 before=json.loads(read(D/'before.json'))
 check(all(sha(ROOT/n)==h for n,h in before.items() if n not in MANIFESTS),'starting mutable evidence restored')
 obs=json.loads(read(D/'browser-observations.json'));by={x['label']:x for x in obs}
 final_browser=D/'browser-final-18px.json'
 check(final_browser.exists() and json.loads(read(final_browser)).get('status')=='PASS','final 18px candidate desktop browser verification')
 check(read(D/'supply-recovered-exit.txt').strip()=='0','persistent-log supply supplement exit0')
 flow=json.loads(read(D/'isolated-supply-recovered/supply3-flow/earned-flow.json'))
 check(flow['checks']==94 and flow['failures']==[],'persistent-log supply 94 checks')
 if final_browser.exists():
  proof=json.loads(read(final_browser))
  for n,h in proof['screenshots'].items():check(sha(D/n)==h,'final18 screenshot '+n)
  check(proof['pck_sha256']==sha(ROOT/'build/web-content-p2-sect/index.pck'),'final18 candidate PCK provenance')
  check(proof['observations_sha256']==sha(D/'browser-final18-observations.json'),'final18 observations provenance')
  for n in ['final18-web-1280-cards.jpg','final18-web-844-plateau.jpg','final18-web-800-plateau.jpg','final18-web-800-qi.jpg']:
   check(n in proof['screenshots'],'final18 reviewed layout '+n)
 for label in ['final-web-1280-cards','final-web-844-plateau','final-web-800-plateau','final-web-800-qi']:
  check(label in by and (D/(label+'.png')).exists(),'same final candidate layout evidence '+label)
 for label,value in [('web-1280-cards','615'),('web-1280-first-learned','495'),('web-1280-refused','495'),('web-1280-retry-refused','495'),('web-1280-recovered','345'),('web-1280-reloaded-cards','345')]:
  check(by[label]['summary']['sect']['contribution']==value,'pre-compact normal candidate transaction '+label)
 for label in ['web-1280-recovered','web-1280-reloaded-cards','final-web-1280-cards']:
  check(by[label]['summary']['sect']['techniques']=={'p2_pill_qi_conservation':1,'sacred_beast_feed_conservation':1},'no duplicate ranks '+label)
 check(json.loads(read(ROOT/'docs/verification/artifacts/content-p2-sect-ui/browser-acceptance.json'))['status']=='PASS_BOUNDED_DESKTOP_WEB','dated L2 two-market fault evidence retained')
 save('delivery-audit.json',dict(checks=len(checks),failures=failures,labels=checks))
 print('AUDIT',len(checks),'FAILURES',failures);assert not failures
def finalize():
 from sect2_finalize import finalize as publish
 publish()
if __name__=='__main__':globals()[sys.argv[1]]()
