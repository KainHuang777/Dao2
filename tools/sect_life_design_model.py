"""Bounded DESIGN calculator; no game execution, save access or asset generation.

Writes reproducible tables only to docs/sect-life/design-v1-tables.md.
"""
from itertools import product
import json
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]


def scores(base, choices, coins, preparation=0):
    return [base + 3 + (4 if i == preparation else 0) +
            (5 if strategy == 'steady' else
             (12 if coins[i] else -4) if strategy == 'advance' else
             (7 if i == preparation else 2))
            for i, strategy in enumerate(choices)]


def rank(player, opponents, tie_orders):
    entries = [player] + opponents
    keys = [(sum(s), min(s), -tie_orders[i]) for i, s in enumerate(entries)]
    ordered = sorted(range(8), key=lambda i: keys[i], reverse=True)
    assert len(set(ordered)) == 8
    return ordered.index(0) + 1


def life_payload():
    """Max-width synthetic field values, not proof of Godot or legacy size."""
    m = 2147483647
    ident = 'x' * 48
    outcomes = {o: {'contribution': 2, 'affinity': {'tx_shen_zhaowei': 4,
                'tx_lu_jingxing': 4, 'tx_tang_xihe': 4}, 'flag': ident}
                for o in ['A', 'B', 'decline']}
    return dict(version=1, content_version=ident, scoring_version=ident,
        life_seq=m, sect_id='taixu_sect', tenure_seconds=m,
        onboarding={k: True for k in ['invite_seen', 'intro_seen', 'first_dispatch',
                    'first_claim', 'skip', 'legacy_review']},
        npcs={k: {'affinity': 100, 'met': True} for k in
              ['tx_shen_zhaowei', 'tx_lu_jingxing', 'tx_tang_xihe']},
        chapter_mask=63, choice_flags={f'chapter_{i}': 'decline' for i in range(6)},
        story_serial=m, pending_story={'id': ident, 'template_id': ident,
            'content_version': ident, 'generated_second': m,
            'epoch': m, 'outcomes': outcomes}, next_story_second=m,
        reward_epoch=m, story_reserved=12,
        rng={'version': 1, 'story': 4294967295, 'tournament': 4294967295},
        edition_cursor=m, next_invite_second=m,
        tournament={'id': ident, 'edition': m, 'era': 12, 'version': ident,
            'roster': [{'id': ident, 'level': 10, 'technique_sum': 10,
                'base': 68, 'tie_order': i, 'offsets': [-2, -2, -2],
                'scores': [99, 99, 99]} for i in range(8)],
            'coins': [1, 1, 1], 'preparation': 2,
            'choices': ['advance'] * 3, 'stage': 3, 'rank': 1,
            'reward': 18, 'reward_claimed': False},
        recent=[{'id': ident, 'template_id': ident, 'option': 'decline',
                 'second': m, 'rank': 8} for _ in range(4)],
        memories={k: 63 for k in ['taixu', 'tianjian', 'piaomiao', 'wanfo', 'zixiao']},
        best_ranks={k: 8 for k in ['taixu', 'tianjian', 'piaomiao', 'wanfo', 'zixiao']})


