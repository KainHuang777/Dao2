"""Bounded static proposal audit. Never imports Godot or edits player saves."""
import argparse
import hashlib
import json
import math
import re
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/content-p2-talent-design'
DATA = ROOT / 'docs/design-data/content-p2-talents-proposal.json'


def hashes():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for folder in ('src', 'content', 'assets', 'tests', 'build/web', 'build/web-sks-p2')
            for p in sorted((ROOT / folder).rglob('*')) if p.is_file()}


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--capture-baseline', action='store_true')
    args = parser.parse_args()
    baseline = OUT / 'protected-baseline.json'
    if args.capture_baseline:
        if baseline.exists():
            raise SystemExit('Refusing to overwrite existing baseline')
        write(baseline, hashes())
        print('Captured protected baseline')
        return
    proposal = json.loads(DATA.read_text(encoding='utf-8'))
    checks = []

    def check(name, valid):
        checks.append({'name': name, 'ok': bool(valid)})

    check('approval explicitly recorded', proposal['approval'] == 'APPROVED' and proposal.get('approval_quote') == '採 U')
    check('all U decisions approved', proposal.get('approved_decisions') == ['U1', 'U2', 'U3', 'U-save', 'U-art'])
    check('implementation still TODO', proposal.get('implementation_status') == 'TODO')
    check('art still not generated', proposal['art_proposal']['status'] == 'NOT_GENERATED' and proposal['art_proposal']['acceptance'] == 'PENDING')
    check('runtime not attached', proposal['runtime_attached'] is False)
    items = proposal['talents']
    check('three unique candidates', len(items) == len({x['id'] for x in items}) == 3)
    runtime = (ROOT / 'src/simulation/talent_system.gd').read_text(encoding='utf-8')
    check('runtime version remains 2', 'const VERSION := 2' in runtime)
    check('runtime still six definitions', len(re.findall(r'^\t"[a-z_]+": \{', runtime, re.M)) == 6)
    for item in items:
        check(item['id'] + ' not runtime', item['id'] not in runtime)
        check(item['id'] + ' scope nonempty', bool(item['scope']))
        check(item['id'] + ' fixed gate', item['gate'] == {'reincarnation_count': 1, 'highest_era': 4})
        check(item['id'] + ' cost contract', item['rank_costs'] == [10, 20, 40, 80, 160])
        check(item['id'] + ' max 5', item['max_level'] == 5)
        check(item['id'] + ' cumulative', item['cumulative_costs'] == [10, 30, 70, 150, 310])
    check('pill whitelist', items[0]['scope'] == ['lifespan_pill', 'tribulation_pill'])
    check('local whitelist', items[1]['scope'] == ['deep', 'ancient', 'void'])
    check('beast whitelist', items[2]['scope'] == ['iron_turtle', 'fire_phoenix'])
    supply = json.loads((ROOT / 'content/supply/era4_6.json').read_text(encoding='utf-8'))
    for island in items[1]['scope']:
        check(island + ' defined', island in supply['islands'])
    alchemy = (ROOT / 'src/simulation/alchemy_system.gd').read_text(encoding='utf-8')
    beast = (ROOT / 'src/simulation/beast_system.gd').read_text(encoding='utf-8')
    for key in items[0]['scope']:
        check(key + ' existing', '"' + key + '": {' in alchemy)
    for key in items[2]['scope']:
        check(key + ' existing', '"' + key + '": {' in beast)

    # Decimal discount calculations model Amount intent, not binary float floors.
    discounts = []
    growth = []
    for level in range(6):
        factor = Decimal(1) - Decimal('0.04') * level
        check(f'positive bounded discount {level}', Decimal('.8') <= factor <= 1)
        row = {'rank': level, 'grass_factor': str(factor),
               'lifespan_grass': str(Decimal(25) * factor),
               'tribulation_grass': str(Decimal(3) * factor),
               'batch99_lifespan_grass': str(Decimal(25) * factor * 99)}
        check(f'batch linear {level}', Decimal(row['batch99_lifespan_grass']) == Decimal(row['lifespan_grass']) * 99)
        discounts.append(row)
        for soul in (False, True):
            base = 65 if soul else 50
            xp = base + 10 * level
            feeds = math.ceil(1000 / xp)
            check(f'minimal maturity feeds {level}/{soul}', (feeds - 1) * xp < 1000 <= feeds * xp)
            growth.append({'rank': level, 'soul_growth_30_percent': soul, 'xp': xp,
                           'feeds': feeds, 'first_to_last_seconds': (feeds - 1) * 300,
                           'turtle_iron': feeds * 30, 'turtle_stone': feeds * 100,
                           'phoenix_grass': feeds * 10})

    def g(heart):
        return 1 + .15 * math.log10(heart + 1)

    budgets = []
    for heart in (20, 25, 50, 100, 310):
        options = []
        for a in range(6):
            for b in range(6):
                for c in range(6):
                    costs = [0, 10, 30, 70, 150, 310]
                    spent = costs[a] + costs[b] + costs[c]
                    if spent > heart:
                        continue
                    ratio = g(heart - spent) / g(heart)
                    check(f'budget {heart}/{a}/{b}/{c}', 0 < ratio <= 1)
                    options.append({'ranks': [a, b, c], 'spent': spent, 'remaining': heart-spent,
                                    'home_production_ratio': ratio})
        budgets.append({'initial_dao_heart': heart, 'options': options})
    local = []
    for level in range(6):
        rate = Decimal('.05') * (1 + Decimal('.1') * level)
        seconds = Decimal(30) / rate
        check(f'local rate bounded {level}', Decimal('.05') <= rate <= Decimal('.075'))
        local.append({'rank': level, 'cold_iron_per_second': str(rate),
                      'continuous_30_units_seconds': str(seconds),
                      'quantized_seconds': math.ceil(seconds)})
    now = hashes()
    before = json.loads(baseline.read_text(encoding='utf-8'))
    check('protected file set unchanged', before.keys() == now.keys())
    for path, digest in before.items():
        check('protected ' + path, now.get(path) == digest)
    for relative in ('docs/36-content-p2-talent-design.md', 'docs/verification/content-p2-talent-design.md'):
        path = ROOT / relative
        text = path.read_text(encoding='utf-8', errors='strict')
        check(relative + ' UTF8', '\ufffd' not in text)
        for link in re.findall(r'\]\(([^)]+)\)', text):
            if '://' not in link and not link.startswith('#'):
                check(relative + ' link ' + link, (path.parent / link.split('#')[0]).exists())
    failures = [c['name'] for c in checks if not c['ok']]
    write(OUT / 'analysis.json', {'checks': len(checks), 'failures': failures,
                                'protected_files': len(before), 'discounts': discounts,
                                'growth': growth, 'budgets': budgets, 'local': local,
                                'evidence': 'L1 static proposal math only; not Godot/gameplay evidence'})
    print(json.dumps({'checks': len(checks), 'failures': failures, 'protected_files': len(before)}))
    raise SystemExit(bool(failures))


if __name__ == '__main__':
    main()
