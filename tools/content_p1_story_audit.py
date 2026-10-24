"""Recheck delivered STORY evidence and preserved baseline; no player writes."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from collections import Counter
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p1-story'
def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))
def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def log(path):
    data = Path(path).read_bytes()
    return data.decode('utf-16' if data.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig')
checks = []
def check(name, condition):
    checks.append({'name': name, 'ok': bool(condition)})

baseline = read(OUT / 'baseline-hashes.json')
changes = [p for p, h in baseline.items() if not (ROOT/p).exists() or sha(ROOT/p) != h]
check('frozen build/web unchanged', not any(p.startswith('build/web/') for p in changes))
check('existing UID files unchanged', not any(p.endswith('.uid') for p in changes))
fixtures = read(OUT/'fixture-restoration.json')['files']
for entry in fixtures:
    check('prior fixture '+entry['path'], sha(ROOT/entry['path']) == entry['restored_sha256'])
old = json.loads(subprocess.check_output(['git','show','HEAD:content/encounters/encounters.json'],cwd=ROOT))
new = read(ROOT/'content/encounters/encounters.json')
check('old 26 definitions unchanged', new[:26] == old[:26])
check('38 encounters', len(new) == 38)
new_ids = {x['id'] for x in new[26:]}
check('12 unique new encounters', len(new_ids) == 12)
for row in new[26:]:
    check(row['id']+' weight and options', row['weight'] == 60 and len(row['options']) == 3)
coverage = read(OUT/'runner-coverage.json')
registered = set(re.findall(r"'((?:(?:tests|tools)/)[^']*runner\.gd)'", (ROOT/'tools/run_all_runners.ps1').read_text(encoding='utf-8-sig')))
check('111 registered and covered', len(registered) == 111 and set(coverage['results']) == registered and not coverage['missing'])
for runner, result in coverage['results'].items():
    data = log(ROOT/result['log'])
    check(runner+' evidence', bool(data.strip()) and 'SCRIPT ERROR' not in data and 'SHADER ERROR' not in data)
check('rules 2677', '2677 checks failures=[]' in log(OUT/'rules-delivery.log'))
check('final UI label 158', '158 checks failures=[]' in log(OUT/'ui-label-final.log'))
check('progression 66', read(OUT/'progression.json')['checks'] == 66 and not read(OUT/'progression.json')['failures'])
assets = []
for folder in ['achievements-painted', 'fortune-painted']:
    manifest = read(ROOT/'assets/ui'/folder/'content-p1-story-manifest.json')
    check(folder+' human acceptance', manifest['human_acceptance'] == 'ACCEPTED_BY_USER'
          and manifest.get('acceptance_evidence', {}).get('user_quote') == '全部接受')
    assets += manifest['assets']
for asset in assets:
    check(asset['id']+' original bytes', sha(ROOT/asset['path']) == sha(ROOT/asset['original']) == asset['sha256'])
    with Image.open(ROOT/asset['path']) as im:
        check(asset['id']+' transparency', im.mode == 'RGBA' and im.getextrema()[3][0] == 0 and im.getextrema()[3][1] > 200)
    check(asset['id']+' provenance', bool(asset['prompt']) and bool(asset['license_note']))
check('14 independent assets', len(assets) == 14 and len({a['id'] for a in assets}) == 14)
observations = read(OUT/'web-observations.json')
branches = [x for x in observations if x['kind'] == 'fortune']
check('36 real mouse branches', {(x['id'],x['index']) for x in branches} == {(i,n) for i in new_ids for n in range(3)})
check('selection never consumes RNG', all(x['rng_unchanged'] for x in branches))
achievements = [x for x in observations if x['kind'] == 'achievement']
counts = Counter(tuple(x['viewport']) for x in achievements if x['claimed'])
for size in [(1280,720),(779,360),(800,360)]:
    check(str(size)+' 12 achievement claims', len({x['id'] for x in achievements if tuple(x['viewport']) == size and x['claimed']}) == 12)
retry = next(x for x in observations if x['kind'] == 'save_retry')
check('pending and RNG reload stable', retry['pending_reload_stable'] and retry['rng_reload_stable'])
check('refusal/retry/reload exactly one receipt', retry['failed']['save_failed'] and not retry['retried']['save_failed'] and retry['restored']['fortune']['total_fortunes_claimed'] == 1 and len(retry['restored']['book']['receipts']) == 1)
full = next(x['state'] for x in observations if x['kind'] == 'full_capacity')
check('full capacity disables resource claims', all(x['disabled'] for x in full['buttons'] if any(i in x['path'] for i in ['Card_p1_greenwood_student/', 'Card_p1_golden_specialist/'])))
check('browser error log empty', read(OUT/'browser-console.json') == [])
for folder in ['content-p1-story-acceptance','web-content-p1-story']:
    target = ROOT/'build'/folder
    manifest = read(target/'compression.json')
    for entry in manifest['files']:
        check(folder+'/'+entry['file'], sha(target/entry['file']) == entry['sha256'] and sha(target/(entry['file']+'.br')) == entry['br_sha256'])
    check(folder+' four BGM', len(manifest['audioFiles']) == 4)
    for entry in manifest['audioFiles']:
        check(folder+'/'+entry['file'], sha(target/entry['file']) == entry['sha256'])
    export = log(OUT/('export-acceptance-label.log' if folder.endswith('acceptance') else 'export-normal-label.log'))
    check(folder+' export complete', '[ DONE ]' in export and 'SCRIPT ERROR' not in export and 'ERROR:' not in export)
proposal = read(ROOT/'docs/design-data/content-p1-story-proposal.json')
check('RNG approval recorded', proposal.get('implementation_amendments',{}).get('fortune_rng',{}).get('approved') is True)
report = {'checks':len(checks),'failures':[x['name'] for x in checks if not x['ok']], 'baseline_changed':changes,'results':checks,'human_art_acceptance':'ACCEPTED_BY_USER'}
(OUT/'delivery-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':report['checks'],'failures':report['failures']},ensure_ascii=False))
raise SystemExit(bool(report['failures']))
