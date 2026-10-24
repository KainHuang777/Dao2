"""Static SKS-P2 proposal audit; never loads Godot or writes player data."""
import argparse
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/sks-p2-design'
DATA = ROOT / 'docs/design-data/sks-p2-proposal.json'


def hashes():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for folder in ('src', 'content', 'assets', 'tests', 'build/web')
            for p in sorted((ROOT / folder).rglob('*')) if p.is_file()}


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--capture-baseline', action='store_true')
    args = parser.parse_args()
    baseline = OUT / 'protected-baseline.json'
    if args.capture_baseline:
        if baseline.exists():
            raise SystemExit('Baseline exists; refusing to overwrite')
        write(baseline, hashes())
        print('Captured protected baseline')
        return
    proposal = json.loads(DATA.read_text(encoding='utf-8'))
    supply = json.loads((ROOT / 'content/supply/era4_6.json').read_text(encoding='utf-8'))
    old = sum((json.loads((ROOT / f'content/skills/era{era}.json').read_text(encoding='utf-8'))
               for era in (2, 3)), [])
    checks, failures = [], []

    def check(label, ok):
        checks.append(label)
        if not ok:
            failures.append(label)

    skills = proposal['skills']
    defs = {s['id']: s for s in old + skills}
    ids = [s['id'] for s in skills]
    check('pending approval', proposal['approval'] == 'pending')
    check('12 unique additions / 24 total', len(ids) == len(set(ids)) == 12 and len(defs) == 24)
    check('no collision with P1', not set(ids) & {s['id'] for s in old})
    check('four per era', all(sum(s['era'] == e for s in skills) == 4 for e in (4, 5, 6)))
    check('incubation counted once', ids.count('nascent_soul_incubation') == 1)
    check('no mainline skill gate', all('skills' not in str(e['upgrade_requirements']) for e in supply['eras']))
    rows, totals = [], {}
    study = json.loads((ROOT / 'content/buildings/study.json').read_text(encoding='utf-8'))
    base_point_cap = 200 + sum(b['effects'].get('skill_point_max', 0) for b in study)
    caps = {e: base_point_cap + sum(b['effects'].get('skill_point_max', 0) for b in supply['buildings'] if b['era'] <= e) for e in (4, 5, 6)}
    check('existing study cap source', base_point_cap == 6200)
    check('independent supply cap source', caps == {4: 36200, 5: 86200, 6: 86200})
    capacity_ids = proposal['effect_contracts']['p2_home_capacity_multiplier']['resources']
    check('frozen home capacity IDs', len(capacity_ids) == len(set(capacity_ids)) == 23)
    for s in skills:
        sid, era = s['id'], s['era']
        check(sid + ': integer positive cost/limit', type(s['cost']) is int and s['cost'] > 0 and type(s['max_level']) is int and s['max_level'] > 0)
        check(sid + ': independent capacity', s['cost'] <= caps[era])
        check(sid + ': finite amount', type(s['amount']) in (int, float) and math.isfinite(s['amount']) and s['amount'] > 0)
        check(sid + ': allowed effect', s['effect'] in proposal['effect_contracts'])
        check(sid + ': art subject', bool(s.get('art_subject')))
        req = s.get('requires', {})
        check(sid + ': valid prerequisite', not req or req['skill_id'] in defs and 0 < req['level'] <= defs[req['skill_id']]['max_level'] and defs[req['skill_id']]['era'] <= era)
        seen = {sid}
        cur = req
        while cur and cur['skill_id'] not in seen:
            seen.add(cur['skill_id'])
            cur = defs[cur['skill_id']].get('requires', {})
        check(sid + ': acyclic prerequisites', not cur)
        contract = proposal['effect_contracts'][s['effect']]
        for resource in contract.get('resources', []):
            check(sid + ': resource ' + resource, resource in supply['resources'] or resource in proposal['existing_resources'])
        for recipe in contract.get('recipes', []):
            check(sid + ': recipe ' + recipe, recipe in supply['recipes'])
        island = contract.get('island')
        check(sid + ': island reachable', not island or island in supply['islands'] and supply['islands'][island]['era'] <= era)
        for local in contract.get('islands', []):
            check(sid + ': local capacity ' + local, local in supply['islands'] and supply['islands'][local]['era'] <= era)
        mult = next(e['resource_multiplier'] for e in supply['eras'] if e['id'] == era)
        rates = [mult * level ** 1.5 for level in (1, 2, 3)]
        rows.append({'id': sid, 'era': era, 'cost_each': s['cost'], 'total_cost': s['cost'] * s['max_level'],
                     'independent_cap': caps[era], 'rates_library_1_2_3': rates,
                     'seconds_per_rank_library_1_2_3': [s['cost'] / r for r in rates]})
        totals[era] = totals.get(era, 0) + s['cost'] * s['max_level']
    before, after = json.loads(baseline.read_text(encoding='utf-8')), hashes()
    changed = [p for p in before.keys() | after.keys() if before.get(p) != after.get(p)]
    check('protected files unchanged', not changed)
    scenarios = []
    for e in supply['eras']:
        era = e['id']
        req = e['level_up_requirements']
        raw = sum(req['base_time'] * req['time_multiplier'] ** n for n in range(9))
        time_factor = math.prod(s['amount'] ** s['max_level'] for s in skills if s['effect'] == 'time_multiplier' and s['era'] <= era)
        scenarios.append({'era': era, 'raw_seconds': raw, 'golden5_seconds': raw * .9 ** 5,
                          'golden5_and_available_p2_time_max_seconds': raw * max(.1, .9 ** 5 * time_factor),
                          'p2_time_factor': time_factor,
                          'all_new_skills_cost_this_era': totals[era],
                          'all_new_skills_library3_seconds': totals[era] / (e['resource_multiplier'] * 3 ** 1.5)})
    time_costs = [s for s in skills if s['effect'] == 'time_multiplier']
    time_schedule = []
    for row in scenarios:
        s = next(x for x in time_costs if x['era'] == row['era'])
        rate = next(x for x in rows if x['id'] == s['id'])['rates_library_1_2_3'][2]
        wait = s['cost'] * s['max_level'] / rate
        base = row['golden5_seconds']
        factor = math.prod(x['amount'] ** x['max_level'] for x in time_costs if x['era'] < row['era'])
        reduction = 1 - s['amount'] ** s['max_level']
        # All three ranks bought at era start, prior time skills maxed, no point stock.
        time_schedule.append({'era': row['era'], 'wait_all_three_ranks_seconds': wait,
                              'break_even_remaining_training_seconds': wait / reduction,
                              'training_before_current_skill_seconds': base * factor,
                              'instant_max_saves_seconds': base * factor * reduction})
    capacity = {'incubation_5': 1.15 ** 5, 'advanced_3': 1.1 ** 3,
                'combined_advanced': 1.15 ** 5 * 1.1 ** 3,
                'point_cap_era4_with_incubation5': math.floor(36200 * 1.15 ** 5),
                'point_cap_era5_with_incubation5': math.floor(86200 * 1.15 ** 5)}
    # Every changed Markdown document is checked independently of historic links.
    import re
    docs = ['docs/35-sks-p2-design.md', 'docs/verification/sks-p2-design.md']
    for name in docs:
        path = ROOT / name
        content = path.read_bytes().decode('utf-8', errors='strict')
        check(name + ': no replacement chars', '\ufffd' not in content)
        for target in re.findall(r'\]\(([^)]+)\)', content):
            if '://' not in target and not target.startswith('#'):
                resolved = (path.parent / target.split('#')[0]).resolve()
                check(name + ': link ' + target, resolved.exists() or resolved == (OUT / 'analysis.json').resolve())
    sources = ['content/skills/era2.json', 'content/skills/era3.json', 'content/buildings/study.json',
               'content/supply/era4_6.json', 'src/simulation/skill_system.gd', 'src/simulation/production.gd',
               'src/simulation/island_economy.gd', 'src/simulation/island_progression.gd',
               'src/simulation/cultivation.gd', 'src/persistence/save_codec.gd',
               'docs/21-res1-e-skills-expansion-plan.md', 'docs/25-system-content-expansion-plan.md',
               'docs/34-res1-e-46-design.md', 'docs/decisions/ADR-012-optional-skills-with-islands.md']
    inventory = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}
    legacy = Path('E:/Python/test1/src/data/skills.csv')
    inventory[str(legacy)] = hashlib.sha256(legacy.read_bytes()).hexdigest()
    write(OUT / 'analysis.json', {'task': 'SKS-P2', 'tier': 'L1-static', 'checks': len(checks),
          'failures': failures, 'protected_files': len(before), 'protected_changes': changed,
          'proposal_sha256': hashlib.sha256(DATA.read_bytes()).hexdigest(), 'source_hashes': inventory,
          'skills': rows, 'era_scenarios': scenarios, 'time_investment': time_schedule,
          'capacity_examples': capacity, 'check_labels': checks,
          'evidence_limit': 'Static arithmetic only; no gameplay, Godot runner, art, browser or save migration evidence.'})
    print(json.dumps({'checks': len(checks), 'failures': failures, 'protected_files': len(before),
                      'era_scenarios': scenarios, 'time_investment': time_schedule, 'capacity_examples': capacity}, ensure_ascii=True))
    raise SystemExit(bool(failures))


if __name__ == '__main__':
    main()
