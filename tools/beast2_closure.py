"""Preserve pre-existing test evidence for the authorized BEAST L3 closure."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys, re
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'docs/verification/artifacts/content-p2-beasts-closure'
MANIFESTS=['assets/ui/beasts-painted/beast2-manifest.json','docs/verification/artifacts/content-p2-beasts-ui/art-manifest.json']
INTENTIONAL=MANIFESTS+['src/verification/content_p1_sect_fixture.json']
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
 hashes=json.loads(read(D/'before.json'));changed=[];generated={}
 for n,h in hashes.items():
  if n in INTENTIONAL:continue
  p=ROOT/n;b=D/'before-flat'/h;assert sha(b)==h
  if not p.exists() or sha(p)!=h:
   if p.exists():
    t=D/'generated-flat'/sha(p);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,t)
    generated[n]=sha(p)
   shutil.copyfile(b,p);changed.append(n)
  assert sha(p)==h,n
 save('restored.json',dict(checked=len([n for n in hashes if n not in INTENTIONAL]),changed_archived_restored=changed,generated_sha256=generated,intentional_files=INTENTIONAL,fixture_repair='Canonical jade_fox active exp/cooldown; invalid original preserved in before-flat'))
 print('RESTORED',len(changed))
def sources():
 files=[p for f in ['src','content','assets','scenes'] for p in (ROOT/f).rglob('*') if p.is_file() and 'src/verification/' not in p.relative_to(ROOT).as_posix()]
 save('candidate-source-hashes.json',{p.relative_to(ROOT).as_posix():sha(p) for p in files});print('SOURCES',len(files))
def logs():
 for p in D.glob('*command.log'):
  for match in re.finditer(r'\[LOGS\] ([^\r\n]+)',read(p)):
   folder=Path(match[1].strip())
   if folder.exists():shutil.copytree(folder,D/'logs-archive'/folder.name,dirs_exist_ok=True)
 print('RAW LOGS ARCHIVED')
def runners():
 registry=[x.strip() for x in read(D/'full-list.log').splitlines() if x.strip().endswith('.gd')]
 passed={}; attempts=[]
 for command in ['full-command.log','resume-command.log','fixture-repair-command.log','supplement-command.log']:
  p=D/command
  if not p.exists():continue
  raw=read(p);match=re.search(r'\[LOGS\] ([^\r\n]+)',raw)
  if not match:continue
  folder=Path(match[1].strip());archived=D/'logs-archive'/folder.name
  if archived.exists():folder=archived
  for attempt,n in re.findall(r'^\[PASS:(initial|serial-retry)\] (\S+)',raw,re.M):
   log=folder/(n.replace('/','_')+'.'+attempt+'.log');err=Path(str(log)+'.err')
   valid=log.exists() and err.exists() and 'SCRIPT ERROR:' not in read(log)+read(err) and len(re.findall(r'^RUNNER_RESULT status=PASS exit=0$',read(log),re.M))==1
   attempts.append(dict(runner=n,command=command,attempt=attempt,raw_valid=valid))
   if valid:passed[n]=attempts[-1]
 missing=[n for n in registry if n not in passed]
 save('runner-summary.json',dict(registry=len(registry),unique=len(set(registry)),passed=len(passed),missing=missing,evidence=passed,attempts=attempts,original_full_interrupted=(D/'full-interrupted.txt').exists()))
 print('RUNNERS',len(passed),'/',len(registry),'MISSING',missing)
def browser():
 obs=json.loads(read(D/'browser-observations.json'));by={x['label']:x for x in obs}
 for label,id in [('stag-recovered','frost_stag'),('stag-reloaded','frost_stag'),('crane-fed','herb_crane'),('crane-reloaded','herb_crane')]:
  assert by[label]['summary']['beasts']['active']==dict(exp=50,id=id,stage='egg'),label
 for label,size in [('stag-acquired',[1280,720]),('stag-844',[844,390]),('stag-800',[800,360]),('crane-acquired',[1280,720]),('crane-844',[844,390]),('crane-800',[800,360])]:
  assert by[label]['canvas']['backing']==size,label
 save('browser-final.json',dict(status='PASS_BOUNDED_DESKTOP_WEB',date='2026-10-26',pck_sha256=sha(ROOT/'build/web-content-p2-beasts/index.pck'),observations_sha256=sha(D/'browser-observations.json'),screenshots={p.name:sha(p) for p in D.glob('web-*.jpg')},boundaries=['normal candidate, real mouse, two independent dated earned branches','one feed each; stag denial/repeated retry/recovery/reload, both remain XP50','durable shell observation lags and continues ordinary production/cooldown; exact instantaneous debit not inferred from these samples','eight synthetic-soul purchases reuse unchanged dated BEAST-2 L2 evidence','CSS backing minus one pixel recorded; no physical device or FPS claim','prior long-session WebGL limit remains unresolved']))
 print('BROWSER BOUNDED PASS',len(obs),'observations')
def audit():
 runners();checks=[];failures=[]
 def check(ok,label):
  checks.append(label)
  if not ok:failures.append(label)
 report=json.loads(read(D/'runner-summary.json'))
 check(report['registry']==report['unique'] and report['missing']==[],'all registry runners finally pass with raw evidence')
 check((D/'full-interrupted.txt').exists(),'original sandbox interruption retained')
 check(read(D/'resume-exit.txt').strip()=='1','original host resume exit1 retained')
 check(read(D/'supplement-exit.txt').strip()=='0','single supply complete-flow supplement exit0')
 flow=json.loads(read(D/'supplement-isolated-storage/supply3-flow/earned-flow.json'))
 check(flow['checks']==94 and flow['failures']==[],'complete supply94 checks')
 check(flow['source_sha256']==sha(D/'supply-source.json'),'exact supplied earned source archived before restoration')
 for step in ['export','compression','rebase']:check(read(D/(step+'-exit.txt')).strip()=='0',step+' exit0')
 check(read(D/'rebase.log').count('state_equal=true')==2,'both earned snapshots unchanged on envelope reseal')
 package=json.loads(read(ROOT/'build/web-content-p2-beasts/compression.json'))
 for row in package['files']:
  check(sha(ROOT/'build/web-content-p2-beasts'/row['file'])==row['sha256'],'candidate '+row['file'])
  check(sha(ROOT/'build/web-content-p2-beasts'/(row['file']+'.br'))==row['br_sha256'],'Brotli '+row['file'])
 check(len(package['audioFiles'])==4,'four BGM companions')
 for row in package['audioFiles']:check(sha(ROOT/'build/web-content-p2-beasts'/row['file'])==row['sha256'],'audio '+row['file'])
 for n,h in json.loads(read(D/'candidate-source-hashes.json')).items():check(sha(ROOT/n)==h,'source '+n)
 for n in MANIFESTS:
  obj=json.loads(read(ROOT/n));check(obj['acceptance']=='ACCEPTED','accepted '+n)
  for row in obj['assets']:check(sha(ROOT/row['runtime'])==sha(ROOT/row['original'])==row['sha256'],'PNG immutable '+row['id'])
 before=json.loads(read(D/'before.json'));check(all(sha(ROOT/n)==h for n,h in before.items() if n not in INTENTIONAL),'original test evidence restored except explicit acceptance and fixture repair')
 browser=json.loads(read(D/'browser-final.json'))
 check(browser['status']=='PASS_BOUNDED_DESKTOP_WEB','normal candidate desktop mouse verified')
 check(browser['pck_sha256']==sha(ROOT/'build/web-content-p2-beasts/index.pck'),'browser PCK provenance')
 for n,h in browser['screenshots'].items():check(sha(D/n)==h,'screenshot '+n)
 save('delivery-audit.json',dict(checks=len(checks),failures=failures,labels=checks))
 print('AUDIT',len(checks),'FAILURES',failures);assert not failures
def finalize():
 report=json.loads(read(D/'delivery-audit.json'));assert not report['failures']
 rr=json.loads(read(D/'runner-summary.json'));assert rr['missing']==[]
 restored=json.loads(read(D/'restored.json'))
 p=ROOT/'docs/design-data/content-p2-beasts-proposal.json';obj=json.loads(read(p));obj['status']='DONE'
 obj['closure']=dict(date='2026-10-27',level='L3',runners=rr['passed'],browser='bounded desktop three landscapes',audit_checks=report['checks'],limits='No FPS or long-session WebGL stability claim')
 p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 line='2026-10-26 **CONTENT-P2-BEAST DONE（兩圖／卡片／目前節奏已接受；L3／桌面Web有界）**：133／133唯一runner最終分段通過；首輪沙箱寫入失敗中斷、74支主機精選續跑與供給並行600秒逾時／串行重試均保留，非單次全綠。修正短式UI測試的動作捲入、八丹測試隔離路徑、舊宗門fixture現行獸欄位及寫檔前encode檢查；正式規則／兩PNG保持。正常Web候選、Brotli／四BGM、三橫式兩獸結契首餵／返回／重載、鹿拒寫再試恢復已驗。交付稽核'+str(report['checks'])+'項通過，'+str(restored['checked'])+'份既有JSON核對、'+str(len(restored['changed_archived_restored']))+'份差異先封存後復原；接受metadata與宗門fixture修復為明列例外。既有長時WebGL限制保持，未宣稱FPS通過；未玩家進度／commit／push。見[整批驗收]({link})。本階段停止；下一大型任務由New Chat指定，不自動開其他P2／P3。下方為日期化歷史。\n\n'
 line=line.replace('供給並行600秒逾時／串行重試均保留','供給並行及串行600秒逾時／單支1800秒補驗均保留')
 line=line.replace('2026-10-26 **CONTENT-P2-BEAST DONE','2026-10-27 **CONTENT-P2-BEAST DONE')
 for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md','docs/25-system-content-expansion-plan.md','docs/39-content-p2-beast-design.md']:
  p=ROOT/name;link=('docs/' if '/' not in name else '')+'verification/content-p2-beasts-closure.md'
  p.write_text(line.replace('{link}',link)+read(p),encoding='utf-8')
 p=ROOT/'docs/verification/content-p2-beasts-closure.md';body=read(p)
 body=body.replace('**L3 IN_PROGRESS，待全部 runner 最終結果與交付稽核；尚未標 DONE。**','**整批 DONE（L3／桌面 Web 有界）。133／133 唯一 runner 最終分段通過；不是單次全綠。**')
 body=body.replace('2026-10-26。使用者明確','2026-10-26 接受／啟動，2026-10-27 完成。使用者明確',1)
 summary='\n最終交付稽核 **'+str(report['checks'])+' 項、0 failures**；'+str(restored['checked'])+' 份既有 JSON 核對，'+str(len(restored['changed_archived_restored']))+' 份差異先封存後逐 byte 復原。接受 manifest 與現行契約的宗門 fixture 修復為明列例外。完整續跑的 exit 與逐支最終證據見下方連結。\n'
 body=body.replace('\n## 範圍與變更',summary+'\n## 範圍與變更',1);p.write_text(body,encoding='utf-8')
 p=ROOT/'updata.txt'
 checkpoint='2026-10-26 CONTENT-P2-BEAST — DONE / L3 BOUNDED DESKTOP WEB. STOP / NEW CHAT.\nHuman explicitly accepted the two images, cards and current pacing: "接受，再接整批 L3 收尾". Do not reopen X or start another P2/P3. Read docs/verification/content-p2-beasts-closure.md.\n133/133 unique registry runners finally passed with full viewport matrix in segmented evidence. Initial Full sandbox run was interrupted after user:// startup failures;59 valid passes retained,74 outstanding runners resumed on host with -Only/-Matrix full/-Parallel3/600s. Original failures, interruption, P1 sect diagnostic stop and supply parallel timeout remain. Serial retries are retained, not a one-shot-green claim.\nOnly test fixes: Beast UI scroll actual feed/talent controls instead of enclosing a tall card,217 checks; pill earned flow honors DAO_TEST_STORAGE_ROOT,64 checks; P1 sect funded fixture uses canonical active exp/cooldown fields and checks SaveCodec.encode before writing. Canonical repaired src/verification/content_p1_sect_fixture.json is intentionally retained; invalid original preserved in before-flat. Production rules, R46, schema, soul costs and PNG bytes unchanged.\nNormal candidate build/web-content-p2-beasts, Web export/Brotli/four BGM passed. Two independent earned Era4/Era5 branches, real mouse acquire/feed50XP, three desktop backing sizes1280x720/844x390/800x360 with measured CSS1279x719/843x389/799x359, internal scroll/return/reload; stag save-denial/repeated retry/recovery/reload retains XP50. Durable shell samples lag and ordinary production/offline catch-up continues; do not infer frozen precise debit from those snapshots. Eight synthetic-soul purchases reuse unchanged dated BEAST-2 L2 evidence. No blank-new-game,11 earned mature lives,FPS or long-session stability claim; prior WebGL RangeError remains unresolved.\nDelivery audit'+str(report['checks'])+' checks passed;'+str(restored['checked'])+' original mutable JSON files verified,'+str(len(restored['changed_archived_restored']))+' changed outputs archived before byte restoration, except accepted art metadata and the explicitly repaired sect fixture.910 runtime source/asset hashes and immutable PNG/original hashes verified. Raw logs are persistent in closure/logs-archive. No player progress, engine update, commit or push. Browser override reset, temporary tabs and this turn\'s local servers closed.\nNEXT: user chooses a new large task in New Chat; no automatic P2/P3 continuation. Pure metadata does not trigger another L3.\n\n'
 checkpoint=checkpoint.replace('Serial retries are retained, not a one-shot-green claim.','Supply 600s serial retry also timed out after reaching Era6; explicit single1800s complete-flow supplement passed. Serial retries are retained, not a one-shot-green claim.')
 checkpoint=checkpoint.replace('2026-10-26 CONTENT-P2-BEAST — DONE','2026-10-27 CONTENT-P2-BEAST — DONE',1)
 p.write_text(checkpoint+read(p),encoding='utf-8');print('FINALIZED')
if __name__=='__main__':globals()[sys.argv[1]]()
