"""CONTENT-P1-PILL evidence audit. Read-only except its own JSON report."""
from pathlib import Path
import hashlib,json,re
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'docs/verification/artifacts/content-p1-pills'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return p.read_text(encoding='utf-8-sig')
failures=[];checks=0
def check(value,label):
 global checks
 checks+=1
 if not value: failures.append(label)
for filename,count in [('runner.json',609),('native-ui.json',102)]:
 data=json.loads(read(OUT/filename));check(data['checks']==count and not data['failures'],filename)
for name in ['runner-final.log','native-final.log']:
 log=read(OUT/name);check('SCRIPT ERROR' not in log and 'SHADER ERROR' not in log,name)
suite=re.findall(r"'((?:tests|tools)/[^']+\.gd)'",read(ROOT/'tools/run_all_runners.ps1'))
prefix=read(OUT/'all-prefix.log').split('[RUNNING] tests/content_p1_skills_runner.gd')[0]
tail=read(OUT/'all-tail.log')
check('ALL 99 RUNNERS PASSED WITH EXIT CODE 0!' in tail,'tail exit0')
check('SCRIPT ERROR' not in prefix+tail and 'SHADER ERROR' not in prefix+tail,'suite script/shader diagnostics')
executed=re.findall(r'^\[RUNNING\] ((?:tests|tools)/\S+\.gd)',prefix+tail,re.M)
check(list(dict.fromkeys(executed))==suite and len(set(executed))==104,'104 fixed runners covered')
(OUT/'runner-coverage.json').write_text(json.dumps({'unique':len(set(executed)),'expected':len(suite),'printed_headers':len(executed),'note':'Three legacy runners also print their own RUNNING header; deduplicate while preserving registry order.','executed':executed,'failures':failures},ensure_ascii=False,indent=2),encoding='utf-8')
manifest=json.loads(read(OUT/'art-manifest.json'));pictures=[]
for a in manifest['assets']:
 runtime=ROOT/a['runtime'];original=ROOT/a['original']
 check(sha(runtime)==a['sha256']==sha(original),a['id']+' original bytes')
 with Image.open(runtime) as im:
  check(im.mode=='RGBA',a['id']+' alpha mode')
  alpha=im.getchannel('A');extrema=alpha.getextrema()
  check(extrema==(0,255),a['id']+' transparent/opaque foreground')
  pictures.append({'id':a['id'],'size':im.size,'alpha_extrema':extrema,'sha256':sha(runtime)})
check(manifest['art_acceptance']=='accepted' and manifest.get('art_acceptance_date')=='2026-10-23' and manifest.get('art_acceptance_evidence',{}).get('user_quote')=='美術接受','explicit human art acceptance recorded')
obs=json.loads(read(OUT/'web-observations.json'))['confirmed']
by={o['label']:o for o in obs}
check(len(by['1280 final four active']['buffs'])==4,'four actual web buffs')
for label in ['844 refine qi denied','844 retry still denied','844 recovered save']:
 o=by[label];check(o['pills']['qi_absorption_pill']==1 and o['resources']['spirit_grass_low']=='360' and o['resources']['stone_low']=='370',label+' no duplicate cost')
check(by['844 refine qi denied']['save_failed'] and not by['844 recovered save']['save_failed'],'web denial recovery')
check(all(v==0 for v in by['reload all paid commands persisted']['pills'].values()),'web reload pills persisted')
baseline=json.loads(read(OUT/'baseline.json'))
check(sha(ROOT/'build/web/index.pck')==baseline['web_pck_sha256'],'existing web package unchanged this task')
exports={}
for directory in ['web-content-p1-pills','content-p1-pills-acceptance']:
 folder=ROOT/'build'/directory
 compression=json.loads(read(folder/'compression-manifest.json')) if (folder/'compression-manifest.json').exists() else None
 exports[directory]={f:sha(folder/f) for f in ['index.html','index.js','index.wasm','index.pck']}
 check(all((folder/(f+'.br')).exists() for f in ['index.js','index.wasm','index.pck']),directory+' companions')
 check(len(list((folder/'audio/bgm').glob('*.mp3')))==4,directory+' four BGM')
paths=['src/simulation/alchemy_system.gd','src/simulation/buff_system.gd','src/simulation/command_processor.gd','src/domain/game_state.gd','src/content/content_loader.gd','src/persistence/save_codec.gd','src/persistence/save_manager.gd','src/presentation/alchemy_panel.gd','src/presentation/abode_modal_manager.gd','src/presentation/resource_icon.gd','tests/content_p1_pills_runner.gd','tests/content_p1_pills_ui_runner.gd','src/verification/content_p1_pills_acceptance.gd','src/verification/content_p1_pills_acceptance.tscn','src/verification/content_p1_pills_fixture.json','project.godot','export_presets.cfg','tools/run_all_runners.ps1','tools/content_p1_pills_audit.py']
source={p:sha(ROOT/p) for p in paths}
for p in paths: check('\ufffd' not in read(ROOT/p),p+' UTF8')
report={'checks':checks,'failures':failures,'art':pictures,'source_sha256':source,'exports':exports,'existing_web_sha256':sha(ROOT/'build/web/index.pck'),'scope':'CLI, native three desktop landscapes, bounded actual Web. Four pill images and cards accepted by the user on2026-10-23. No device or FPS claim.'}
(OUT/'audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'checks':checks,'failures':failures},ensure_ascii=False))
raise SystemExit(bool(failures))
