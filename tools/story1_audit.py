"""Static delivery audit for approved Y / STORY-1; never starts Godot or edits saves."""
import hashlib, json, re, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root/'docs/verification/artifacts/content-p2-story'
def read(p): return json.loads((root/p).read_text(encoding='utf-8-sig'))
checks=0
failures=[]
def check(value,label):
    global checks
    checks+=1
    if not value: failures.append(label)
proposal=read('docs/design-data/content-p2-story-proposal.json')
runtime=read('content/encounters/encounters.json')
p2=[d for d in runtime if d.get('content_batch')=='content-p2-story']
check(len(runtime)==56 and len(p2)==18,'56/18 events')
keys=['id','title','desc','min_era','requires','art','options','weight','content_batch','definition_version','weather_bias','shichen_bias','realm_bias']
check(p2==[{k:d[k] for k in keys} for d in proposal['encounters']],'approved 54 branches exact')
achievement_source=(root/'src/simulation/achievement_system.gd').read_text(encoding='utf-8-sig')
block=achievement_source.split('const P2_DEFINITIONS := ',1)[1].split('\n\nstatic var DEFINITIONS:',1)[0]
definitions=json.loads(block)
check(len(definitions)==18,'18 P2 achievements')
for item in proposal['achievements']:
    actual=definitions[item['id']]
    for k in ['id','name','category']: check(actual[k]==item[k],item['id']+k)
    check(actual['desc']==item['condition'],item['id']+' condition')
    expected=item['rewards'].copy()
    if 'resources' in expected: expected['resource']=expected.pop('resources')
    check(actual['rewards']==expected,item['id']+' rewards')
    check(not any(k in actual['rewards'] for k in ['dao_heart','dao_proof','beast_souls','skill_point']),'no new meta currency')
baseline=read('docs/verification/artifacts/content-p2-story-design/protected-baseline.json')
allowed={
    'content/encounters/encounters.json','src/application/game_session.gd','src/content/content_loader.gd',
    'src/domain/decision_receipt.gd','src/persistence/save_codec.gd','src/persistence/save_manager.gd','src/persistence/story_save_contract.gd',
    'src/simulation/achievement_system.gd','src/simulation/beast_system.gd','src/simulation/fortune_system.gd','src/simulation/island_progression.gd','src/simulation/sect_system.gd','src/simulation/story_progress.gd',
    'tests/content_p1_story_runner.gd','tests/content_p2_beasts_save_runner.gd','tests/content_p2_pills_save_runner.gd','tests/content_p2_sect_save_runner.gd','tests/content_p2_supply_economy_runner.gd','tests/sks_p2_core_runner.gd',
}
changed=[]
for rel,digest in baseline.items():
    path=root/rel
    actual=hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None
    if actual!=digest: changed.append(rel)
    check(actual==digest or rel in allowed,'protected '+rel)
restoration=read('docs/verification/artifacts/content-p2-story/json-restoration.json')
check(restoration['all_original_hashes_match'],'existing JSON restored')
for name in ['core','save','events']:
    result=read('docs/verification/artifacts/content-p2-story/'+name+'.json')
    check(not result['failures'],name+' no failures')
check(proposal['approval']=='APPROVED_Y_ALL','Y metadata approved')
check(not proposal['policy']['art']['generated'] and not proposal['policy']['art']['accepted'],'actual art still pending')
result={'level':'L1 static delivery audit','checks':checks,'failures':failures,'protected_files':len(baseline),'explicit_changed_files':changed,'existing_json':restoration,'new_runner_counts':{k:read('docs/verification/artifacts/content-p2-story/'+k+'.json')['checks'] for k in ['core','save','events']}}
out.mkdir(parents=True,exist_ok=True)
(out/'delivery-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':checks,'failures':failures,'protected':len(baseline),'changed':changed},ensure_ascii=False))
sys.exit(bool(failures))
