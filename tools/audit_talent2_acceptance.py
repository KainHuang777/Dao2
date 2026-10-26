"""Audit recorded UI observations; never drives UI or edits saves."""
from pathlib import Path
import json
import hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification/artifacts/content-p2-talents-ui'
IDS=['elixir_conservation_memory','frontier_prospector_memory','sacred_beast_nurture_memory']
def main():
    failures=[]
    checks=[]
    def check(ok,label):
        checks.append(label)
        if not ok: failures.append(label)
    data=[json.loads(line) for line in (OUT/'browser-states.jsonl').read_text(encoding='utf-8').splitlines()]
    stable=[d for d in data if d.get('ready') and len(d.get('rows',{}))==9]
    check(bool(stable),'stable observations')
    for d in stable:
        check(d['viewport']==[1280,720],'viewport '+d['case'])
        check(d['talent_version']==3,'version '+d['case'])
        check(all(d['rows'][id]['art'] for id in IDS),'three loaded textures '+d['case'])
    for case,id in zip(['elixir','frontier','beast'],IDS):
        samples=[d for d in stable if d['case']==case]
        check(any(float(d['hearts'])==25 and d['talents'].get(id,0)==0 for d in samples),'earned before '+id)
        check(any(float(d['hearts'])==15 and d['talents'].get(id,0)==1 for d in samples),'earned debit '+id)
    budget=[d for d in stable if d['case']=='budget']
    payments=[]
    for before,after in zip(budget,budget[1:]):
        changed=[id for id in IDS if before['talents'].get(id,0)!=after['talents'].get(id,0)]
        if not changed: continue
        check(len(changed)==1,'one rank per command')
        id=changed[0]
        old=before['talents'].get(id,0)
        new=after['talents'].get(id,0)
        spent=float(before['hearts'])-float(after['hearts'])
        check(new==old+1 and spent==[10,20,40,80,160][old],'exact browser payment '+id+str(new))
        payments.append({'id':id,'level':new,'cost':spent})
    check(len(payments)==15,'all fifteen exact browser payments')
    for id in IDS:
        for level in range(1,6): check(any(d['talents'].get(id,0)==level for d in budget),'browser rank '+id+str(level))
    check(any(float(d['hearts'])==70 and all(d['talents'].get(id,0)==5 for id in IDS) for d in budget),'budget all max exact 930 spent')
    failed=[d for d in stable if d.get('save_failed')]
    check(bool(failed),'purchase write failure observed')
    if failed:
        first=failed[0]
        check(any(d.get('ready') and d['case']==first['case'] and not d.get('save_failed') and d['talents']==first['talents'] and d['hearts']==first['hearts'] for d in data[data.index(first):]),'purchase recovery preserves debit')
    pending=[d for d in data if d['case']=='migration' and not d.get('ready') and d.get('migration_pending')]
    check(len(pending)>=1,'migration blocks before session ready')
    check(all(float(d['hearts'])==25 and not d['talents'] for d in pending),'migration no debit')
    check(any(d['case']=='migration' and float(d['hearts'])==25 for d in stable),'migration recovered')
    art=json.loads((OUT/'art-manifest.json').read_text(encoding='utf-8'))
    for item in art['assets']:
        check(hashlib.sha256((ROOT/item['runtime']).read_bytes()).hexdigest()==item['sha256'],'runtime art hash '+item['id'])
    for file in ['ui.json','flow.json']:
        result=json.loads((OUT/file).read_text(encoding='utf-8'))
        check(not result['failures'],file+' checks')
    report={'checks':len(checks),'failures':failures,'payments':payments,'stable_observations':len(stable),'migration_pending_observations':len(pending),'boundary':'paused mouse verification; fixture max/budget synthetic; art acceptance pending'}
    (OUT/'audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False))
    if failures: raise SystemExit(1)
if __name__=='__main__': main()
