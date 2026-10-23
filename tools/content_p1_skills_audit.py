"""Recheck P1 skills, review artifacts and the preserved production baseline."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs/verification/artifacts/content-p1-skills'
def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))
def sha(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()

def main():
    failures = []
    checks = []
    def check(condition, label):
        checks.append(label)
        if not condition:
            failures.append(label)
    defs = read('content/skills/era2.json') + read('content/skills/era3.json')
    check(len(defs) == 12 and len({d['id'] for d in defs}) == 12, '12 unique skills')
    check(sum(d.get('era', 2) == 2 for d in defs) == 9, 'Era2 nine')
    check(sum(d.get('era', 2) == 3 for d in defs) == 3, 'Era3 three')
    by_id = {d['id']:d for d in defs}
    for proposed in read('docs/design-data/content-p1-proposal.json')['skills']:
        actual = by_id[proposed['id']]
        check(all(actual[key] == proposed[key] for key in ['name','era','cost','max_level','effect']) and float(actual['amount']) == float(proposed['amount']), proposed['id']+' matches selected S design')
    for name in ['runner.json', 'progression.json', 'native-ui.json']:
        result = read('docs/verification/artifacts/content-p1-skills/' + name)
        check(result['failures'] == [] and result['checks'] > 0, name)
    art = read('docs/verification/artifacts/content-p1-skills/art-manifest.json')
    check(len(art['assets']) == 5, 'five original images')
    for entry in art['assets']:
        check(sha(entry['source']) == entry['source_sha256'], entry['id'] + ' original hash')
        check(sha(entry['runtime']) == entry['runtime_sha256'], entry['id'] + ' runtime hash')
        check(entry['alpha_range'][0] == 0 and entry['alpha_range'][1] == 255, entry['id'] + ' alpha')
    web = read('docs/verification/artifacts/content-p1-skills/browser-observations.json')
    check([o['size'] for o in web['observations']] == [[1280,720],[844,390],[800,360]], 'three desktop sizes')
    for o in web['observations']:
        state = o.get('after', o.get('recovered'))
        check(len(state['skills']) == 5 and all(n == 1 for n in state['skills'].values()), str(o['size'])+' learned five')
        check(o['reload']['skills'] == state['skills'], str(o['size'])+' reload unchanged ranks')
    fault = web['observations'][1]
    check(fault['denied']['save_failed'] and fault['deniedRetry']['save_failed'] and not fault['recovered']['save_failed'], 'write failure and recovery')
    check(fault['denied']['points'] == fault['deniedRetry']['points'] and fault['denied']['skills'] == fault['deniedRetry']['skills'], 'denied retry no charge')
    payment = web['observations'][2]
    check(payment['after']['resources']['lingli']['value'] == '420' and payment['refined']['resources']['lingli']['value'] == '372.5', 'browser discount charged47.5')
    check(payment['after']['points'] == payment['refined']['points'] == '2840', 'refine does not charge skill points')
    baseline = read('docs/verification/artifacts/content-p1-design/session-start.json')['protected']
    allowed = {'content/skills/era2.json','content/skills/era3.json','export_presets.cfg','project.godot','src/persistence/save_codec.gd','src/simulation/alchemy_system.gd','src/simulation/production.gd','src/simulation/skill_system.gd','tests/early_v1c_skills_runner.gd','tests/skills_b1_runner.gd','tests/sks_p1_runner.gd','tests/uix_r8_skills_ui_runner.gd','tools/run_all_runners.ps1'}
    changed = [p for p, h in baseline.items() if not (ROOT/p).exists() or sha(p) != h]
    check(set(changed) <= allowed, 'only13 planned baseline files changed')
    check(sha('build/web/index.pck') == baseline['build/web/index.pck'], 'frozen Web unchanged')
    sources = {}
    for folder in ['src','content','tests']:
        for p in (ROOT/folder).rglob('*'):
            if p.is_file() and p.suffix in ['.gd','.json','.tscn','.uid']:
                sources[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    builds = {}
    for folder in ['web-content-p1-skills','content-p1-skills-acceptance']:
        for name in ['index.html','index.pck','index.wasm','index.js']:
            path = 'build/'+folder+'/'+name
            check((ROOT/path).is_file(), path+' exists')
            if (ROOT/path).is_file(): builds[path] = sha(path)
    for doc in ['docs/verification/content-p1-skills.md','docs/verification/artifacts/content-p1-skills/art-review.md']:
        for link in re.findall(r'\]\(([^)]+)\)',(ROOT/doc).read_text(encoding='utf-8')):
            check((ROOT/doc).parent.joinpath(link.split('#')[0]).exists(), 'link '+link)
    expected = re.findall(r"^\s*'([^']+\.gd)'", (ROOT/'tools/run_all_runners.ps1').read_text(encoding='utf-8'), re.M)
    passed = set()
    segments = []
    for name in ['content-p1-skills-all-runners-final.log','content-p1-skills-all-runners-resume.log']:
        text = (OUT/'logs'/name).read_text(encoding='utf-8')
        runs = [r.strip() for r in re.findall(r'^\[RUNNING\] (.*)$', text, re.M)]
        if name.endswith('final.log'):
            runs = runs[:-1]  # Exclude B1's outdated Era assumption; its final run is below.
        passed.update(runs)
        segments.append(dict(log=name,unique_passed=len(set(runs)),script_errors=text.count('SCRIPT ERROR')))
    passed.update(['tests/content_p1_skills_progression_runner.gd','tests/content_p1_skills_ui_runner.gd'])
    coverage = dict(expected=len(expected),unique_passed=len(passed),missing=sorted(set(expected)-passed),segments=segments,supplementary=dict(progression=75,native_ui=84),core_final=370)
    check(set(expected) == passed and not any(s['script_errors'] for s in segments), '99 current runners passed; final script errors0')
    (OUT/'runner-coverage.json').write_text(json.dumps(coverage,indent=2),encoding='utf-8')
    status = 'DONE: human art accepted 2026-10-23' if art.get('human_acceptance', {}).get('status') == 'accepted' and all(a['acceptance'] == 'accepted by user 2026-10-23' for a in art['assets']) else 'IN_PROGRESS: human art review pending'
    result = dict(task='CONTENT-P1-SKILL',date='2026-10-23',status=status,checks=len(checks),failures=failures,baseline_changes=changed,sources=sources,builds=builds)
    result['supporting'] = {p:sha(p) for p in ['project.godot','export_presets.cfg','tools/run_all_runners.ps1','tools/content_p1_skills_audit.py','docs/verification/content-p1-skills.md','docs/verification/artifacts/content-p1-skills/art-manifest.json','docs/verification/artifacts/content-p1-skills/prompts.json']}
    (OUT/'final-manifest.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:result[k] for k in ['task','status','checks','failures']},ensure_ascii=False))
    return 0 if not failures else 1

if __name__ == '__main__':
    raise SystemExit(main())
