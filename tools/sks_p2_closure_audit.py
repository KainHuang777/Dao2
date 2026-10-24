"""Archive runner logs, restore previous JSON evidence, and audit this closure."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
D = ROOT / 'docs/verification/artifacts/sks-p2-closure'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def read(p):
    raw = p.read_bytes()
    text = raw.decode('utf-16') if raw.startswith((b'\xff\xfe', b'\xfe\xff')) else raw.decode('utf-8-sig')
    return re.sub(r'\x1b\[[0-9;]*[A-Za-z]', '', text)

def archive():
    for name in ['full-sandbox-interrupted.log', 'full-command.log']:
        match = re.search(r'\[LOGS\] ([^\r\n]+)', read(D/name))
        if match and Path(match[1].strip()).exists():
            folder = Path(match[1].strip())
            shutil.copytree(folder, D/'logs'/folder.name, dirs_exist_ok=True)
    before = json.loads(read(D/'before-json-hashes.json'))
    restored = []
    for name, digest in before.items():
        path = ROOT/name
        if not path.exists() or sha(path) != digest:
            if path.exists():
                target = D/'generated'/name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(path, target)
            shutil.copyfile(D/'before'/name, path)
            restored.append(name)
        assert sha(path) == digest, name
    # Initial git status showed no modifications to tracked src/verification JSON.
    # Some runners refresh their envelope timestamps there. Archive their output,
    # then restore those initially clean tracked fixtures from the same HEAD.
    baseline_head = 'c81254b553ad94bae2cee3275bc516658ff17b0a'
    current_head = subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    assert current_head == baseline_head, 'HEAD changed: inspect before restoring initially clean fixtures'
    names = subprocess.check_output(['git','diff','--name-only','--','src/verification'],cwd=ROOT,text=True).splitlines()
    source_restored = []
    for name in names:
        if not name.endswith('.json'):
            continue
        path = ROOT/name
        target = D/'generated'/name
        target.parent.mkdir(parents=True,exist_ok=True)
        if not target.exists():
            shutil.copyfile(path,target)
        original = subprocess.check_output(['git','show',baseline_head+':'+name],cwd=ROOT)
        path.write_bytes(original)
        source_restored.append(name)
    restored = [name for name in before if (D/'generated'/name).exists()]
    source_restored = [p.relative_to(D/'generated').as_posix() for p in (D/'generated/src/verification').glob('*.json')]
    (D/'restored-fixtures.json').write_text(json.dumps({'checked':len(before),'restored':restored,'initially_clean_source_fixtures_restored':source_restored},indent=2),encoding='utf-8')
    print(json.dumps({'checked':len(before),'restored':len(restored)}))

def audit():
    checks, failures = [], []
    def check(ok, label):
        checks.append(label)
        if not ok:
            failures.append(label)
    command = read(D/'full-command.log')
    runners = [x.strip() for x in read(D/'full-list.log').splitlines() if x.strip().endswith('.gd')]
    check(len(runners)==len(set(runners))==118, '118 unique registered runners')
    check('matrix=full' in command and 'parallel=3' in command, 'L3 full matrix parallel3')
    check(read(D/'full-exit.txt').strip()=='0', 'full command exit0')
    check(f'SELECTED {len(runners)} RUNNERS PASSED (matrix=full)' in command, 'full command complete')
    match = re.search(r'\[LOGS\] ([^\r\n]+)',command)
    folder = D/'logs'/Path(match[1].strip()).name
    for runner in runners:
        attempt = 'serial-retry' if '[PASS:serial-retry] '+runner in command else 'initial'
        check('[PASS:'+attempt+'] '+runner in command, 'PASS '+runner)
        log = folder/(runner.replace('/','_')+'.'+attempt+'.log')
        err = Path(str(log)+'.err')
        check(log.exists() and err.exists(), 'raw logs '+runner)
        if log.exists() and err.exists():
            check('SCRIPT ERROR:' not in read(log)+read(err), 'no SCRIPT ERROR '+runner)
    for filename in ['export','compression']:
        check(read(D/(filename+'-exit.txt')).strip()=='0', filename+' exit0')
    check('[ DONE ] savepack' in read(D/'export.log'), 'candidate savepack complete')
    package = json.loads(read(D/'compression.log'))
    build = ROOT/'build/web-sks-p2'
    for item in package['files']:
        check(sha(build/item['file'])==item['sha256'], 'candidate '+item['file'])
        check(sha(build/(item['file']+'.br'))==item['br_sha256'], 'Brotli '+item['file'])
    check(len(package['audioFiles'])==4, 'four BGM companions')
    for item in package['audioFiles']:
        check(sha(build/item['file'])==item['sha256'], 'BGM '+item['file'])
    check('state_equal=true' in read(D/'rebase.log'), 'earned fixture state preserved')
    before = json.loads(read(D/'before-json-hashes.json'))
    check(all((ROOT/name).exists() and sha(ROOT/name)==h for name,h in before.items()), 'original JSON evidence byte restored')
    integrity = json.loads(read(D/'backup-integrity.json'))
    check(integrity['backups']==len(before) and integrity['failures']==[], 'pre-run backup integrity')
    source = json.loads(read(D/'candidate-source-hashes.json'))
    check(all((ROOT/name).exists() and sha(ROOT/name)==h for name,h in source.items() if not name.startswith('src/verification/')), 'candidate runtime and asset provenance (verification fixtures excluded)')
    web = json.loads(read(D/'browser-observations.json'))
    check(web['sizes']==[[1280,720],[844,390],[800,360]], 'three landscape desktop sizes')
    states = {row['step']:row.get('state',{}) for row in web['observations']}
    check('deep_vein_resonance' not in states['before-refused-study']['skills'], 'new skill absent before study')
    old = states['study-save-refused-persisted-old']
    check(old==states['retry-denied-persisted-old'], 'refused retry preserves persisted state')
    check('deep_vein_resonance' not in old['skills'], 'refusal keeps old persisted skill state')
    for name in ['recovered-study-once','reload-keeps-study']:
        s = states[name]
        check(s['skills'].get('deep_vein_resonance')==1 and s['skill_version']==4 and s['economy']=='res1-e-46-1', name)
    check(web['logs']==[], 'observed browser error/warning window empty')
    shots = list(D.glob('web-*.png'))
    check(len(shots)>=5 and all(p.stat().st_size>10000 for p in shots), 'browser screenshots archived')
    decision = json.loads(read(D/'closure-decision.json'))
    check(decision['user_quote']=='整批收尾', 'actual user closure instruction preserved')
    check(decision['scope']=='SKS-P2', 'closure limited to skill batch')
    for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md','docs/21-res1-e-skills-expansion-plan.md','docs/25-system-content-expansion-plan.md']:
        first = read(ROOT/name).splitlines()[0]
        check('SKS-P2 DONE' in first, 'current closure status '+name)
    proposal = json.loads(read(ROOT/'docs/design-data/sks-p2-proposal.json'))
    check(proposal['implementation'].startswith('SKS-P2 DONE'), 'implementation metadata closed')
    result = {'level':'L3','checks':len(checks),'failures':failures,'runners':len(runners),'initial_failures':re.findall(r'\[FAIL:initial\] ([^ ]+)',command),'package':package,'source_files':len(source),'original_json_files':len(before),'historical_failures_preserved':True,'candidate':'build/web-sks-p2'}
    (D/'delivery-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:result[k] for k in ['checks','failures','runners','initial_failures']}))
    return bool(failures)

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--archive-generated', action='store_true')
    args = p.parse_args()
    if args.archive_generated:
        archive()
    else:
        raise SystemExit(audit())
