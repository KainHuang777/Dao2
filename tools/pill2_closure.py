"""Preserve pre-closure evidence, record human acceptance and archive L3 output."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,re
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'docs/verification/artifacts/content-p2-pills-closure'
ACCEPTED='docs/verification/artifacts/content-p2-pills-ui/art-manifest.json'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def log_text(p):
 raw=p.read_bytes()
 return raw.decode('utf-16') if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else raw.decode('utf-8-sig')
def save(n,v): (D/n).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def backup():
 D.mkdir(parents=True,exist_ok=True)
 assert not (D/'before.json').exists(),'Never replace baseline'
 files=list((ROOT/'docs/verification/artifacts').rglob('*.json'))+list((ROOT/'src/verification').glob('*.json'))
 hashes={}
 for p in files:
  if D in p.parents: continue
  n=p.relative_to(ROOT).as_posix(); t=D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json');t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,t);hashes[n]=sha(p)
 save('before.json',hashes)
 failures=[n for n,h in hashes.items() if sha(D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json'))!=h]
 save('backup-integrity.json',dict(count=len(hashes),failures=failures));assert not failures
 (D/'git-start.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=ROOT))
 for n in ['assets/ui/pills-painted/pill2-manifest.json',ACCEPTED]:
  p=ROOT/n;obj=json.loads(p.read_text(encoding='utf-8-sig'));obj.update(acceptance='ACCEPTED',acceptance_date='2026-10-25',user_quote='接受八圖、卡片與目前節奏');p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 p=ROOT/'docs/design-data/content-p2-pills-proposal.json';obj=json.loads(p.read_text(encoding='utf-8-sig'));save('proposal-before-acceptance.json',obj)
 obj['status']='ACCEPTED_L3_IN_PROGRESS';obj['common']['art_acceptance']='ACCEPTED'
 obj['acceptance_record']=dict(date='2026-10-25',quote='接受八圖、卡片與目前節奏',art='ACCEPTED',cards='ACCEPTED',pacing='ACCEPTED')
 for row in obj['pills']: row['art_status']='GENERATED_INTEGRATED_ACCEPTED'
 obj['implementation']['art']='GENERATED_INTEGRATED_ACCEPTED'
 p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 save('closure-decision.json',dict(date='2026-10-25',user_quote='接受八圖、卡片與目前節奏',batch='IN_PROGRESS'))
 print('BACKUP VERIFIED',len(hashes))
def restore():
 hashes=json.loads((D/'before.json').read_text(encoding='utf-8'))
 changed=[n for n in hashes if (D/'generated-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json')).exists()]
 for n,h in hashes.items():
  if n==ACCEPTED: continue
  p=ROOT/n;backup=D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json');assert sha(backup)==h
  if not p.exists() or sha(p)!=h:
   if p.exists():
    t=D/'generated-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json');t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,t)
   shutil.copyfile(backup,p)
   if n not in changed:changed.append(n)
  assert sha(p)==h,n
 save('restored.json',dict(checked=len(hashes)-1,changed_archived_restored=changed,intentional_acceptance_metadata=ACCEPTED));print('RESTORED',len(changed))
def logs():
 for p in D.glob('*.log'):
  for m in re.finditer(r'\[LOGS\] ([^\r\n]+)',log_text(p)):
   s=Path(m[1].strip())
   if s.exists():shutil.copytree(s,D/'logs'/s.name,dirs_exist_ok=True)
 print('LOGS ARCHIVED')
def sources():
 files=[p for f in ['src','content','assets','scenes'] for p in (ROOT/f).rglob('*') if p.is_file() and 'src/verification/' not in p.relative_to(ROOT).as_posix()]
 save('candidate-source-hashes.json',{p.relative_to(ROOT).as_posix():sha(p) for p in files});print('SOURCES',len(files))
def finalize():
 result=json.loads((D/'delivery-audit.json').read_text(encoding='utf-8'));assert not result['failures']
 summary='2026-10-25 **CONTENT-P2-PILL DONE（八圖／卡片／目前節奏人工接受；L3／桌面Web有界）**：125／125唯一runner最終分段通過（123初跑＋八丹UI串行重試＋技能核心81項補驗）；原Full命令exit1保留，非單次全綠。修正短橫式八丹卡過高，三煉丹UI全尺寸補驗通過（八丹288項）。正常Web候選／Brotli／四BGM與桌面三橫式、藏石拒寫再重試／恢復／重載已驗；844×390容器的canvas實測844×389。410項交付稽核通過，62份測試差異先封存後復原，八圖不變。長時停留WebGL RangeError導致畫面停更已留存，重載後有界流程通過，長時穩定性未通過、不宣稱已修。未改玩家進度、未commit/push。見[整批驗收](LINK)。本階段停止，下一大型工作請New Chat指定，不自動開其他P2／P3。下方為日期化歷史。'
 for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md','docs/25-system-content-expansion-plan.md','docs/37-content-p2-pill-design.md']:
  p=ROOT/name;link='docs/verification/content-p2-pills-closure.md' if '/' not in name else 'verification/content-p2-pills-closure.md'
  p.write_text(summary.replace('LINK',link)+'\n\n'+p.read_text(encoding='utf-8-sig'),encoding='utf-8')
 p=ROOT/'docs/design-data/content-p2-pills-proposal.json';obj=json.loads(p.read_text(encoding='utf-8-sig'))
 obj['status']='DONE_BOUNDED_DESKTOP_L3';obj['implementation'].update({'PILL-2':'DONE','overall':'DONE','verification':'docs/verification/content-p2-pills-closure.md'})
 obj['closure']=dict(date='2026-10-25',report='docs/verification/content-p2-pills-closure.md',level='L3 bounded desktop Web',unique_runners=125,original_full_exit=1,final_selected_supplement='PASS',long_idle_webgl='OBSERVED_UNRESOLVED_OUTSIDE_BOUNDED_FUNCTIONAL_CLOSURE')
 p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 save('closure-decision.json',dict(date='2026-10-25',user_quote='接受八圖、卡片與目前節奏',batch='DONE',scope='L3 / bounded desktop Web',long_idle_webgl='Unresolved observed limitation; no long-run stability pass'))
 p=ROOT/'docs/verification/content-p2-pills-ui.md';p.write_text('2026-10-25 更新：使用者已接受八圖、卡片與目前節奏，整批L3／有界桌面Web收尾完成；短橫式卡另修正過高。見[收尾驗收](content-p2-pills-closure.md)。下方待接受與未L3為當時狀態。\n\n'+p.read_text(encoding='utf-8-sig'),encoding='utf-8')
 p=ROOT/'updata.txt';checkpoint='''2026-10-25 CONTENT-P2-PILL DONE — HUMAN ACCEPTED EIGHT IMAGES, CARDS AND CURRENT PACING; L3 / BOUNDED DESKTOP WEB CLOSED. STOP / NEW CHAT.
Human quote: "接受八圖、卡片與目前節奏". V prices/formulas, R46 times, schema5/pill_version2/core-flow-21 unchanged. Eight PNG originals/runtime/prompts immutable; both manifests and proposal record acceptance. 125/125 unique runners finally pass across the Full attempt and bounded supplements: 123 initial, PILL UI serial retry, SKS core81 isolated supplement. ORIGINAL FULL EXIT1 IS PRESERVED, not a single green Full invocation. PILL UI288/full three-size and P1/legacy alchemy UI final supplements pass. Full raw stdout/stderr, original failures, scripts, audits and hashes are under docs/verification/artifacts/content-p2-pills-closure.
L3 exposed overly tall short-landscape P2 cards. AlchemyPanel now uses a horizontal material/action + effect container only for short P2 cards, reserves enough HFlow width for four-material silver ward, keeps 16px status/44px buttons/full TIP, and does not alter accepted wide art/formulas. Initial HFlow collapse, explicit-bool parse error/180s timeout and failed fixes remain. Old SKS core expected TALENT_RULES_VERSION although new states are pill_version2; corrected two exact identity assertions, remaining81 checks kept. No runtime rule/PNG edits.
Normal Web candidate build/web-content-p2-pills re-exported after UI fix; Brotli roundtrip/four BGM and R46/font checks pass. Actual mouse independent origin48472: targeted1280x720/844x390/800x360; observed CSS1280x720/844x389/800x360, backing1600x900/1055x487/1000x450 at desktop scale1.25. Four-material card fits. Stone-vault refined1, then refusal/denied retry kept disk pill1/count1/total7; recovery/reload pill0/count2/total8, stone_mid29 unchanged, return home passed. Normal clock ran; no exact paused cost delta claim. First page remained open for hours, then WebGL genObject/glGenVertexArrays RangeError at2026-10-25T01:02:57.972Z stalled rendering. Exact error retained; same stored state reload completed bounded functional flow. Long-idle stability is NOT passed/fixed; do not erase this issue or claim zero console errors. Prior L2 MutationObserver remains historical.
10072 initial JSON backups verified before tests. 10071 existing evidence files byte-checked after restoration (one art manifest intentionally accepted);62 generated changes archived then restored. First sandbox restore partially completed then write failed; normal-host retry completed, final archive-derived list includes both parts. First audit required empty LASTEXITCODE from in-process script; preserved failed audit, fixed evidence to actual exec process exit0 + raw PASS marker, final410 checks pass. Earlier sandbox attempt interrupted; temporary raw folder unavailable, captured output summary only. Windows PS5 UTF8-without-BOM regex misdecode interrupted another attempt; PWSh7 complete attempt and all raw logs retained. No environment update, player save, commit/push or FPS claim. Existing dirty work preserved. Review tab closed/viewport reset and owned server Ctrl+C stopped (exit1 is intentional stop).
STOP this completed stage per Context Guard. Next large task must be user-selected in a New Chat. Do not repeat V/art/pacing approval, run another Full for metadata, or automatically start other P2/P3. Keep long-idle WebGL observation visible as unresolved; investigate only under an explicitly scoped later task.

''';p.write_text(checkpoint+p.read_text(encoding='utf-8-sig'),encoding='utf-8')
 print('FINALIZED bounded PILL closure')
def audit():
 failures=[];checks=[]
 def check(ok,n):
  checks.append(n)
  if not ok:failures.append(n)
 def read(p):return p.read_text(encoding='utf-8-sig')
 command=read(D/'full-command.log')
 runners=[n.strip() for n in read(D/'full-list.log').splitlines() if n.strip().endswith('.gd')]
 check(len(runners)==len(set(runners))==125,'125 unique runners')
 check(read(D/'full-exit.txt').strip()=='1','original L3 exit1 preserved')
 check('[MODE] matrix=full runners=125 parallel=3' in command,'complete full matrix attempted')
 supplement=read(D/'core-fix-command.log')
 check(json.loads(read(D/'core-fix-process-result.json'))['exit_code']==0 and 'SELECTED 1 RUNNERS PASSED (matrix=full)' in supplement,'isolated core supplement exit0')
 folder=D/'logs'/Path(re.search(r'\[LOGS\] ([^\r\n]+)',command)[1].strip()).name
 for runner in runners:
  evidence_command=supplement if runner=='tests/sks_p2_core_runner.gd' else command
  evidence_folder=D/'logs'/Path(re.search(r'\[LOGS\] ([^\r\n]+)',evidence_command)[1].strip()).name
  attempt='serial-retry' if '[PASS:serial-retry] '+runner in evidence_command else 'initial'
  check('[PASS:'+attempt+'] '+runner in evidence_command,'PASS '+runner)
  p=evidence_folder/(runner.replace('/','_')+'.'+attempt+'.log');err=Path(str(p)+'.err')
  check(p.exists() and err.exists(),'raw logs '+runner)
  if p.exists() and err.exists():check('SCRIPT ERROR:' not in read(p)+read(err),'no SCRIPT ERROR '+runner)
 for step in ['export','compression','rebase']:check(read(D/(step+'-exit.txt')).strip()=='0',step+' exit0')
 check('state_equal=true' in read(D/'rebase.log'),'earned state unchanged')
 package=json.loads(read(ROOT/'build/web-content-p2-pills/compression.json'))
 for row in package['files']:
  check(sha(ROOT/'build/web-content-p2-pills'/row['file'])==row['sha256'],'package '+row['file'])
  check(sha(ROOT/'build/web-content-p2-pills'/(row['file']+'.br'))==row['br_sha256'],'Brotli '+row['file'])
 check(len(package['audioFiles'])==4,'four BGM companions')
 for row in package['audioFiles']:check(sha(ROOT/'build/web-content-p2-pills'/row['file'])==row['sha256'],'audio '+row['file'])
 check(all(sha(ROOT/n)==h for n,h in json.loads(read(D/'before.json')).items() if n!=ACCEPTED),'starting evidence restored')
 check(all(sha(ROOT/n)==h for n,h in json.loads(read(D/'candidate-source-hashes.json')).items()),'runtime assets match candidate source')
 manifest=json.loads(read(ROOT/'assets/ui/pills-painted/pill2-manifest.json'))
 check(manifest['acceptance']=='ACCEPTED','eight art accepted')
 for row in manifest['assets']:check(sha(ROOT/row['runtime'])==sha(ROOT/row['original'])==row['sha256'],'unchanged art '+row['id'])
 proposal=json.loads(read(ROOT/'docs/design-data/content-p2-pills-proposal.json'));before=json.loads(read(D/'proposal-before-acceptance.json'))
 def rules(rows):return [{k:v for k,v in row.items() if k!='art_status'} for row in rows]
 check(rules(proposal['pills'])==rules(before['pills']) and proposal['save']==before['save'],'V prices effects gates save unchanged')
 web=json.loads(read(D/'browser-observations.json'))
 check(web['sizes']==[[1280,720],[844,390],[800,360]],'desktop three horizontal sizes')
 check(web['consume_recovery_verified'],'mouse consume refusal retry recovery reload')
 check(json.loads(read(D/'ui-final.json'))['failures']==[],'final UI full matrix no failures')
 check('SELECTED 3 RUNNERS PASSED (matrix=full)' in read(D/'ui-fix-final-command.log'),'three affected UI runners pass')
 result=dict(level='L3',checks=len(checks),failures=failures,runners=len(runners),initial_passes=len(re.findall(r'\[PASS:initial\]',command)),serial_retry_passes=re.findall(r'\[PASS:serial-retry\] ([^ ]+)',command),supplemental_passes=['tests/sks_p2_core_runner.gd'],original_full_exit=1,candidate='build/web-content-p2-pills',package=package)
 save('delivery-audit.json',result);print(json.dumps({k:result[k] for k in ['checks','failures','runners','initial_passes','serial_retry_passes']}));return bool(failures)
if __name__=='__main__':sys.exit({'backup':backup,'restore':restore,'logs':logs,'sources':sources,'audit':audit,'finalize':finalize}[sys.argv[1]]())
