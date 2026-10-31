"""Offline DESIGN arithmetic; never imports Godot or reads/writes player saves.

python tools/sect_reform_design_model.py --write  # regenerate reviewable annex
python tools/sect_reform_design_model.py --check  # compare annex, read-only
This is a bounded scenario model, not a natural-play simulation or runtime rule.
"""
import argparse
from decimal import Decimal, ROUND_CEILING
from fractions import Fraction as F
import json
import math
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'docs/sect-reform/design-v1-tables.md'


def cost(base, levels=5, scale='1.5'):
    return [int((Decimal(base) * Decimal(scale) ** n).to_integral_value(
        rounding=ROUND_CEILING)) for n in range(levels)]


def row(*values):
    return '| ' + ' | '.join(map(str, values)) + ' |'


def pct(value):
    return f'{float(value) * 100:.6f}%'


def render():
    lines = ['# 宗門改版 DESIGN 算表（數值模型v1／獸種修訂2，自動產生）', '',
             '由 [離線模型](../../tools/sect_reform_design_model.py) 產生；規則與前提見 '
             '[設計規格](../47-sect-reform-numeric-design.md)。這是候選數值的解析比較，非遊戲測試證據。', '',
             '## 1. 八項舊功法與兩組新功法成本', '',
             row('功法／組別', '各階貢獻', '貢獻合計', '各階材料', '材料合計'),
             row('---', '---', '---:', '---', '---:')]
    old = [('divine_farm', 50, 100, '木', 10, '1.5'),
           ('breathing_method', 80, 5, '下石', 10, '1.6'),
           ('storage_talisman', 60, 200, '木', 10, '1.5'),
           ('essence_array', 100, 30, '下石', 10, '1.5'),
           ('alchemy_herb_conservation', 60, 5, '下石', 5, '1.5'),
           ('fox_feed_conservation', 90, 100, '木', 5, '1.5'),
           ('p2_pill_qi_conservation', 120, 10, '下石', 5, '1.5'),
           ('sacred_beast_feed_conservation', 150, 200, '木', 5, '1.5'),
           ('各宗基礎專法 A', 80, 5, '下石', 5, '1.5'),
           ('各宗進階專法 B', 120, 10, '下石', 5, '1.5')]
    # Guard the eight copied legacy inputs against current source definitions.
    source = (ROOT / 'src/simulation/sect_system.gd').read_text(encoding='utf-8-sig')
    techniques = source.split('const TECHNIQUES := {', 1)[1].split('const MARKET_ITEMS', 1)[0]
    for name, contribution, material, unit, levels, scale in old[:8]:
        block = re.search(r'"' + re.escape(name) + r'":\s*\{([^}]+)\}', techniques).group(1)
        fields = dict(re.findall(r'"(\w+)":\s*([\d.]+)', block))
        assert int(fields['base_contrib']) == contribution, name
        assert int(fields['base_wood' if unit == '木' else 'base_stone_low']) == material, name
        assert int(fields['max_level']) == levels and Decimal(fields['cost_scale']) == Decimal(scale), name
    for name, contribution, material, unit, levels, scale in old:
        a, b = cost(contribution, levels, scale), cost(material, levels, scale)
        lines.append(row(name, '/'.join(map(str, a)), sum(a),
                         '/'.join(map(str, b)) + unit, sum(b)))
    assert sum(cost(80)) == 1055 and sum(cost(120)) == 1583
    assert sum(cost(5)) == 68 and sum(cost(10)) == 133
    lines += ['', '## 2. 五宗比較：固定同底盤、無既有加成的解析樣本', '',
              'Era>=5的滿階樣本；A/B各五階；天賦T=0或3階；守護獸G=成熟、無獸魂天賦。'
              '同軸新加成相加；加工速率取ceil(基礎秒數／倍率)。樣本沒有運輸／缺料／庫滿等待。', '',
              row('方案', '無選修', 'A/B滿階', '再加T3', '再加同宗G'),
              row('---', '---:', '---:', '---:', '---:')]
    lines.append(row('太虛：600修煉秒所需實秒', 600,
                     f'{600/1.10:.3f}', f'{600/1.16:.3f}', f'{600/1.20:.3f}'))
    lines.append(row('太虛：基礎100靈力/s', 100, 115, 115, 115))
    lines.append(row('天劍：礦採集100單位/s', 100, 120, 126, 134))
    lines.append(row('天劍：銅精10秒一批', 10,
                     math.ceil(10/1.15), math.ceil(10/1.15), math.ceil(10/1.15)))
    lines.append(row('縹緲：草採集100單位/s', 100, 120, 126, 134))
    lines.append(row('縹緲：白名單丹草100單位', 100, 90, 90, 90))
    base_years = 0
    eras = []
    for era in (1, 2, 3):
        eras += json.loads((ROOT / f'content/eras/era{era}.json').read_text(encoding='utf-8-sig'))
    eras += json.loads((ROOT / 'content/supply/era4_6.json').read_text(encoding='utf-8-sig'))['eras']
    lifespan_rows = []
    for e in eras:
        base_years += e['lifespan']
        era = e['id']
        a = 0 if era < 2 else 3 if era < 4 else 5
        b = 0 if era < 3 else 3 if era < 5 else 5
        t = 6 if era >= 2 else 0
        g = 4 if era >= 3 else 0
        # Apply actual current-era activation before the shared lifespan floor.
        lifespan_rows.append(row(era, base_years, f'A{a}/B{b}',
                                 base_years*(100+2*b)//100+2*a,
                                 base_years*(100+2*b+t)//100+2*a,
                                 base_years*(100+2*b+t+g)//100+2*a))
    lines.append(row('萬佛：Era6壽元上限（年）', base_years, base_years*110//100+10,
                     base_years*116//100+10, base_years*120//100+10))
    lines.append(row('紫霄：靈力容量1000', 1000, 1200, 1260, 1340))
    lines.append(row('紫霄：白名單材料容量1000', 1000, 1200, 1200, 1200))
    lines += ['', '## 3. 壽元逐Era（固定停留該境界、無其他壽元加成）', '',
              row('Era', '無選修年數', '當世A/B啟用階', '萬佛專法', '再加T3', '再加G'),
              row('---:', '---:', '---', '---:', '---:', '---:')] + lifespan_rows
    lines += ['', '1年=60實秒；這是從當世開始累積的上限，不能當成升境後剩餘時間。', '',
              '## 4. 發現與同宗權重（每一新生成候選槽）', '',
              row('Era／池數n', '任意發現', '指定同宗新獸', '指定非同宗項', '12個未篩選候選槽至少一次任意發現'),
              row('---', '---:', '---:', '---:', '---:')]
    rarity = [F(40,100), F(30,100), F(18,100), F(10,100), F(2,100)]
    duration = [60,120,300,600,900]
    contribution = [F(45,2),45,90,185,450]
    configs = source.split('const RARITY_CONFIGS := {',1)[1].split('const TASK_TEMPLATES',1)[0]
    for i, key in enumerate(['common','uncommon','rare','epic','legendary']):
        block = re.search(r'"'+key+r'":\s*\{([^}]+)\}', configs).group(1)
        fields = dict(re.findall(r'"(\w+)":\s*([\d.]+)', block))
        assert F(int(fields['weight']),100) == rarity[i]
        assert int(fields['duration']) == duration[i]
        assert F(int(fields['contrib_min'])+int(fields['contrib_max']),2) == contribution[i]
    event = F(10,100)*F(10,100) + F(2,100)*F(20,100)
    assert event == F(7,500)
    assert sum(rarity) == 1 and 1-(1-event)**3 == F(5176843,125000000)
    assert F(3,3) == 1  # One eligible affinity target: weighting cannot improve 100%.
    for era, n in [(3,5),(4,7),(5,8),(6,9),(8,10)]:
        assert F(3,n+2) + (n-1)*F(1,n+2) == 1
        lines.append(row(f'{era} / {n}', pct(event), pct(event*F(3,n+2)),
                         pct(event*F(1,n+2)), pct(1-(1-event)**12)))
    lines += ['', 'Era8只為池邊界，非本輪正常可達聲稱；滿池要求各必要島已開。'
              '持有資格仍占原池、重複轉信物，故權重分母不因藏品數改變。', '',
              '## 5. 委託與保底時間界線', '',
              f'- 單槽平均貢獻={float(sum(p*c for p,c in zip(rarity,contribution))):.1f}；'
              f'平均派遣={float(sum(p*d for p,d in zip(rarity,duration))):.0f}秒。這是抽樣合成比值，非三選一政策的速率。',
              '- 從0信物，12次合資格領取（每次保底1）可兌換任一當前合資格項；不要求抽到史詩。',
              f'- 無操作延遲的保守上界：12×(900派遣+300刷新)={12*(900+300)}秒=4小時；'
              '假設持續派遣／領取／刷新且未壽盡。不構成真實時間SLA。',
              '- 無同種天賦的五新獸（各自）：每餵50XP、滿1000XP需20餵；首餵即刻，19×300=5700秒=95分鐘；共1000低階草。',
              f'- 若只靠隨機，指定同宗新獸Era3平均候選槽數={float(1/(event*F(3,7))):.3f}；'
              '沒有有限最壞值，故正式保證只用信物。', '',
              '## 6. 跨世道心機會成本', '',
              row('同宗有效世數', '可購天賦階', '當階道心', '累計道心', '築基輪迴最低累計收入', '最低收入扣購後'),
              row('---:', '---:', '---:', '---:', '---:', '---:')]
    for lives, rank, price, spent in [(1,1,5,5),(3,2,10,15),(5,3,20,35)]:
        lines.append(row(lives,rank,price,spent,lives*15,lives*15-spent))
    lines += ['', '成就無道心獎勵；表中假設每世符合築基15道心保底且沒有其他支出。',
              f'首世15道心買5後，道心持有產率加數由{0.15*math.log10(16):.6f}'
              f'降為{0.15*math.log10(11):.6f}，少{0.15*math.log10(16/11)*100:.4f}個百分點。'
              '專精天賦不是無代價全面增益。', '',
              '## 7. 已有加成／取整／運輸瓶頸敏感度', '',
              '- 已有修速+100%時，太虛A5的600秒工作由300→285.714秒（省4.762%），不是再快10%。',
              '- 天劍A5/B5若供料30秒、加工10秒，瓶頸變成25秒／9秒；每批節省5秒。'
              '若運輸40秒／批，兩者都仍40秒，實際吞吐增益0。',
              '- 縹緲草費100：已有丹材宿慧20%則80→72；四丹舊共通10%則90→81；'
              '兩個舊白名單互斥，不製造不存在的0.9×0.8×0.9案例。',
              '- 天劍B每階3%：10秒配方L0..5='+ '/'.join(str(math.ceil(F(10)/(1+F(3*i,100)))) for i in range(6)) +
              '秒；部分階沒有此配方的當次收益。',
              '- 太虛／天劍／縹緲庫滿時產量邊際收益0；紫霄只有庫容瓶頸時受益；'
              '萬佛只延後壽盡，不加速到金丹。沒有把不同物料換成共同貨幣。', '']
    lines += ['## 8. 五獨立新獸的養成與魂樹成本', '',
              '物種方向已核定；以下名字、相同起步成本與四階細節仍為提案。各物種獨立魂池，沒有跨獸付款或全域XP加成。', '',
              row('beast_id', '各自魂樹節點', '各自滿樹魂費', '初次成熟草／冷卻秒', '同種滿樹成熟草／冷卻秒'),
              row('---', '---:', '---:', '---', '---')]
    species = ['taixu_baize', 'tianjian_suanni', 'piaomiao_jade_hare',
               'wanfo_lotus_elephant', 'zixiao_star_tapir']
    assert len(set(species)) == 5
    for beast in species:
        plain_feeds = math.ceil(1000/50)
        trained_feeds = math.ceil(1000/75)
        lines.append(row(beast, 4, sum([1,2,3,5]),
                         f'{plain_feeds*50} / {(plain_feeds-1)*300}',
                         f'{trained_feeds*30} / {(trained_feeds-1)*300}'))
    lines += ['', '- 五種新增天賦合計20節點；各11同種魂，五樹共55魂。每世只有實際成熟的一獸結1枚同種魂，故五樹全滿至少55次成熟輪迴。',
              '- 初次成熟20餵、95分鐘；各自滿樹14餵、65分鐘。別種天賦滿階不降低本種成本。',
              '- 原六獸保留，總物種11；抽選資格池最大仍10（五新獸＋五原獸，免費靈狐排除），因此本次物種更換不改1.4%／3:1／12信物算術。', '']
    return '\n'.join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--check', action='store_true')
    args = ap.parse_args()
    expected = render()
    if args.write:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(expected, encoding='utf-8')
        print('WROTE docs/sect-reform/design-v1-tables.md')
    else:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding='utf-8') != expected:
            raise SystemExit('FAIL: design annex stale; review inputs and use --write')
        print('PASS: cost, lifespan, probability, guarantee and opportunity-cost annex matches model')


if __name__ == '__main__':
    main()
