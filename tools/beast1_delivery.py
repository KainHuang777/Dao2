"""Archive/restore prior runner output and audit the bounded BEAST-1 delivery."""
from pathlib import Path
import ast,hashlib,json,re,shutil,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification/artifacts/content-p2-beasts'
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(name,obj): (OUT/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def read(p): return (ROOT/p).read_text(encoding='utf-8-sig')
def constant(source,name):
    match=re.search(r'const '+name+r' := (\{.*?\n\})',source,re.S)
    return ast.literal_eval(match[1])
if sys.argv[1]=='restore':
    baseline=json.loads((OUT/'baseline-index.json').read_text(encoding='utf-8'))
    restored=[]
    for rel,h in baseline.items():
        p=ROOT/rel
        if p.exists() and digest(p)==h: continue
        old=OUT/'baseline'/hashlib.sha256(rel.encode()).hexdigest()
        assert digest(old)==h
        if p.exists():
            archived=OUT/'generated'/digest(p)
            archived.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(p,archived)
        shutil.copyfile(old,p)
        restored.append(rel)
    assert all(digest(ROOT/rel)==h for rel,h in baseline.items())
    save('restore.json',{'checked':len(baseline),'archived_then_restored':restored})
    print('Verified prior JSON',len(baseline),'restored',len(restored))
    sys.exit(0)

failures=[]; checks=0
def check(ok,label):
    global checks
    checks+=1
    if not ok: failures.append(label)

original=read('docs/verification/artifacts/content-p2-beasts/source-before/src/simulation/beast_system.gd.txt')
current=read('src/simulation/beast_system.gd')
old_beasts=constant(original,'BEAST_CONFIGS'); beasts=constant(current,'BEAST_CONFIGS')
old_talents=constant(original,'BEAST_TALENTS'); talents=constant(current,'BEAST_TALENTS')
check(len(beasts)==6 and len(talents)==24,'6/24 registry')
for key,v in old_beasts.items(): check(beasts.get(key)==v,'legacy beast unchanged '+key)
for key,v in old_talents.items(): check(talents.get(key)==v,'legacy talent unchanged '+key)
check(list(beasts)[:4]==list(old_beasts) and list(talents)[:16]==list(old_talents),'legacy presentation order retained')
check(constant(current,'STAGE_CONFIGS')==constant(original,'STAGE_CONFIGS'),'old growth thresholds unchanged')
for name in ['compute_multipliers','feed_costs']:
    pattern=r'static func '+name+r'\(.*?(?=\nstatic func |\Z)'
    check(re.search(pattern,original,re.S)[0].strip()==re.search(pattern,current,re.S)[0].strip(),'legacy '+name+' unchanged')
proposal=json.loads(read('docs/design-data/content-p2-beasts-proposal.json'))
check(proposal['status']=='APPROVED' and proposal['runtime_attached'],'approved attachment metadata')
check(proposal['approval']['user_instruction']=='採 X，接 BEAST-1','direct human authorization')
for b in proposal['beasts']:
    config=beasts[b['id']]
    for key,value in [('unlock_era',b['era']),('feed_resource',b['feed_home_cost']),('island',b['requires_open_island']),('resources',b['active_effect']['resources']),('passive_base_value',0.2)]: check(config[key]==value,b['id']+key)
    for t in b['talents']:
        for key,value in t.items(): check(talents[t['id']][key]==value,t['id']+key)
    check(b['art']['status']=='NOT_GENERATED' and not b['art']['accepted'],'art is separately pending '+b['id'])

protected=json.loads(read('docs/verification/artifacts/content-p2-beasts-design/protected-baseline.json'))['protected']
allowed={'src/domain/game_state.gd','src/persistence/save_codec.gd','src/persistence/save_manager.gd','src/simulation/beast_system.gd','src/simulation/island_economy.gd','src/simulation/island_progression.gd','src/simulation/reincarnation_rules.gd','src/simulation/time_advancer.gd','src/simulation/command_processor.gd','tests/m3b_spirit_beast_runner.gd','tests/content_p2_supply_economy_runner.gd','tests/content_p2_pills_save_runner.gd','tests/content_p2_sect_save_runner.gd','tests/sks_p2_core_runner.gd'}
for rel,h in protected.items():
    if rel in allowed: continue
    check((ROOT/rel).exists() and digest(ROOT/rel)==h,'protected unchanged '+rel)

for file in ['core.json','save.json']:
    result=json.loads((OUT/file).read_text(encoding='utf-8'))
    check(result['checks']>900 and result['failures']==[],'new runner result '+file)
expected=['content_p2_beasts_runner','content_p2_beasts_save_runner','content_p2_sect_runner','content_p2_talents_runner','m3a_reincarnation_runner','m3b_spirit_beast_runner','content_p2_supply_economy_runner','offline_closed_form_parity_runner','m1c_persistence_runner','m1e_import_runner','m4a_session_integration_runner','content_p2_sect_save_runner','content_p2_pills_save_runner','sks_p2_core_runner']
passed={}; all_runs=[]
for path in sorted((OUT/'runs').glob('*/command.log')):
    text=path.read_text(encoding='utf-8-sig'); all_runs.append(str(path.relative_to(ROOT)))
    for name in re.findall(r'\[PASS:initial\] tests/(\w+)\.gd',text): passed[name]=str(path.relative_to(ROOT))
for name in expected: check(name in passed,'segmented scoped pass '+name)
save('runner-summary.json',{'level':'L1/L2 single','unique_runners':len(expected),'latest_pass_evidence':{name:passed.get(name) for name in expected},'all_run_logs_including_failures':all_runs})
restore=json.loads((OUT/'restore.json').read_text(encoding='utf-8'))
check(restore['checked']==26389,'prior JSON restoration completed')
for rel,h in json.loads((OUT/'baseline-index.json').read_text(encoding='utf-8')).items(): check(digest(ROOT/rel)==h,'prior artifact byte equality '+rel)
source_files=sorted(allowed|{'src/persistence/beast_save_contract.gd','tests/content_p2_beasts_runner.gd','tests/content_p2_beasts_save_runner.gd','tools/run_all_runners.ps1','tools/run_beast1_checks.ps1'})
save('source-hashes.json',{p:digest(ROOT/p) for p in source_files})
save('delivery.json',{'checks':checks,'failures':failures,'unique_runners':len(expected),'level':'L1/L2 single; no Web or L3'})
print('BEAST1 DELIVERY',checks,'checks failures=',json.dumps(failures,ensure_ascii=False))
sys.exit(bool(failures))
