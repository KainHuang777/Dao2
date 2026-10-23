"""Bounded CONTENT-P1-SECT delivery evidence; no gameplay or player storage writes."""
from pathlib import Path
import hashlib,json,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification/artifacts/content-p1-sect'
failures=[];checks=0
def check(ok,label):
    global checks
    checks+=1
    if not ok: failures.append(label)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return p.read_text(encoding='utf-8-sig')
def data(p): return json.loads(read(p))
for file,count in [('rules.json',6778),('native-ui.json',69),('progression.json',16)]:
    d=data(OUT/file);check(d['checks']==count and not d['failures'],file)
registry=re.findall(r"'((?:tests|tools)/[^']+\.gd)'",read(ROOT/'tools/run_all_runners.ps1'))
parts=[('second','tests/uix_r9_sect_ui_runner.gd'),('tail','tests/m1a_core_runner.gd'),('final-tail','tests/sks_p1_runner.gd'),('end',None)]
executed=[]
for name,stop in parts:
    log=read(OUT/('all-runners-'+name+'.log'))
    selected=log.split('[RUNNING] '+stop)[0] if stop else log
    check('SCRIPT ERROR' not in selected and 'SHADER ERROR' not in selected,'final suite diagnostics '+name)
    executed.extend(re.findall(r'^\[RUNNING\] ((?:tests|tools)/\S+\.gd)',selected,re.M))
focused=read(OUT/'focused-final.log')
check('ALL 6 FOCUSED RUNNERS PASSED' in focused and 'SCRIPT ERROR' not in focused,'final focused six')
executed.extend(re.findall(r'^\[RUNNING\] ((?:tests|tools)/\S+\.gd)',focused,re.M))
check(set(executed)==set(registry) and len(set(registry))==107,'107 unique fixed runners including tools entry')
check('ALL 14 RUNNERS PASSED WITH EXIT CODE 0!' in read(OUT/'all-runners-end.log'),'final suite tail exit0')
art=[]
manifest=data(ROOT/'assets/ui/sects-painted/content-p1-manifest.json')
check(manifest.get('approval')=='ACCEPTED_BY_USER','human art/card acceptance recorded')
check(manifest.get('human_acceptance',{}).get('user_quote')=='美術接受','explicit acceptance evidence')
for a in manifest['assets']:
    runtime=ROOT/'assets/ui/sects-painted'/a['file']; original=OUT/'originals'/a['file']
    check(sha(runtime)==sha(original),a['id']+' original retained')
    with Image.open(runtime) as im:
        check(im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255),a['id']+' real alpha')
        art.append({'id':a['id'],'sha256':sha(runtime),'size':list(im.size),'mode':im.mode})
    check(len(a['prompt'])>100,a['id']+' prompt retained')
obs=data(OUT/'web-observations.json')
by={o['case']:o for o in obs}
for id in ['home_supply_register','wood_ore_convoy','herb_island_inventory','specialist_pill_preparation','jade_fox_nursery']:
    check('template-dispatch-claim-'+id in by,'real Web dispatch/claim '+id)
earned=by.get('earned-natural-reload',{}).get('state',{})
check(earned.get('sect',{}).get('contribution')=='33' and earned.get('pills',{}).get('herb_nurture_pill')==1 and earned.get('sect',{}).get('techniques',{}).get('alchemy_herb_conservation')==1,'earned natural path reload')
for width in [844,800]:
    for action in ['buy-wood','buy-pill','learn-alchemy','learn-fox']:
        check(str(width)+'-'+action in by,'real mouse '+str(width)+action)
check('reload-after-denied-learning' in by,'write denial save-only recovery reload')
guards=data(ROOT/'docs/verification/artifacts/content-p1-sect-design/session-start.json')['protected']
changed=[p for p,h in guards.items() if not (ROOT/p).exists() or sha(ROOT/p)!=h]
allowed={'src/domain/game_state.gd','src/simulation/sect_system.gd','src/simulation/beast_system.gd','src/simulation/alchemy_system.gd','src/simulation/command_processor.gd','src/simulation/island_progression.gd','src/persistence/save_manager.gd','src/persistence/save_codec.gd','src/presentation/sect_panel.gd','src/abode/living_abode.gd','tests/uix_r9_sect_ui_runner.gd','tests/sks_p1_runner.gd','project.godot','export_presets.cfg','assets/fonts/runtime/Dao2Sans-VF.ttf','assets/fonts/runtime/Dao2Serif-VF.ttf','assets/fonts/runtime/manifest.json'}
unexpected=sorted(set(changed)-allowed)
check(not unexpected,'protected source/assets/fixtures outside approved task')
check(sha(ROOT/'build/web/index.pck')=='74aa640f734044c59bbe1a1d67f473cf9b705ca74d50169d2aeb04bc62106e4f','frozen build/web unchanged')
exports={}
for name in ['web-content-p1-sect','content-p1-sect-acceptance']:
    folder=ROOT/'build'/name
    exports[name]={f:sha(folder/f) for f in ['index.html','index.js','index.wasm','index.pck']}
    check(all((folder/(f+'.br')).exists() for f in ['index.js','index.wasm','index.pck']),name+' compressed companions')
    check(len(list((folder/'audio/bgm').glob('*.mp3')))==4,name+' four BGM')
    compression=data(folder/'compression.json')
    for entry in compression['files']: check(sha(folder/entry['file'])==entry['sha256'],name+' compression matches '+entry['file'])
sources={p:sha(ROOT/p) for p in changed if (ROOT/p).exists()}
for p in ['src/persistence/sect_save_contract.gd','src/verification/content_p1_sect_acceptance.gd','src/verification/content_p1_sect_acceptance.tscn','src/verification/content_p1_sect_fixture.json','src/verification/content_p1_sect_tasks.json','src/verification/content_p1_sect_earned_start.json','tests/content_p1_sect_runner.gd','tests/content_p1_sect_progression_runner.gd','tests/content_p1_sect_ui_runner.gd','assets/ui/sects-painted/content-p1-manifest.json']:
    sources[p]=sha(ROOT/p)
    check('\ufffd' not in read(ROOT/p),p+' strict UTF8')
report={'checks':checks,'failures':failures,'unique_runners':len(set(executed)),'registry':registry,'art':art,'changed_protected':changed,'unexpected_protected':unexpected,'sources':sources,'exports':exports,'scope':'CLI, native and real mouse desktop Web; two technique images and batch cards accepted by the user on 2026-10-23. No FPS/device or natural pacing budget claim.'}
(OUT/'audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'checks':checks,'failures':failures,'unique_runners':len(set(executed))},ensure_ascii=False))
raise SystemExit(bool(failures))
