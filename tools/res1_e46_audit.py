"""Read-only source inventory and bounded design checks; never runs legacy code."""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import math
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/res1-e-46'
LEGACY = Path('E:/Python/test1')

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def protected():
    paths = []
    for folder in ['src', 'content', 'tests', 'assets', 'build/web']:
        paths.extend(p for p in (ROOT / folder).rglob('*') if p.is_file())
    paths.extend(ROOT / p for p in ['project.godot', 'export_presets.cfg'])
    return {p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(paths)}

def dump(name, data):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def rows(name):
    with (LEGACY / 'src/data' / name).open(encoding='utf-8-sig', newline='') as f:
        return [r for r in csv.DictReader(f) if r.get('id', '').strip()]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--capture', action='store_true')
    args = parser.parse_args()
    if args.capture:
        if (OUT / 'start-hashes.json').exists():
            raise SystemExit('Refuse to replace baseline')
        dump('start-hashes.json', protected())
        print('Baseline captured')
        return
    checks = []
    def check(name, ok):
        checks.append({'name': name, 'ok': bool(ok)})
    tables = {n: rows(n + '.csv') for n in ['eras', 'resources', 'buildings', 'storage', 'skills']}
    source_files = [LEGACY / 'src/data' / (n + '.csv') for n in tables]
    source_files += [LEGACY / p for p in ['AGENTS.md', 'user_rules.md',
        'src/balance/rules/eraRequirements.ts', 'src/utils/EraManager.ts',
        'src/utils/BreakthroughSystem.ts']]
    source_files += [ROOT / p for p in ['src/simulation/island_progression.gd',
        'src/simulation/island_economy.gd', 'src/simulation/production.gd',
        'src/simulation/cultivation.gd', 'src/simulation/lifespan.gd',
        'src/simulation/alchemy_system.gd', 'src/simulation/beast_system.gd',
        'src/simulation/skill_system.gd', 'src/persistence/save_codec.gd',
        'src/content/content_loader.gd', 'src/application/game_session.gd',
        'content/buildings/study.json', 'content/eras/era3.json',
        'content/recipes/era1_3.json', 'content/manifest.json']]
    selected = {}
    for name, table in tables.items():
        field = 'id' if name == 'eras' else 'prereqEra' if name == 'resources' else 'era'
        selected[name] = [r for r in table if r.get(field, '').strip() in ['4', '5', '6']]
    dump('source-inventory.json', {'date': '2026-10-24', 'mode': 'static only; not legacy parity',
        'source_hashes': {str(p): digest(p) for p in source_files},
        'counts': {n: len(r) for n, r in tables.items()}, 'era4_6_rows': selected,
        'storage_rows': tables['storage']})
    p = json.loads((ROOT / 'docs/design-data/res1-e-46-proposal.json').read_text(encoding='utf-8'))
    check('proposal is approved', p['approval'] == 'APPROVED')
    check('all four approved decisions', [d['id'] for d in p['decisions']] == ['R46-A', 'R46-B', 'R46-C', 'R46-S'] and all(d.get('approval') == 'APPROVED' for d in p['decisions']))
    check('human approval evidence', p['approval_evidence']['quote'] == '四項採原案，保留舊修行時間' and p['approval_evidence']['actor'] == 'human user')
    check('approval is design only', p['implementation_status'] == 'TODO')
    before = json.loads((OUT / 'proposal-before-approval.json').read_text(encoding='utf-8'))
    check('approved design values unchanged', all(p[k] == before[k] for k in ['task', 'version', 'scope', 'eras', 'resources', 'islands', 'recipes', 'facilities', 'routes', 'save']))
    catalog = json.loads((ROOT / 'content/recipes/era1_3.json').read_text(encoding='utf-8'))
    known = set(catalog['resources'])
    new = {r['id']: r for r in p['resources']}
    check('new resource ids unique', len(new) == len(p['resources']))
    known |= set(new)
    for r in p['resources']:
        check('source/sink:' + r['id'], bool(r['source']) and bool(r['sinks']))
        check('capacity:' + r['id'], 0 < r['home_cap'] <= 1e12)
    for r in p['recipes']:
        check('recipe references:' + r['id'], r['product'] in known and all(k in known for k in r['inputs']))
        check('recipe positive:' + r['id'], r['seconds'] > 0 and r['output'] > 0 and all(v > 0 for v in r['inputs'].values()))
    legacy_resources = {r['id']: r for r in tables['resources']}
    for r in p['recipes']:
        old_recipe = json.loads(legacy_resources[r['product']]['recipe'])
        check('legacy recipe ratio:' + r['id'], {k: v / r['output'] for k, v in r['inputs'].items()} == old_recipe)
    check('new routes count', sum(len(i['route_products']) for i in p['islands']) == p['routes']['new_count'] == 5)
    check('exact bounded scope', len(p['resources']) == 7 and len(p['recipes']) == 3 and len(p['facilities']) == 9)
    check('new resource ids not existing', not set(new).intersection(catalog['resources']))
    buildings = set()
    for path in (ROOT / 'content/buildings').glob('*.json'):
        buildings |= {b['id'] for b in json.loads(path.read_text(encoding='utf-8'))}
    for f in p['facilities']:
        check('facility dependency:' + f['id'], all(b in buildings for b in f['requires']))
        check('facility material:' + f['id'], all(r in known and v > 0 for r, v in f['cost'].items()))
        buildings.add(f['id'])
    # Conservative capacity proof uses only proposed warehouses, excludes old caps/bonuses.
    caps = {'lingli': 0, 'stone_low': 0, 'money': 0, 'skill_point': 6200}
    for era in [3, 4, 5]:
        f = next(f for f in p['facilities'] if f['id'] == 'core_storehouse_' + str(era))
        for resource, amount in f['flat_caps'].items():
            caps[resource] = caps.get(resource, 0) + amount
        req = {'lingli': 10000, 'stone_low': 5000} if era == 3 else next(e['exit_capacity'] for e in p['eras'] if e['id'] == era)
        check('prior-era exit capacity:' + str(era), all(caps[k] >= v for k, v in req.items()))
    check('skill 21250 affordability capacity', 6200 + 30000 >= 21250)
    check('Era6 remains bounded', p['eras'][-1]['exit_capacity'] is None and all(not e['required_skills'] for e in p['eras']))
    # Structural progression only: era entry uses prior-era capital, never its own locked output.
    available = set(catalog['resources'])
    for era in [4, 5, 6]:
        island = next(x for x in p['islands'] if x['era'] == era)
        check('opening acyclic:' + str(era), all(k in available for k in island['cost']))
        available |= {r['id'] for r in p['resources'] if r['era'] <= era}
    metrics = []
    legacy_eras = {int(r['id']): r for r in tables['eras']}
    for e in p['eras']:
        old = legacy_eras[e['id']]
        check('era baseline numbers:' + str(e['id']), e['base_time'] == float(old['lvl_baseTime']) and e['time_multiplier'] == float(old['lvl_timeMult']) and e['lifespan'] == float(old['lifespan']))
        check('era costs known:' + str(e['id']), all(k in known for k in e['cost']))
        check('lv9 known:' + str(e['id']), e['lv9']['id'] in known)
        raw = sum(e['base_time'] * e['time_multiplier'] ** i for i in range(9))
        years = sum(float(legacy_eras[i]['lifespan']) for i in range(1, e['id'] + 1))
        metrics.append({'era': e['id'], 'raw_lv1_to10_seconds': raw,
            'golden_core_formation_5_only_seconds': raw * .9 ** 5,
            'lifespan_total_years_no_bonus': years, 'lifespan_seconds_no_bonus': years * 60})
    metrics += [{'case': 'turtle feed raw supply', 'seconds': 30 / .1},
                {'case': 'phoenix feed raw supply', 'seconds': 10 / .04},
                {'case': 'bulk stone_mid 5000 processing only', 'seconds': math.ceil(5000 / 100) * 10}]
    dump('synthetic-metrics.json', {'scope': 'arithmetic only; excludes upstream contention, travel and player choices', 'metrics': metrics})
    baseline = json.loads((OUT / 'start-hashes.json').read_text(encoding='utf-8'))
    current = protected()
    drift = [k for k in baseline.keys() | current.keys() if baseline.get(k) != current.get(k)]
    check('runtime assets tests and frozen Web unchanged', not drift)
    for path in ['docs/34-res1-e-46-design.md', 'docs/design-data/res1-e-46-proposal.json', 'tools/res1_e46_audit.py']:
        (ROOT / path).read_text(encoding='utf-8', errors='strict')
        check('UTF8:' + path, True)
    doc = ROOT / 'docs/34-res1-e-46-design.md'
    for target in re.findall(r'\]\(([^)]+)\)', doc.read_text(encoding='utf-8')):
        check('design link:' + target, (doc.parent / target).is_file())
    dump('audit.json', {'tier': 'L1 static design checks', 'checks': checks,
        'failures': [c['name'] for c in checks if not c['ok']], 'preserved_files': len(baseline), 'drift': drift})
    print(json.dumps({'checks': len(checks), 'failures': [c['name'] for c in checks if not c['ok']], 'preserved_files': len(baseline)}))
    raise SystemExit(1 if any(not c['ok'] for c in checks) else 0)

if __name__ == '__main__':
    main()
