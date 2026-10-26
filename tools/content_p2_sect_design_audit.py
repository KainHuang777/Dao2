"""Synthetic proposal calculations and source protection; no gameplay claims.

python tools/content_p2_sect_design_audit.py --capture-baseline
python tools/content_p2_sect_design_audit.py
"""
from pathlib import Path
from decimal import Decimal as D, ROUND_CEILING, ROUND_FLOOR
import ast
import hashlib
import itertools
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p2-sect-design'


def read(path):
    return path.read_text(encoding='utf-8-sig')


def write(name, data):
    (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def protected():
    files = [p for folder in ('src', 'content', 'tests', 'assets')
             for p in (ROOT / folder).rglob('*') if p.is_file()]
    files += [ROOT / p for p in ('project.godot', 'export_presets.cfg', 'build/web/index.pck') if (ROOT / p).is_file()]
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}


def constant(path, name):
    source = read(ROOT / path)
    match = re.search(r'const ' + name + r' := ([\s\S]*?)(?=\nconst |\nstatic func )', source)
    if not match:
        raise ValueError(name)
    return ast.literal_eval(match[1].strip())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    baseline = OUT / 'session-start.json'
    if '--capture-baseline' in sys.argv:
        if baseline.exists():
            raise RuntimeError('Refusing to overwrite baseline')
        write('session-start.json', {'date': '2026-10-25', 'protected': protected()})
        print('Captured protected source baseline')
        return
    proposal = json.loads(read(ROOT / 'docs/design-data/content-p2-sect-proposal.json'))
    failures = []
    checks = 0

    def check(ok, label):
        nonlocal checks
        checks += 1
        if not ok:
            failures.append(label)

    before = json.loads(read(baseline))['protected']
    after = protected()
    changed = [k for k in before.keys() | after.keys() if before.get(k) != after.get(k)]
    check(not changed, 'protected sources unchanged')
    sect_path = 'src/simulation/sect_system.gd'
    techs = constant(sect_path, 'TECHNIQUES')
    market = constant(sect_path, 'MARKET_ITEMS')
    old_tasks = constant(sect_path, 'TASK_TEMPLATES')
    p1_tasks = constant(sect_path, 'P1_TASKS')
    rarities = constant(sect_path, 'RARITY_CONFIGS')
    beasts = constant('src/simulation/beast_system.gd', 'BEAST_CONFIGS')
    supply = json.loads(read(ROOT / 'content/supply/era4_6.json'))
    pills = json.loads(read(ROOT / 'docs/design-data/content-p2-pills-proposal.json'))
    check(proposal['status'] == 'PROPOSED' and proposal['approval'] is None, 'no invented approval')
    check((len(techs), sum(map(len, old_tasks.values())) + len(p1_tasks), len(market)) == (6, 20, 6), 'actual runtime baseline 6/20/6')
    check((len(proposal['techniques']), len(proposal['task_templates']), len(proposal['market_items'])) == (2, 10, 2), 'P2 additions 2/10/2')
    ids = [x['id'] for x in proposal['techniques'] + proposal['market_items']] + [x['template_id'] for x in proposal['task_templates']]
    check(len(set(ids)) == 14, 'unique candidate IDs')
    for key in ids:
        check(key not in techs and key not in market and key not in p1_tasks, 'no existing ID collision: ' + key)
    check(proposal['save_plan']['schema'] == 5 and proposal['save_plan']['sect_version'] == 2, 'save version proposal')
    check('const VERSION := 1' in read(ROOT / sect_path), 'runtime sect version remains 1')
    check('core-flow-21-content-p2-pills' in read(ROOT / 'src/persistence/save_codec.gd'), 'current rules identity')
    check(beasts['fire_phoenix']['unlock_era'] == 6, 'phoenix actual Era6 gate')
    tables = {'costs': {}, 'feed': [], 'pill_costs': [], 'eligibility': [], 'probabilities': {}}
    for t in proposal['techniques']:
        check(t['max_level'] == 5 and t['percent_per_level'] == 2, t['id'] + ' ranks')
        cols = {}
        for key, base in t['base_costs'].items():
            vals = [int((D(base) * D('1.5') ** rank).to_integral_value(rounding=ROUND_CEILING)) for rank in range(5)]
            check(vals == t['rank_costs'][key], t['id'] + ':' + key + ' cost series')
            cols[key] = {'ranks': vals, 'sum': sum(vals)}
        tables['costs'][t['id']] = cols
    # Exact rational arithmetic is deliberately independent of runtime floats.
    for beast in ('iron_turtle', 'fire_phoenix'):
        for rank, soul, talent, growth in itertools.product(range(6), (100, 60), range(6), (0, 30)):
            costs = {r: max(1, base * soul * (100 - 2 * rank) // 10000) for r, base in beasts[beast]['feed_resource'].items()}
            xp = 50 * (100 + growth) // 100 + 10 * talent
            feeds = (1000 + xp - 1) // xp
            check(all(1 <= costs[r] <= base * soul // 100 for r, base in beasts[beast]['feed_resource'].items()), 'bounded feeding')
            check(9 <= feeds <= 20, 'finite maturity cost')
            tables['feed'].append({'beast': beast, 'rank': rank, 'soul_percent': soul, 'talent': talent, 'growth': growth, 'xp': xp, 'feeds': feeds, 'costs': costs, 'total': {r: c * feeds for r, c in costs.items()}})
    # Eight P2 pills already exist in runtime, unlike these candidates.
    p2_ids = proposal['techniques'][0]['pill_ids']
    pill_defs = pills['pills']
    if isinstance(pill_defs, dict):
        pill_defs = [dict(v, id=k) for k, v in pill_defs.items()]
    by_id = {x['id']: x for x in pill_defs}
    check(set(p2_ids) == set(by_id), 'explicit eight pill allowlist')
    runtime_pills = constant('src/simulation/alchemy_system.gd', 'PILLS')
    runtime_p2_ids = constant('src/simulation/alchemy_system.gd', 'P2_IDS')
    check(set(p2_ids) == set(runtime_p2_ids), 'actual runtime eight pill IDs')
    for pid in p2_ids:
        check(runtime_pills[pid]['cost'] == by_id[pid]['cost'], 'actual runtime pill costs: ' + pid)
    for pid, rank, count in itertools.product(p2_ids, range(6), (1, 5, 99)):
        definition = by_id[pid]
        base = D(str(definition.get('cost', definition.get('costs', {}))['lingli']))
        per = base * D(100 - 2 * rank) / 100
        check(per > 0 and per * count == base * count * D(100 - 2 * rank) / 100, 'pill batch equivalence')
        tables['pill_costs'].append({'id': pid, 'rank': rank, 'count': count, 'lingli': str(per * count)})
    for t in proposal['task_templates']:
        check(t['rarity'] in rarities and 4 <= t['min_era'] <= 6, 'task rarity/era')
        check(len(t['name'].encode()) <= 128 and len(t['desc'].encode()) <= 1024, 'task text limits')
        check('special_buff' not in t['rewards'], 'no accidental old reward stacking')
        for r, amount in t['rewards'].items():
            check(r in supply['resources'] or r in ('stone_low', 'spirit_grass_100y', 'wood'), 'reachable reward ' + r)
            check(type(amount) is int and 0 < amount <= 1000000, 'bounded reward')
        for island in t['requires_open_islands']:
            check(island in supply['islands'] and supply['islands'][island]['era'] <= t['min_era'], 'reachable island gate')
        b = t['requires_active_beast']
        check(not b or beasts[b]['unlock_era'] <= t['min_era'], 'reachable beast gate')
    # Exhaust all current eras, three island flags, active beast variants.
    for era, flags, beast in itertools.product(range(1, 7), itertools.product((False, True), repeat=3), ('', 'jade_fox', 'iron_turtle', 'fire_phoenix')):
        opened = dict(zip(('deep', 'ancient', 'void'), flags))
        eligible = [t['template_id'] for t in proposal['task_templates'] if era >= t['min_era'] and all(opened[x] for x in t['requires_open_islands']) and (not t['requires_active_beast'] or beast == t['requires_active_beast'])]
        check(era >= 4 or not eligible, 'no premature P2 template')
        check(len(eligible) == len(set(eligible)), 'no duplicate eligible IDs')
        tables['eligibility'].append({'era': era, 'opened': opened, 'active_beast': beast, 'eligible': eligible})
    for rarity, cfg in rarities.items():
        group = [t for t in proposal['task_templates'] if t['rarity'] == rarity]
        check(len(group) == 2 and group[0]['rewards'] != group[1]['rewards'], 'two distinct profiles per rarity')
        # No beast simultaneously satisfies both legendary gates.
        maximum = 1 if rarity == 'legendary' else 2
        denominator = (3 if rarity == 'legendary' else 4) + maximum
        tables['probabilities'][rarity] = {'max_new_eligible': maximum, 'per_new_template_slot_percent': cfg['weight'] / denominator, 'aggregate_new_slot_percent': cfg['weight'] * maximum / denominator}
    for item in proposal['market_items']:
        check(item['limit'] == 10 and item['cost'] > 0, 'lifetime market bounds')
        check(item['grant_resource'] in supply['resources'], 'market existing resource')
        check(supply['islands'][item['requires_open_island']]['era'] <= item['min_era'], 'market source first')
        check(item['grant_amount'] * item['limit'] == (50 if item['grant_resource'] == 'refined_iron' else 20), 'finite total supplement')
    write('calculations.json', tables)
    result = {'date': '2026-10-25', 'level': 'L1_STATIC_DESIGN_ONLY', 'checks': checks, 'failures': failures, 'protected_files': len(before), 'changed_protected': changed, 'runtime': [6, 20, 6], 'candidate_additions': [2, 10, 2], 'attached_new': 0, 'new_gameplay_verified': 0}
    write('audit.json', result)
    documents = ('docs/38-content-p2-sect-design.md', 'docs/verification/content-p2-sect-design.md')
    for name in documents:
        path = ROOT / name
        source = read(path)
        for target in re.findall(r'\]\(([^)]+)\)', source):
            if '://' not in target and not target.startswith('#'):
                check((path.parent / target.split('#')[0]).exists(), 'local link: ' + target)
    result.update(checks=checks, failures=failures)
    write('audit.json', result)
    print(json.dumps(result, ensure_ascii=False))
    if failures:
        sys.exit(1)


if __name__ == '__main__':
    main()
