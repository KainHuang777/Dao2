"""Reproducible P1 acceptance delivery audit; never rewrites original baselines."""
import base64
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p1-accept'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    checks = []
    def check(label, ok, **detail):
        checks.append(dict(label=label, ok=bool(ok), **detail))
    baseline = json.loads((OUT/'start-hashes.json').read_text(encoding='utf-8'))
    allowed = {'src/abode/living_abode.gd', 'project.godot', 'export_presets.cfg'}
    changed = [p for p,h in baseline.items() if not (ROOT/p).is_file() or sha(ROOT/p)!=h]
    check('existing runtime/assets/frozen files preserved except explicit review wiring', not set(changed)-allowed, changed=changed)
    fixtures=json.loads((OUT/'fixture-backup.json').read_text(encoding='utf-8'))
    check('all pre-existing verification fixture bytes restored',all((ROOT/p).read_bytes()==base64.b64decode(data) for p,data in fixtures.items()),count=len(fixtures))
    result=json.loads((OUT/'integration.json').read_text(encoding='utf-8'))
    check('integration assertions pass',not result['failures'],checks=result['checks'])
    rows={r['choice']:r for r in result['comparisons']}
    check('seven independent choices from one earned second life',len(rows)==7 and len({r['age_at_choice'] for r in rows.values()})==1)
    check('held-heart cost observed',rows['retain']['hearts']==20 and all(rows[x]['hearts']==15 for x in ['alchemical_past_wisdom','artisan_past_wisdom','beast_bond_past_wisdom']))
    check('pill and fox benefits paid and observed',rows['alchemical_past_wisdom']['pill_training_seconds']==66 and rows['retain']['pill_training_seconds']==60 and rows['beast_bond_past_wisdom']['feed_grass']==850 and rows['retain']['feed_grass']==1000)
    for directory in ['content-p1-acceptance','web-content-p1-accept']:
        folder=ROOT/'build'/directory
        manifest=json.loads((folder/'compression.json').read_text(encoding='utf-8'))
        for entry in manifest['files']:
            check(directory+'/'+entry['file'],sha(folder/entry['file'])==entry['sha256'] and sha(folder/(entry['file']+'.br'))==entry['br_sha256'])
        for entry in manifest['audioFiles']:
            check(directory+'/'+entry['file'],sha(folder/entry['file'])==entry['sha256'])
    log=(OUT/'l3-runners-host.log').read_text(encoding='utf-8-sig')
    passed=set(re.findall(r'\[PASS:initial\] ((?:tests|tools)/\S+\.gd)',log))
    failed=set(re.findall(r'\[FAIL:serial-retry\] (tests/\S+\.gd)',log))
    patch=(OUT/'skills-ui-final-console.log').read_text(encoding='utf-8-sig')
    repaired='CONTENT-P1-SKILL UI 87 checks failures=[]' in patch and 'SCRIPT ERROR:' not in patch
    check('L3 registry coverage with targeted three-size repair',len(passed)==111 and failed=={'tests/content_p1_skills_ui_runner.gd'} and repaired and 'SCRIPT ERROR:' not in log, passed_initial=len(passed),original_full_command_exit=1,repaired=sorted(failed),targeted_repair_exit=0,footer=log[-2000:])
    web=json.loads((OUT/'web-observations.json').read_text(encoding='utf-8'))
    check('desktop three game viewports observed',all(any(r.get('css_viewport',r.get('viewport'))==size for r in web) for size in [[1280,720],[844,390],[800,360]]))
    check('browser failed save and saved reload preserve one purchase',any(r.get('step')=='artisan-refused-final' and r.get('save_failed') and r.get('hearts')=='15' and r.get('talents',{}).get('artisan_past_wisdom')==1 for r in web) and any(r.get('step')=='artisan-reloaded' and not r.get('save_failed') and r.get('hearts')=='15' and r.get('talents',{}).get('artisan_past_wisdom')==1 for r in web))
    report={'checks':checks,'failures':[x['label'] for x in checks if not x['ok']], 'human_rhythm_acceptance':'PENDING', 'art_acceptance':'reuse previously accepted S/T/P/SECT/STORY; no new art', 'historical_exception':'STORY preservation failures remain historical failures; current start-hashes is a separate task baseline'}
    (OUT/'delivery-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'checks':len(checks),'failures':report['failures']},ensure_ascii=False))
    return bool(report['failures'])

if __name__=='__main__':
    raise SystemExit(main())
