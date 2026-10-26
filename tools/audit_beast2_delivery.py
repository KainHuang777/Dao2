"""Bounded evidence audit; does not run gameplay, modify saves, or export."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification/artifacts/content-p2-beasts-ui'
checks=[]
def check(ok,label):
 checks.append({'ok':bool(ok),'label':label})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
manifest=json.loads((OUT/'art-manifest.json').read_text(encoding='utf-8'))
for item in manifest['assets']:
 for key in ['original','runtime']:
  p=ROOT/item[key];check(sha(p)==item['sha256'],item['id']+' '+key+' exact')
 image=Image.open(ROOT/item['runtime'])
 check(image.mode=='RGBA' and image.getchannel('A').getextrema()==(0,255),item['id']+' transparent')
 check(bool(item['prompt']),item['id']+' prompt retained')
check(manifest['acceptance']=='PENDING_USER_ART_ACCEPTANCE','art not presumed accepted')
for name in ['flow','ui']:
 report=json.loads((OUT/(name+'.json')).read_text(encoding='utf-8'))
 check(not report['failures'],name+' passed')
check(json.loads((OUT/'restore.json').read_text())['checked']==28190,'28190 existing JSON verified')
states=[json.loads(line) for line in (OUT/'browser-states.jsonl').read_text(encoding='utf-8').splitlines()]
for case,beast,costs in [('era4','frost_stag',{'refined_iron':22.2,'spirit_grass_low':190}),('era5','herb_crane',{'spirit_grass_100y':95,'spirit_grass_1000y':11.68})]:
 rows=[s for s in states if s['case']==case]
 check(any(s['save_failed'] and s['active']['active'].get('exp')==50 and all(abs(s['stocks'][k]-v)<1e-8 for k,v in costs.items()) for s in rows),case+' exact charge under denial')
 check(any(not s['save_failed'] and s['active']['active'].get('id')==beast and s['active']['active'].get('exp')==50 for s in rows),case+' recovered/reloaded single XP award')
 check(all(s['active']['active'].get('exp',0)<=50 for s in rows),case+' no duplicate XP')
for case,beast,prefix in [('souls4','frost_stag','stag'),('souls5','herb_crane','crane')]:
 rows=[s for s in states if s['case']==case]
 ids=[prefix+'_t1_boost',prefix+'_t2_growth',prefix+'_t3_discount',prefix+'_t4_capacity']
 check(any(s['souls'].get(beast)==11 and not s['talents'] for s in rows),case+' synthetic budget starts11')
 check(any(s['souls'].get(beast)==10 and s['talents'].get(ids[0])==1 for s in rows),case+' T1 exact charge')
 check(any(s['souls'].get(beast)==5 and all(s['talents'].get(k)==1 for k in ids[:3]) for s in rows),case+' T2/T3 cumulative exact charge')
 check(sum(s['souls'].get(beast)==0 and all(s['talents'].get(k)==1 for k in ids) and not s['save_failed'] for s in rows)>=2,case+' four talents persist reload')
 check(all(0<=s['souls'].get(beast,0)<=11 for s in rows),case+' soul budget bounded')
check(any(s['case']=='souls5' and not s['visible'] for s in states),'Web return home')
check(any(s['case']=='souls5' and s['visible'] and s['souls'].get('herb_crane')==0 for s in states),'Web reopen keeps talents')
check(all(s['viewport']==[1280,720] for s in states),'single desktop viewport')
paths=['src/presentation/beast_care_view.gd','src/presentation/system_actions_panel.gd','src/simulation/beast_system.gd','src/abode/living_abode.gd','src/verification/beast2_acceptance.gd','src/verification/beast2_acceptance.tscn','src/verification/beast2-review-era4.json','src/verification/beast2-review-era5.json','project.godot','export_presets.cfg','assets/fonts/runtime/Dao2Sans-VF.ttf','assets/fonts/runtime/Dao2Serif-VF.ttf','assets/ui/beasts-painted/frost_stag.png','assets/ui/beasts-painted/herb_crane.png']
hashes={p:sha(ROOT/p) for p in paths}
hashes['build/beast2-acceptance/index.pck']=sha(ROOT/'build/beast2-acceptance/index.pck')
report=dict(level='L1/L2 single-size',checks=len(checks),failures=[x['label'] for x in checks if not x['ok']],observations=len(states),results=checks,source_and_package_sha256=hashes,boundary='Read-only evidence audit. Repeated unchanged retry documented by screenshots/tool transcript; paused regular clock still permits normal offline recovery production. No FPS/L3/natural 11-life soul claim.')
(OUT/'delivery-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:report[k] for k in ['checks','failures','observations']}))
raise SystemExit(bool(report['failures']))
