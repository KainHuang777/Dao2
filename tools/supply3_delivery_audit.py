"""Static SUPPLY-3 delivery audit. Does not run the engine or mutate player data."""
from pathlib import Path
import hashlib,json,re,sys
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'docs/verification/artifacts/content-p2-supply-3'
failures=[]; checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok: failures.append(label)
def text(p):
 raw=p.read_bytes()
 decoded = raw.decode('utf-16') if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else raw.decode('utf-8-sig')
 return re.sub(r'\x1b\[[0-9;]*[A-Za-z]', '', decoded)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
selected={
 'content_p2_supply_progression_runner.gd':'flow-story-tail-final-command.log',
 'content_p2_supply_ui_runner.gd':'labels-final-command.log',
 'res1_ui1a_runner.gd':'ui-final-command.log',
 'res1_ui1b_runner.gd':'ui-final-command.log',
 'life_history_runner.gd':'core-final-command.log',
 'resource_accounts_runner.gd':'core-final-command.log',
 'm1a_core_runner.gd':'dispatch-final-command.log',
 'm3b_alchemy_runner.gd':'core-final-command.log',
 'res1b_economy_runner.gd':'ui-routes-final-command.log',
 'recipe_row_runner.gd':'economy-dependencies-command.log',
 'content_p2_supply_economy_runner.gd':'economy-dependencies-command.log'}
evidence={}
for runner,log in selected.items():
 out=text(D/log); check('[PASS:initial] tests/'+runner in out,'selected PASS '+runner)
 m=re.search(r'\[LOGS\] ([^\r\n]+)',out)
 check(m is not None,'raw log directory '+runner)
 if m:
  folder=Path(m[1].strip()); stdout=folder/('tests_'+runner+'.initial.log'); stderr=Path(str(stdout)+'.err')
  check(stdout.exists() and stderr.exists(),'raw files '+runner)
  if stdout.exists() and stderr.exists():
   check('SCRIPT ERROR:' not in text(stdout)+text(stderr),'no SCRIPT ERROR in selected '+runner)
   evidence[runner]={'command':log,'stdout':str(stdout.relative_to(ROOT)).replace('\\','/'),'stderr':str(stderr.relative_to(ROOT)).replace('\\','/')}
ui=json.loads(text(D/'ui-contract.json'));check(ui['checks']==76 and ui['failures']==[],'final UI76')
prior=json.loads(text(D/'earned-flow-long-before-tail-failure.json'))
check(prior['checks']==92 and prior['failures']==['earned reincarnation','reincarnation closes deep','reincarnation closes ancient','reincarnation closes void'],'preserve exactly four premature tail failures; earlier88 passed')
check([r['to'] for r in prior['trace']]==[4,5,6],'earned three breakthroughs')
check(prior['age']==150253,'no-skill level10 age')
tail=json.loads(text(D/'earned-flow.json'));check(tail['checks']==13 and tail['failures']==[],'final resumed tail13')
source=D/'earned-era6-level10.json';check(tail['source_sha256']==sha(source),'resume source hash')
level10=json.loads(text(source));reborn=json.loads(text(D/'earned-reborn.json'))
check(level10['state']['era_id']==6 and level10['state']['level']==10 and level10['state']['skills']=={},'earned no-skill maximum')
check(reborn['state']['era_id']==1 and reborn['state']['total_elapsed_seconds']==0,'reborn reset')
check(all(not reborn['state']['economy']['islands'][i]['opened'] for i in ['deep','ancient','void']),'seven-island next-life reset')
check('REVIEW_REBASE state_equal=true' in text(D/'reborn-readback.log'),'reborn codec readback')
web=json.loads(text(D/'web-observations.json'));route=web['finalPersistedEra6']['routes']['deep_iron_home']
check(route=={'enabled':True,'level':3,'reserve':'0','target':'3000'},'actual browser reload level3/policy')
check(web['logsEra6']==[] and web['logsOld']==[],'observed browser console window empty')
for name in ['web-era3-deep-final.png','web-bulk160-final.png','web-route-refusal-final.png','web-route-level3-final.png']:
 check((D/name).stat().st_size>10000,'screenshot '+name)
check('[ DONE ] savepack' in text(D/'export-labels-final.log'),'final local export complete')
check(json.loads(text(D/'fonts-delivery-check.log'))['ok'],'final font coverage')
for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md','docs/25-system-content-expansion-plan.md','docs/34-res1-e-46-design.md']:
 check('SUPPLY-3' in text(ROOT/name).splitlines()[0],'latest handoff '+name)
# Report links resolve; no link to an assumed future artifact is accepted.
report=ROOT/'docs/verification/content-p2-supply-3.md'
for link in re.findall(r'\]\(([^)]+)\)',text(report)):
 if not link.startswith(('http:','https:')):check((report.parent/link).exists(),'report link '+link)
sources=[p for directory in ['src','content'] for p in (ROOT/directory).rglob('*') if p.suffix in ['.gd','.gdshader','.json','.tscn','.tres']]
source_hashes={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in sorted(sources)}
pack=ROOT/'build/web-supply3-local/index.pck'
result={'level':'L1 static delivery audit','checks':checks,'failures':failures,'selected_unique_runners':len(selected),'evidence':evidence,'long_flow':{'original_exit':1,'passed_before_tail':88,'original_failed_tail':4,'repaired_resume_checks':13,'note':'Composed evidence, not a clean end-to-end rerun; legacy story/pill/sect0 core path'},'source_hashes':source_hashes,'local_test_pack':{'path':'build/web-supply3-local/index.pck','sha256':sha(pack),'bytes':pack.stat().st_size},'no_L3':True}
(D/'delivery-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'checks':checks,'failures':failures,'selected_unique_runners':len(selected)},ensure_ascii=False))
sys.exit(bool(failures))
