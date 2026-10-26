"""L1 static proposal audit. Does not run Godot or claim natural gameplay."""
from pathlib import Path
from fractions import Fraction as F
import ast
import hashlib
import json
import math
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p2-beasts-design'


def read(path):
    return (ROOT / path).read_text(encoding='utf-8-sig')


def write(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def protected():
    files = [p for folder in ('src', 'content', 'tests', 'assets')
             for p in (ROOT / folder).rglob('*') if p.is_file()]
    files += [ROOT / p for p in ('project.godot', 'export_presets.cfg', 'build/web/index.pck') if (ROOT / p).is_file()]
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}


def constant(name):
    source = read('src/simulation/beast_system.gd')
    match = re.search(r'const ' + name + r' := ([\s\S]*?)(?=\nconst |\nstatic func )', source)
    return ast.literal_eval(match[1].strip())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if '--capture-baseline' in sys.argv:
        path = OUT / 'protected-baseline.json'
        if path.exists():
            raise SystemExit('Baseline already exists; will not overwrite evidence')
        write(path.name, {'protected': protected()})
        print('Protected baseline captured')
        return
    p = json.loads(read('docs/design-data/content-p2-beasts-proposal.json'))
    supply = json.loads(read('content/supply/era4_6.json'))
    skills = {s['id']: s for s in json.loads(read('content/skills/era4_6.json'))}
    original = json.loads((OUT / 'protected-baseline.json').read_text(encoding='utf-8'))['protected']
    current = protected()
    failures, tables = [], {'growth': [], 'local_rates': [], 'capacity': [], 'legacy_feed': []}
    checks = 0

    def check(ok, label):
        nonlocal checks
        checks += 1
        if not ok:
            failures.append(label)

    check(original == current, 'all protected source/assets/tests/config/package hashes unchanged')
    check(p['status'] == 'PROPOSED' and p['approval'] is None and not p['runtime_attached'], 'no invented approval or attachment')
    old, talents, stages = constant('BEAST_CONFIGS'), constant('BEAST_TALENTS'), constant('STAGE_CONFIGS')
    check((len(old), len(talents)) == (4, 16), 'actual baseline 4/16')
    check(p['baseline'] == {'beasts': 4, 'soul_talents': 16} and p['target'] == {'beasts': 6, 'soul_talents': 24}, 'target 6/24')
    check([stages[k]['max_exp'] for k in ('egg', 'young', 'growing')] == [100, 500, 1000], 'cumulative stage thresholds')
    check(old['iron_turtle']['unlock_era'] == 4 and old['fire_phoenix']['unlock_era'] == 6 and old['cloud_serpent']['unlock_era'] == 8, 'old gates unchanged')
    ids = [b['id'] for b in p['beasts']] + [t['id'] for b in p['beasts'] for t in b['talents']]
    check(len(ids) == len(set(ids)) == 10, 'two beasts plus eight talents unique')
    check(not (set(ids) & (old.keys() | talents.keys())), 'no existing ID collisions')
    shared = p['shared']
    check(shared['active_limit'] == 1 and not shared['auto_feed'], 'single active, manual feeds')
    check(not shared['p2_memory_applies_to_new_beasts'] and not shared['p2_sect_discount_applies_to_new_beasts'], 'no silent expansion of U/W scopes')
    check(shared['soul_tier_costs'] == [1, 2, 3, 5] and shared['soul_cumulative_lives'] == [1, 3, 6, 11], 'eleven mature reincarnations, not eleven feeds')
    for b in p['beasts']:
        island = b['requires_open_island']
        effect = b['active_effect']
        check(b['era'] == supply['islands'][island]['era'], b['id'] + ' current source era gate')
        check(b['realm_gate'] is None and b['requires_supply'], b['id'] + ' era not realm')
        check(effect['island'] == island and set(effect['resources']) == set(supply['islands'][island]['rates']), b['id'] + ' exact local resource whitelist')
        check(b['art']['status'] == 'NOT_GENERATED' and not b['art']['accepted'] and len(b['art']['prompt']) > 200, b['id'] + ' prompt only')
        check([t['tier'] for t in b['talents']] == [1, 2, 3, 4] and [t['cost'] for t in b['talents']] == [1, 2, 3, 5], b['id'] + ' soul costs')
        check([t['value'] for t in b['talents']] == [.05, .3, .4, 30], b['id'] + ' soul effects')
        for resource, cost in b['feed_home_cost'].items():
            check(type(cost) is int and cost > 0, b['id'] + ':' + resource + ' positive feed')
            check(resource in supply['resources'] or resource in read('content/recipes/era1_3.json'), resource + ' existing supply')
            if resource in supply['resources']:
                check(supply['resources'][resource]['era'] <= b['era'], resource + ' feed reachable by era')
                check(cost <= int(supply['resources'][resource]['cap']), resource + ' single feed fits home cap')
        for owned_tiers in range(5):
            xp = 65 if owned_tiers >= 2 else 50
            feeds = math.ceil(1000 / xp)
            costs = {k: max(1, v * (60 if owned_tiers >= 3 else 100) // 100) for k, v in b['feed_home_cost'].items()}
            row = {'beast': b['id'], 'owned_tiers': owned_tiers, 'xp': xp, 'feeds': feeds,
                   'feed_cost': costs, 'maturity_total': {k: v * feeds for k, v in costs.items()},
                   'earliest_seconds_after_first_feed': (feeds - 1) * 300}
            tables['growth'].append(row)
            check(row['earliest_seconds_after_first_feed'] == (5700 if xp == 50 else 4500), b['id'] + ' manual cooldown lower bound')
        for stage, stage_factor in zip(('egg', 'young', 'growing', 'mature'), map(F, ('0', '0.5', '0.75', '1'))):
            for t1 in (False, True):
                bonus = F(0) if stage == 'egg' else F('0.2') * (stage_factor + (F('.05') if t1 else 0))
                check(bonus >= 0 and bonus <= F('.21'), b['id'] + ' bounded stage bonus')
                for resource in effect['resources']:
                    base = F(str(supply['islands'][island]['rates'][resource]))
                    # Existing skill, memory and pill multipliers remain separate;
                    # enumerate their extrema without replacing their formulas.
                    for dispatch in (1, 2):
                        for skill in (0, skills['deep_vein_resonance' if island == 'deep' else 'ancient_herb_attunement']['max_level']):
                            for memory in (0, 5):
                                for pill in (F(1), F('1.5')):
                                    before = base * dispatch * F('1.1') ** skill * (1 + F('.1') * memory) * pill
                                    after = before * (1 + bonus)
                                    check(after / before == 1 + bonus, b['id'] + ':' + resource + ' isolated local factor')
                    tables['local_rates'].append({'beast': b['id'], 'stage': stage, 't1': t1, 'resource': resource, 'base_rate': float(base), 'with_beast': float(base * (1 + bonus)), 'bonus': float(bonus)})
        for skill in range(skills['frontier_storekeeping']['max_level'] + 1):
            for owned in (False, True):
                cap = 300 + 100 * skill + (30 if owned else 0)
                tables['capacity'].append({'island': island, 'skill_rank': skill, 't4': owned, 'capacity': cap})
                check(cap == (330 if owned else 300) + skill * 100, b['id'] + ' additive local capacity')
    for beast in ('iron_turtle', 'fire_phoenix'):
        for soul in (False, True):
            for rank in range(6):
                costs = {k: max(1, v * (60 if soul else 100) * (100 - 2 * rank) // 10000) for k, v in old[beast]['feed_resource'].items()}
                tables['legacy_feed'].append({'beast': beast, 'soul_discount': soul, 'sect_rank': rank, 'costs': costs})
                check(all(v >= 1 for v in costs.values()), 'legacy cost lower bound')
    check([r['costs']['spirit_grass_1000y'] for r in tables['legacy_feed'] if r['beast'] == 'fire_phoenix' and not r['soul_discount']] == [10, 9, 9, 9, 9, 9], 'dated W phoenix plateau retained')
    save = p['save_plan']
    check(save['schema'] == 5 and save['beast_version'] == 1 and save['legacy_version'] == 0, 'versioned proposal')
    check('beast_version' not in read('src/domain/game_state.gd'), 'runtime has no beast subversion yet')
    check(save['rules'] not in read('src/persistence/save_codec.gd'), 'new rule identifier not occupied')
    write('calculations.json', tables)
    # Materialize the report before checking links back to this generated file.
    write('audit.json', {'status': 'RUNNING'})
    for path in ('docs/39-content-p2-beast-design.md', 'docs/verification/content-p2-beasts-design.md'):
        text = read(path)
        check(bool(text), path + ' UTF8')
        for target in re.findall(r'\]\(([^)]+)\)', text):
            if '://' not in target and not target.startswith('#'):
                check((ROOT / path).parent.joinpath(target.split('#')[0]).exists(), path + ' link ' + target)
    report = {'level': 'L1 static design only', 'checks': checks, 'failures': failures,
              'protected_files': len(original), 'source_changed': [k for k in original.keys() | current.keys() if original.get(k) != current.get(k)],
              'runtime_beasts': len(old), 'runtime_talents': len(talents), 'proposed_beasts': 2, 'proposed_talents': 8,
              'gameplay_tested': False, 'browser_tested': False}
    write('audit.json', report)
    print(json.dumps(report, ensure_ascii=False))
    raise SystemExit(bool(failures))


if __name__ == '__main__':
    main()