def main():
    source = (ROOT / 'src/simulation/sect_system.gd').read_text(encoding='utf-8-sig')
    # Fail visibly if this calculator's source assumptions stop matching.
    import re
    common = re.search(r'"common":\s*\{(.*?)\n\s*\}', source, re.S).group(1)
    values = {key: int(re.search(r'"' + key + r'":\s*(\d+)', common).group(1))
              for key in ['duration', 'contrib_min', 'contrib_max']}
    assert values == {'duration': 60, 'contrib_min': 15, 'contrib_max': 30}
    low = 600 // values['duration'] * values['contrib_min']
    mean = 600 / values['duration'] * (values['contrib_min'] + values['contrib_max']) / 2
    rewards = [18, 14, 10, 6, 6, 6, 6, 6]
    assert 12 + max(rewards) <= low * .2
    lines = ['# SECT-LIFE DESIGN v1 試算', '',
        '由 `python tools/sect_life_design_model.py` 產生；設計模型，不是Godot／自然玩法驗收。', '',
        '## 收益（宗齡600秒，按生成epoch）', '',
        '| 項目 | 貢獻 | 對派遣下界／均值 |', '| --- | ---: | --- |',
        f'| 普通派遣下界／均值 | {low}／{mean:g} | 100% |',
        f'| 故事預留上限＋大比第一 | 30 | {30/low:.2%}／{30/mean:.2%} |',
        f'| 故事上限＋假設均勻名次期望 | {12+sum(rewards)/8:g} | '
        f'{(12+sum(rewards)/8)/low:.2%}／{(12+sum(rewards)/8)/mean:.2%} |', '',
        '均勻名次只是敏感度，不是玩家勝率；延後領取可集中現金流。', '',
        '## 評分窮舉', '',
        '固定對手偏移全0；八種進取硬幣、27種策略各一次；準備第1段。',
        '籤序以玩家最末及最先兩種端點重算；表列玩家最末。策略不是隨機操作勝率。', '',
        '| 玩家level／有效功法和 | 總分範圍 | 名次範圍 | 216組名次次數 |',
        '| --- | --- | --- | --- |']
    for level, tech in [(1, 0), (5, 5), (10, 10)]:
        base = 40 + 2 * (level - 1) + min(10, tech)
        opponents = [scores(42 + i * 3, ['steady'] * 3, [0] * 3, i % 3)
                     for i in range(7)]
        counts, totals = Counter(), []
        for choices in product(['steady', 'advance', 'observe'], repeat=3):
            for coins in product([0, 1], repeat=3):
                player = scores(base, choices, coins)
                r = rank(player, opponents, [7, 0, 1, 2, 3, 4, 5, 6])
                assert 1 <= r <= 8
                assert rank(player, opponents, list(range(8))) <= r
                counts[r] += 1
                totals.append(sum(player))
        assert sum(counts.values()) == 216
        lines.append(f'| {level}／{tech} | {min(totals)}～{max(totals)} | '
                     f'{min(counts)}～{max(counts)} | ' +
                     '、'.join(f'{k}名:{v}' for k, v in sorted(counts.items())) + ' |')
    # Equal scores exercise tie order; the public secondary key must matter.
    equal = [[10, 10, 10]] * 7
    assert rank([10, 10, 10], equal, list(range(8))) == 1
    assert rank([10, 10, 10], equal, [7, 0, 1, 2, 3, 4, 5, 6]) == 8
    assert rank([9, 10, 11], equal, list(range(8))) == 8
    lines += ['', '對手偏移敏感度（level5／功法5、全穩健）：', '',
              '| 全部對手每段偏移 | 玩家名次 |', '| --- | ---: |']
    for offset in [-2, 0, 2]:
        opponents = [[x + offset for x in scores(42+i*3, ['steady']*3, [0]*3, i%3)]
                     for i in range(7)]
        lines.append(f'| {offset:+d} | {rank(scores(53, ["steady"]*3, [0]*3), opponents, list(range(8)))} |')
    size = len(json.dumps(life_payload(), ensure_ascii=False, separators=(',', ':')).encode('utf-8'))
    assert size <= 8192
    lines += ['', '## 保存合成樣本', '',
              f'- life寬欄位合成JSON：{size} UTF-8 bytes；預算8192，剩餘{8192-size}。',
              '- 配額22528既有＋8192新增＋2048餘量=32768 bytes。',
              '- 合成樣本不是合法遊戲快照，也不是所有字串／Godot JSON最壞上界證明。',
              '- CORE仍須用現有滿載sect與正式life合併，在Godot量測並驗證遷移／拒寫。', '']
    output = ROOT / 'docs/sect-life/design-v1-tables.md'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text('\n'.join(lines), encoding='utf-8')
    print(f'PASS: source assumptions, economy ceiling, 648 score cases, tie/offset checks; '
          f'synthetic life={size} bytes; {output.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
