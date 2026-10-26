"""Bounded PILL-2 evidence audit; preserves historical reports and raw failures."""
from pathlib import Path
from decimal import Decimal
import hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification/artifacts/content-p2-pills-ui'
checks=[]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def check(ok,label):checks.append({'ok':bool(ok),'label':label})
def restore():
 restored=[]
 for row in read(OUT.relative_to(ROOT)/'baseline-index.json'):
  p=ROOT/row['path'];backup=OUT/'baseline'/row['path']
  assert sha(backup)==row['sha256']
  if sha(p)!=row['sha256']:
   dst=OUT/'rerun-results'/p.name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dst);shutil.copyfile(backup,p)
  restored.append(dict(path=row['path'],sha256=sha(p),ok=sha(p)==row['sha256']))
 (OUT/'restoration.json').write_text(json.dumps(restored,indent=2),encoding='utf-8')
def main():
 manifest=read(OUT.relative_to(ROOT)/'art-manifest.json')
 check(len(manifest['assets'])==8,'eight generated images')
 check(manifest['acceptance']=='PENDING_USER_ART_ACCEPTANCE','art pending human acceptance')
 for item in manifest['assets']:
  check(sha(ROOT/item['runtime'])==sha(ROOT/item['original'])==item['sha256'],item['id']+' immutable original/runtime')
  check(item['alpha_extrema']==[0,255],item['id']+' alpha preserved')
  check(item['id'] in (ROOT/'src/presentation/resource_icon.gd').read_text(encoding='utf-8'),item['id']+' shared icon registration')
 flow=read(OUT.relative_to(ROOT)/'flow.json');ui=read(OUT.relative_to(ROOT)/'ui.json')
 for name,data,minimum in [('flow',flow,64),('ui',ui,96)]:check(not data['failures'] and data['checks']>=minimum,name+' checks')
 check(set(x['id'] for x in flow['uses'])==set(x['id'] for x in manifest['assets']),'all eight IDs earned effective use')
 check([(x['from'],x['to']) for x in flow['tribulation_trace']]==[(4,5),(5,6)],'continuous formal Era4→5→6')
 check(sha(ROOT/flow['source'].removeprefix('res://'))==flow['source_sha256'],'actual inherited source hash')
 check(flow['end_age']>flow['start_age'],'positive simulated time, no age injection')
 for era in [4,5,6]:
  path=OUT/f'earned-era{era}.json';check(sha(path)==sha(ROOT/f'src/verification/pill2-era{era}.json'),'browser fixture byte identical earned era'+str(era))
 observations=[json.loads(s) for s in (OUT/'browser-states.jsonl').read_text(encoding='utf-8').splitlines()]
 era5=[d for d in observations if d.get('case')=='era5' and d.get('era')==5]
 check(bool(era5),'real Web earned Era5 observation')
 def find(rev):return next(d for d in era5 if d['revision']==rev)
 before,after=find(3000),find(3001)
 for resource,cost in [('spirit_grass_100y',10),('mithril',2),('lingli',1000)]:
  check(Decimal(before['resources'][resource])-Decimal(after['resources'][resource])==cost,'Web nascent exact debit '+resource)
 check(find(3002)['effects']['stacks']['p2_training']==1,'Web consume shared stack')
 before,after=find(3002),find(3003)
 for resource,cost in [('spirit_grass_1000y',1),('mithril',5),('lingli',2000)]:
  check(Decimal(before['resources'][resource])-Decimal(after['resources'][resource])==cost,'Web stone-vault exact debit '+resource)
 failures=[d for d in era5 if d['save_failed']]
 check(bool(failures) and all(d['pills'].get('stone_vault_pill')==0 and d['effects']['p2_capacity_counts']['stone_vault_pill']==2 and d['effects']['total_consumed']==9 for d in failures),'refused/retry preserves single consume')
 check(len(failures)>=1,'save failure observed; repeat denied retry separately recorded by screenshot/tool')
 recovered=[d for d in era5 if d['revision']>3004 and not d['save_failed']]
 check(any(d['effects']['p2_capacity_counts']['stone_vault_pill']==2 and d['effects']['total_consumed']==9 for d in recovered),'recovered/reloaded keeps capacity count2')
 timed=find(3010)
 check(timed['pills']['ancient_herb_dew_pill']==1 and timed['buffs']['p2_ancient_dew']['remaining_seconds']==600,'Web timed replacement to600')
 check(timed['rows']['ancient_herb_dew_pill']['consume_disabled'],'Web no-extension disabled')
 check(all(d['viewport']==[1280,720] for d in observations if d.get('era') in [5,6]),'actual 1280×720 canvas')
 check(any(d.get('era')==6 and all(w['art'] for w in d['rows'].values()) for d in observations),'eight art textures loaded in Web')
 for name in ['art-gallery.png','web-home.png','web-save-refused.png','web-save-recovered.png','web-era6-timed.png','web-timed-no-extension.png']:
  check((OUT/name).exists(),'screenshot '+name)
 for p in [ROOT/'src/presentation/alchemy_panel.gd',ROOT/'src/presentation/resource_icon.gd',ROOT/'src/verification/pill2_acceptance.gd',ROOT/'tests/content_p2_pills_flow_runner.gd',ROOT/'tests/content_p2_pills_ui_runner.gd']:
  p.read_text(encoding='utf-8',errors='strict');check(True,'UTF-8 '+p.name)
 for row in read(OUT.relative_to(ROOT)/'restoration.json'):check(row['ok'] and sha(ROOT/row['path'])==row['sha256'],'restored '+row['path'])
 source_files=['src/presentation/alchemy_panel.gd','src/presentation/resource_icon.gd','src/abode/living_abode.gd','src/simulation/alchemy_system.gd','src/verification/pill2_acceptance.gd','project.godot','export_presets.cfg','assets/fonts/runtime/Dao2Sans-VF.ttf','assets/fonts/runtime/Dao2Serif-VF.ttf']
 package={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in (ROOT/'build/pill2-acceptance').glob('index.*')}
 (OUT/'web-manifest.json').write_text(json.dumps({'date':'2026-10-25','purpose':'L2 local test package, not a release candidate','source':{p:sha(ROOT/p) for p in source_files},'package':package},indent=2),encoding='utf-8')
 report={'checks':len(checks),'failures':[x['label'] for x in checks if not x['ok']],'details':checks}
 (OUT/'delivery-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'checks':len(checks),'failures':report['failures']},ensure_ascii=False))
 raise SystemExit(bool(report['failures']))
if __name__=='__main__':
 import sys
 if '--restore' in sys.argv:restore()
 else:main()
