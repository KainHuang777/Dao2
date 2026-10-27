"""L1 static design checks, source preservation, mutually exclusive pool arithmetic.
No game commands or player saves are executed. Capture baseline once, before audits.
"""
import argparse
from collections import Counter
from fractions import Fraction
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p2-story-design'

def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))

def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def protected():
    paths = [p for d in ['src','content','tests','assets','build/web'] for p in (ROOT/d).rglob('*') if p.is_file()]
    paths += [ROOT/'project.godot', ROOT/'export_presets.cfg']
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture-baseline',action='store_true')
    args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    baseline=OUT/'protected-baseline.json'
    now=protected()
    if args.capture_baseline:
        if baseline.exists(): parser.error('Refusing to overwrite existing evidence')
        write(baseline,now)
    if not baseline.exists(): parser.error('Capture baseline first')
    p=read('docs/design-data/content-p2-story-proposal.json')
    failures=[]
    checks=[]
    def check(ok,label):
        checks.append(label)
        if not ok: failures.append(label)
    old=json.loads(baseline.read_text(encoding='utf-8'))
    changed=[k for k in old.keys()|now.keys() if old.get(k)!=now.get(k)]
    check(not changed,'Protected runtime/content/assets/tests/Web inventory unchanged')
    check(p['approval']=='PENDING' and not p['runtime_attached'],'Design only; no implied approval')
    ach=p['achievements']; events=p['encounters']
    legacy=read('content/encounters/encounters.json')
    supply=read('content/supply/era4_6.json')
    skills=read('content/skills/era4_6.json')
    text='\n'.join((ROOT/f'src/simulation/{s}_system.gd').read_text(encoding='utf-8') for s in ['alchemy','beast','sect','talent','achievement'])
    achievement_source=(ROOT/'src/simulation/achievement_system.gd').read_text(encoding='utf-8')
    baseline_ids=re.findall(r'^\t"([a-z0-9_]+)": \{',achievement_source,re.M)
    check(len(baseline_ids)==30 and len(legacy)==38,'Source baseline 30 achievements / 38 encounters')
    check(len(ach)==18 and len(events)==18,'18+18 candidates')
    check(Counter(a['category'] for a in ach)==dict.fromkeys(['cultivation','abode','alchemy','sect','beast_fate','reincarnation'],3),'Six achievement categories, three each')
    check(Counter(e['group'] for e in events)==dict.fromkeys(['resources','industry','sect','alchemy','beast','reincarnation'],3),'Six encounter groups, three each')
    ids=[x['id'] for x in ach+events]
    check(len(set(ids))==36 and not set(ids)&(set(baseline_ids)|{x['id'] for x in legacy}),'Unique new IDs; no baseline collision')
    refs={s['id'] for s in skills}|set(supply['routes'])|set(re.findall(r'"([a-z0-9_]+)"',text))
    for a in ach:
        check(a['era'] in [4,5,6] and a['lifetime_once'],a['id']+' lifetime/era')
        check(all(r in refs for r in a['refs']),a['id']+' authoritative references')
        check(set(a['rewards']) <= {'resources','sect_contribution'},a['id']+' no meta currency')
        for r,v in a['rewards'].get('resources',{}).items():
            check(r in ['lingli','wood','stone_low','spirit_grass_low'] and type(v) is int and 0<v<=1000,a['id']+' bounded basic reward '+r)
        for r in a['refs']:
            skill=next((s for s in skills if s['id']==r),None)
            check(skill is None or skill['era']<=a['era'],a['id']+' skill era '+r)
    masks=p['facts']['masks']
    for name,order in [('refined_mask','p2_pill_order'),('consumed_mask','p2_pill_order'),('arrival_mask','arrival_order'),('task_mask','task_order'),('market_mask','market_order'),('mature_mask','mature_order')]:
        values=p['facts'][order]
        check(masks[name]==(1<<len(values))-1 and len(values)==len(set(values)),name+' fixed mask bounds')
        check(all(v in refs for v in values),name+' source IDs')
    whitelist={'deep_open','ancient_open','void_open','deep_arrived','ancient_arrived','void_arrived','joined_sect','p2_task_claimed','p2_refined','p2_consumed','active_stag','active_crane','active_phoenix','second_life','any_p2_talent'}
    resource_era={r:d['era'] for r,d in supply['resources'].items()}
    allowed={'lingli','money','wood','stone_low','stone_mid','spirit_grass_low','spirit_grass_100y'}|set(resource_era)
    resource_island={r:island for island,data in supply['islands'].items() for r in data['rates']}
    edges=[]
    for e in events:
        check(e['min_era'] in [4,5,6] and e['weight']==60,e['id']+' era/weight')
        check(set(e['requires'])<=whitelist and len(set(e['requires']))==len(e['requires']),e['id']+' finite qualifications')
        check(not any(e[k] for k in ['realm_bias','weather_bias','shichen_bias']),e['id']+' no biases')
        check(len(e['options'])==3 and e['options'][2]['costs']=={} and set(e['options'][2]['rewards'])=={'log_text'},e['id']+' free departure')
        for i,o in enumerate(e['options']):
            label=e['id']+f' option {i}'
            check(bool(o['text']) and bool(o['rewards']['log_text']),label+' full copy')
            check(set(o['rewards'])<={'resources','training_seconds','log_text'},label+' no hidden rewards or pills')
            for r,v in (o['costs']|o['rewards'].get('resources',{})).items():
                check(r in allowed and type(v) is int and 0<v<=1000000,label+' registered positive amount '+r)
                check(resource_era.get(r,1)<=e['min_era'],label+' resource era '+r)
                check(r not in resource_island or resource_island[r]+'_open' in e['requires'],label+' source island '+r)
            t=o['rewards'].get('training_seconds',0)
            check(type(t) is int and 0<=t<=180,label+' bounded training')
            check(len(json.dumps(e,ensure_ascii=False).encode())+2500<12288,label+' pending size allowance')
            if len(o['costs'])==1 and len(o['rewards'].get('resources',{}))==1:
                (c,n),=o['costs'].items(); (r,m),=o['rewards']['resources'].items()
                edges.append((c,r,Fraction(m,n),label))
    # Conservative union of mutually exclusive events: every simple single-resource
    # conversion cycle must lose or preserve quantity. Multi-input paths need separate review.
    cycles=[]
    for start in sorted({x[0] for x in edges}):
        def visit(node,seen,mult,path):
            for a,b,ratio,label in edges:
                if a!=node: continue
                if b==start:
                    cycles.append({'path':path+[label],'multiplier':str(mult*ratio)})
                    check(mult*ratio<=1,'No profitable resource cycle: '+' -> '.join(path+[label]))
                elif b not in seen:
                    visit(b,seen|{b},mult*ratio,path+[label])
        visit(start,{start},Fraction(1),[])
    scenarios=[]
    for era,life in [(4,1),(5,1),(6,1),(6,2)]:
        beasts=['none','jade_fox','iron_turtle','frost_stag']+(['herb_crane'] if era>=5 else [])+(['fire_phoenix'] if era>=6 else [])
        for beast in beasts:
            q=dict.fromkeys(whitelist,True)
            q.update(deep_open=True,ancient_open=era>=5,void_open=era>=6,
                ancient_arrived=era>=5,void_arrived=era>=6,second_life=life>=2,any_p2_talent=life>=2,
                active_stag=beast=='frost_stag',active_crane=beast=='herb_crane',active_phoenix=beast=='fire_phoenix')
            p1q={'active_fox':beast=='jade_fox','mature_active_fox':beast=='jade_fox','second_life':life>=2}
            base=[e for e in legacy if e.get('min_era',1)<=era and (not e['id'].startswith('enc_p1_') or all(p1q.get(k,True) for k in e['requires']))]
            new=[e for e in events if e['min_era']<=era and all(q[k] for k in e['requires'])]
            weight=sum(e.get('weight',100)*(3 if e.get('realm_bias')=='realm_human' else 1) for e in base)
            total=weight+len(new)*60
            prob=60/total
            scenarios.append(dict(era=era,life=life,active_beast=beast,baseline_count=len(base),baseline_weight=weight,new_count=len(new),new_ids=[e['id'] for e in new],new_share=len(new)*prob,specific_probability=prob,mean_opportunities=1/prob,mean_hours=1/prob/era))
            check(sum(q[k] for k in ['active_stag','active_crane','active_phoenix'])<=1,'Pool active beast exclusivity '+str((era,life,beast)))
    check(len(p['art_assets'])==20,'18 badges + 2 vignettes planned')
    for art in p['art_assets']:
        check(len(art['prompt'])>150 and art['acceptance']=='PENDING' and art['source'].endswith('not generated'),art['id']+' prompt/provenance pending')
    totals=Counter()
    for a in ach:
        totals.update(a['rewards'].get('resources',{}))
        totals['sect_contribution']+=a['rewards'].get('sect_contribution',0)
    doc=(ROOT/'docs/40-content-p2-story-design.md').read_text(encoding='utf-8')
    for x in ach+events: check(x['id'] in doc,x['id']+' reviewable in design document')
    report=dict(level='L1 static',checks=len(checks),failures=failures,protected_files=len(now),changed=changed,
        proposal_sha256=hashlib.sha256((ROOT/'docs/design-data/content-p2-story-proposal.json').read_bytes()).hexdigest(),
        achievement_totals=dict(totals),pool_scenarios=scenarios,single_resource_cycles=cycles,
        boundaries=['No runtime simulation','No natural encounters observed','No browser or Web export','Single-resource cycle check is not a general multi-input economy proof'])
    write(OUT/'audit.json',report)
    print(json.dumps({k:report[k] for k in ['level','checks','failures','protected_files','achievement_totals']},ensure_ascii=False))
    raise SystemExit(1 if failures else 0)

if __name__=='__main__': main()
