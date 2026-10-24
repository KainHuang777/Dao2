"""Archive L3 evidence, restore pre-existing JSON fixtures, and audit delivery."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
D = ROOT / 'docs/verification/artifacts/content-p2-supply-closure'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def read(path):
    raw = path.read_bytes()
    text = raw.decode('utf-16') if raw.startswith((b'\xff\xfe', b'\xfe\xff')) else raw.decode('utf-8-sig')
    return re.sub(r'\x1b\[[0-9;]*[A-Za-z]', '', text)

def archive():
    # Only call after the full run has ended. Keep every original failed log.
    for name in ['full-sandbox-interrupted.log', 'full-normal-command.log']:
        log = D / name
        match = re.search(r'\[LOGS\] ([^\r\n]+)', read(log))
        if match:
            folder = Path(match[1].strip())
            if folder.exists():
                shutil.copytree(folder, D/'logs'/folder.name, dirs_exist_ok=True)
    before = json.loads((D/'before-json-hashes.json').read_text(encoding='utf-8'))
    restored = []
    for name, digest in before.items():
        path = ROOT/name
        if not path.exists() or sha(path) != digest:
            if path.exists():
                copy = D/'generated'/name
                copy.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(path, copy)
            shutil.copyfile(D/'before'/name, path)
            restored.append(name)
        assert sha(path) == digest, name
    (D/'restored-fixtures.json').write_text(json.dumps({'restored':restored,'checked':len(before)},ensure_ascii=False,indent=2),encoding='utf-8')
    print('Restored',len(restored),'pre-existing JSON files; new results archived separately')

def audit():
    failures = []
    checks = []
    def check(ok, label):
        checks.append(label)
        if not ok:
            failures.append(label)
    command = read(D/'full-normal-command.log')
    runners = [line.strip() for line in read(D/'full-list.log').splitlines() if line.strip().endswith('.gd')]
    check(len(runners) == len(set(runners)), 'unique registered runners')
    check('matrix=full' in command and 'parallel=3' in command,'L3 full matrix and parallel3')
    check(read(D/'full-normal-exit.txt').strip() == '0','full command exit0')
    check(f'SELECTED {len(runners)} RUNNERS PASSED (matrix=full)' in command,'complete full command')
    log_dir = re.search(r'\[LOGS\] ([^\r\n]+)',command)
    local_logs = D/'logs'/Path(log_dir[1].strip()).name
    for runner in runners:
        attempt = 'serial-retry' if '[PASS:serial-retry] '+runner in command else 'initial'
        check(f'[PASS:{attempt}] {runner}' in command,'PASS '+runner)
        stdout = local_logs/(runner.replace('/','_')+'.'+attempt+'.log')
        stderr = Path(str(stdout)+'.err')
        check(stdout.exists() and stderr.exists(),'archived raw logs '+runner)
        if stdout.exists() and stderr.exists():
            check('SCRIPT ERROR:' not in read(stdout)+read(stderr),'no script error '+runner)
    before = json.loads((D/'before-json-hashes.json').read_text(encoding='utf-8'))
    check(all((ROOT/name).exists() and sha(ROOT/name)==h for name,h in before.items()),'all original JSON fixtures restored')
    reuse = json.loads((D/'source-reuse-check.json').read_text())
    check(reuse['changed_runtime_content']==[],'SUPPLY3 runtime/content matched at closure start')
    prior = json.loads((D/'before/docs/verification/artifacts/content-p2-supply-3/delivery-audit.json').read_text(encoding='utf-8'))
    delta = [name for name,h in prior['source_hashes'].items() if not name.startswith('src/verification/') and sha(ROOT/name)!=h]
    check(delta==['src/presentation/island_world.gd'],'final runtime delta limited to Danxia version label')
    provenance = json.loads((D/'candidate-provenance.json').read_text(encoding='utf-8'))
    check(all(sha(ROOT/name)==h for name,h in provenance['files'].items()),'candidate source and asset provenance unchanged')
    check(sha(ROOT/'build/web-content-p2-supply/index.pck')==provenance['pck_sha256'],'candidate PCK provenance')
    decision = json.loads((D/'closure-decision.json').read_text(encoding='utf-8'))
    check(decision['user_quote']=='接受目前節奏與 UI，完成整批驗收收尾','explicit human acceptance')
    check('state_equal=true' in read(D/'rebase-era6.log'),'earned fixture state preserved')
    check(read(D/'export-exit.txt').strip()=='0' and '[ DONE ] savepack' in read(D/'export.log'),'candidate export succeeded')
    check(read(D/'compression-exit.txt').strip()=='0','candidate compression succeeded')
    compression = json.loads(read(D/'compression.log'))
    build = ROOT/'build/web-content-p2-supply'
    for item in compression['files']:
        check(sha(build/item['file'])==item['sha256'],'candidate '+item['file'])
        check(sha(build/(item['file']+'.br'))==item['br_sha256'],'compressed '+item['file'])
    check(len(compression['audioFiles'])==4,'four BGM companions')
    for item in compression['audioFiles']:
        check(sha(build/item['file'])==item['sha256'],'BGM '+item['file'])
    web = json.loads((D/'web-observations.json').read_text(encoding='utf-8'))
    check(web['route_after_reload']=={'enabled':True,'level':3,'reserve':'0','target':'3000'},'real mouse upgrade retry and reload')
    check(web['console_warn_error']==[],'observed browser console windows')
    check(web['bulk_stock_after']==160,'real bulk product output')
    check(web['sizes']==[[1280,720],[844,390],[800,360]],'three desktop landscape sizes')
    check(web['final_candidate_smoke']['console_warn_error']==[],'final candidate console window')
    check(web['final_candidate_smoke']['route_after_reload']==web['route_after_reload'],'final re-export preserves route3')
    flow_path = D/'generated/docs/verification/artifacts/content-p2-supply-3/earned-flow.json'
    flow = json.loads(flow_path.read_text(encoding='utf-8'))
    check(flow['failures']==[] and flow['checks']>90,'fresh complete legal supply flow including rebirth')
    check([row['to'] for row in flow['trace']]==[4,5,6],'fresh earned breakthroughs through Era6')
    check(flow['age']==0,'fresh full flow reincarnated')
    for name in web['screenshots']:
        path=D/name
        check(path.exists() and path.stat().st_size>10000,'screenshot '+name)
    for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md','docs/25-system-content-expansion-plan.md','docs/34-res1-e-46-design.md']:
        check('CONTENT-P2-SUPPLY' in read(ROOT/name).splitlines()[0] and 'DONE' in read(ROOT/name).splitlines()[0],'current closure '+name)
    result={'level':'L3 closure delivery audit','checks':len(checks),'failures':failures,'runners':len(runners),'source_changes':'test size isolation and Danxia supply-version label','runtime_delta':delta,'candidate':str(build.relative_to(ROOT)),'package':compression,'historical_failures_preserved':True}
    (D/'delivery-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'checks':len(checks),'failures':failures,'runners':len(runners)},ensure_ascii=False))
    return bool(failures)

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--archive-generated',action='store_true')
    args=parser.parse_args()
    if args.archive_generated:
        archive()
    else:
        raise SystemExit(audit())
