"""Bounded static design checks; does not run Godot or alter player fixtures."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p2-pill-design'
PROPOSAL = ROOT / 'docs/design-data/content-p2-pills-proposal.json'


def hashes():
    files = []
    for directory in ('src', 'content', 'assets', 'tests'):
        files.extend(p for p in (ROOT / directory).rglob('*') if p.is_file())
    files.extend(ROOT / p for p in ('project.godot', 'export_presets.cfg'))
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(files)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--capture', action='store_true')
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    baseline = OUT / 'baseline.json'
    if args.capture:
        if baseline.exists():
            raise SystemExit('Refusing to replace initial baseline')
        baseline.write_text(json.dumps(hashes(), indent=2) + '\n', encoding='utf-8')
        print('BASELINE', len(json.loads(baseline.read_text(encoding='utf-8'))))
        return
    checks, failures = [], []

    def check(label, condition):
        checks.append(label)
        if not condition:
            failures.append(label)

    data = json.loads(PROPOSAL.read_text(encoding='utf-8'))
    supply = json.loads((ROOT / 'content/supply/era4_6.json').read_text(encoding='utf-8'))
    alchemy = (ROOT / 'src/simulation/alchemy_system.gd').read_text(encoding='utf-8')
    # Only the top-level PILLS block, before its first static method.
    pill_block = alchemy.split('const PILLS := {', 1)[1].split('static func', 1)[0]
    existing = set(re.findall(r'^\t"([a-z0-9_]+)": \{', pill_block, re.M))
    new_ids = [p['id'] for p in data['pills']]
    check('12 runtime pills remain', len(existing) == 12)
    check('eight unique proposals', len(new_ids) == len(set(new_ids)) == 8)
    check('no runtime attachment', not existing.intersection(new_ids))
    check('20 prospective definitions', len(existing | set(new_ids)) == 20)
    check('all six V groups approved', set(data['approval']) == {'V1', 'V2', 'V3', 'V4', 'V-save', 'V-art'} and all(v == 'APPROVED' for v in data['approval'].values()))
    check('explicit human approval', data.get('approval_record', {}).get('quote') == '採 V')
    check('art acceptance still pending', data['common']['art_acceptance'] == 'PENDING')
    prior = json.loads((OUT / 'approval/proposal-before-approval.json').read_text(encoding='utf-8'))
    metadata = {'approval', 'approval_record', 'status'}
    check('approved rules exactly unchanged', {k: v for k, v in data.items() if k not in metadata} == {k: v for k, v in prior.items() if k not in metadata})
    check('pill version 1 to 2, schema 5 unchanged', data['save']['from'] == 1 and data['save']['to'] == 2 and data['save']['schema'] == 5)
    groups = ('training', 'supply', 'capacity', 'tribulation')
    known_resources = set(supply['resources']) | {'spirit_grass_100y', 'lingli', 'stone_mid', 'money', 'formation_core'}
    for group in groups:
        check('two ' + group, sum(p['group'] == group for p in data['pills']) == 2)
    for p in data['pills']:
        prefix = p['id'] + ':'
        for field in ('name', 'group', 'era', 'cost', 'effect', 'gates', 'art_subject', 'prompt'):
            check(prefix + field, bool(p.get(field)))
        check(prefix + 'v2 original', p['origin'] == 'v2_original')
        check(prefix + 'Era4-6', 4 <= p['era'] <= 6)
        check(prefix + 'positive known inputs', all(k in known_resources and type(v) is int and v > 0 for k, v in p['cost'].items()))
        for key, value in p['cost'].items():
            if key in supply['resources']:
                check(prefix + key + 'available by era', supply['resources'][key]['era'] <= p['era'])
                check(prefix + key + 'single dose fits base home cap', value <= int(supply['resources'][key]['cap']))
        check(prefix + 'no self ingredient', p['id'] not in p['cost'])
        check(prefix + 'art not generated', p['art_status'] == 'NOT_GENERATED')
        check(prefix + 'new discounts opt out', not p['discount_allowlists'])
        if p['group'] == 'supply':
            effect = p['effect']
            island = supply['islands'][effect['island']]
            check(prefix + 'target sourced', effect['resource'] in island['rates'])
            check(prefix + 'source reachable', island['era'] <= p['era'])
            check(prefix + 'positive timed effect', effect['bonus'] == 0.5 and effect['duration'] == 600)
        if p['group'] == 'capacity':
            check(prefix + 'bounded per life', p['effect']['max_per_life'] == 5)
        if p['group'] == 'tribulation':
            check(prefix + 'no unavailable Era7', bool(p['consume_eras']) and all(p['era'] <= era <= 5 for era in p['consume_eras']))
            check(prefix + 'one per attempt', p['effect']['max_per_attempt'] == 1)
    before = json.loads(baseline.read_text(encoding='utf-8'))
    after = hashes()
    changed = [p for p in before if after.get(p) != before[p]]
    added = sorted(set(after) - set(before))
    check('runtime/assets/tests preserved', not changed and not added)
    calculations = {}
    for base in (300, 900, 1800):
        calculations['training_' + str(base)] = {str(n): base * (1 - .85 ** n) / .15 for n in (1, 3, 5, 10, 99)}
    check('900 family total below 6000', calculations['training_900']['99'] < 6000)
    check('1800 family total below 12000', calculations['training_1800']['99'] < 12000)
    probabilities = []
    for era in (4, 5):
        base = max(.3, .8 - .1 * (era - 3))
        for n in (0, 1, 5, 10, 99):
            old = .05 * (1 - .85 ** n) / .15 if era == 4 else 0
            for a in (0, 1):
                for b in (0, 1):
                    raw = base + old + .03 * a + .05 * b
                    probability = min(.95, max(.05, raw))
                    check(f'probability:{era}/{n}/{a}/{b}', .05 <= probability <= .95)
                    probabilities.append({'era': era, 'old_count': n, 'calm': a, 'ward': b, 'p': probability})
    calculations['probabilities'] = probabilities
    calculations['supply'] = {}
    for island, res in (('ancient', 'spirit_grass_1000y'), ('void', 'void_essence')):
        rate = supply['islands'][island]['rates'][res]
        extra = rate * .5 * 600
        calculations['supply'][island] = {'base_rate': rate, 'extra_no_focus': extra, 'extra_focus': extra * 2,
                                         'no_focus_source_seconds': 300,
                                         'full_store_extra': 0}
        check(island + '300 base-source seconds', abs(extra / rate - 300) < 1e-9)
    for doc in ('docs/37-content-p2-pill-design.md', 'docs/verification/content-p2-pill-design.md'):
        text = (ROOT / doc).read_text(encoding='utf-8', errors='strict')
        check(doc + ':utf8', '\ufffd' not in text)
        for target in re.findall(r'\]\(([^)]+)\)', text):
            if '://' in target or target.startswith('#'):
                continue
            check(doc + ':link:' + target, ((ROOT / doc).parent / target.split('#')[0]).exists())
    report = {'level': 'L1_STATIC_ONLY', 'checks': len(checks), 'failures': failures,
              'runtime_file_count': len(before), 'runtime_changed': changed, 'runtime_added': added,
              'calculations': calculations, 'evidence_boundary': 'Static proposal arithmetic, not Godot/Amount/natural-play/Web evidence.'}
    (OUT / 'audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: report[k] for k in ('level', 'checks', 'failures', 'runtime_file_count', 'runtime_changed', 'runtime_added')}, ensure_ascii=False))
    raise SystemExit(bool(failures))


if __name__ == '__main__':
    main()
