"""Static W/runtime parity and bounded SECT-1 evidence, no gameplay simulation."""
import ast, hashlib, json, re, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification/artifacts/content-p2-sect'
def read(p): return (ROOT/p).read_text(encoding='utf-8-sig')
def constant(s,name):
    match=re.search(r'const '+name+r' := ([\s\S]*?)(?=\nconst |\nstatic func )',s)
    assert match,name
    return ast.literal_eval(match[1].strip())
checks=0
def check(ok,label):
    global checks
    checks+=1
    assert ok,label
proposal=json.loads(read('docs/design-data/content-p2-sect-proposal.json'))
source=read('src/simulation/sect_system.gd')
old=subprocess.check_output(['git','show','HEAD:src/simulation/sect_system.gd'],cwd=ROOT).decode('utf-8-sig')
for name in ['RARITY_CONFIGS','TASK_TEMPLATES','P1_TASKS','HERB_DISCOUNT_PILLS','P1_TECHNIQUES']:
    check(constant(source,name)==constant(old,name),'legacy unchanged '+name)
for name in ['TECHNIQUES','MARKET_ITEMS']:
    final=constant(source,name)
    previous=constant(old,name)
    for key,val in previous.items(): check(final[key]==val,'legacy definition unchanged '+key)
    check(list(final)[:len(previous)]==list(previous),'old presentation order retained '+name)
tech=constant(source,'TECHNIQUES'); market=constant(source,'MARKET_ITEMS'); tasks=constant(source,'P2_TASKS')
check((len(tech),sum(map(len,constant(source,'TASK_TEMPLATES').values()))+len(constant(source,'P1_TASKS'))+len(tasks),len(market))==(8,30,8),'runtime counts')
for t in proposal['techniques']:
    d=tech[t['id']]
    for key in ['name','min_era','max_level']: check(d[key]==t[key],t['id']+key)
    for key,val in t['base_costs'].items(): check(d['base_contrib' if key=='contribution' else 'base_'+key]==val,t['id']+key)
    check(d['cost_scale']==float(t['cost_scale']),'cost scale')
for t in proposal['task_templates']: check(tasks[t['template_id']]==t,'exact template '+t['template_id'])
for item in proposal['market_items']:
    for key,val in item.items():
        if key not in ['id','group']: check(market[item['id']][key]==val,item['id']+key)
check(constant(source,'P2_PILL_IDS')==proposal['techniques'][0]['pill_ids'],'exact eight pill allowlist')
check(constant(source,'VERSION')==2,'sect2')
check('const SCHEMA_VERSION := 5' in read('src/persistence/save_codec.gd'),'schema5')
check('core-flow-22-content-p2-sect' in read('src/persistence/save_codec.gd'),'rules22')
for name,count in [('core',4189),('save',957)]:
    result=json.loads((OUT/(name+'.json')).read_text(encoding='utf-8'))
    check(result['checks']==count and result['failures']==[],name+' passed')
# The accepted art and normal Web package from the preceding design checkpoint.
baseline=json.loads(read('docs/verification/artifacts/content-p2-sect-design/session-start.json'))['protected']
protected={p:h for p,h in baseline.items() if p.startswith('assets/') or p=='build/web/index.pck'}
for p,h in protected.items(): check(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h,'unchanged art/Web '+p)
result={'date':'2026-10-25','level':'STATIC_DELIVERY','checks':checks,'failures':[],
        'runtime':[8,30,8],'legacy_definitions_unchanged':True,'art_and_normal_web_unchanged':len(protected),
        'art':'NOT_GENERATED_NOT_ACCEPTED','earned_flow':'SECT-2_PENDING','L3':False}
(OUT/'delivery.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
