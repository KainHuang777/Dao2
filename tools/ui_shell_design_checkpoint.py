"""Update this design delivery checkpoint and validate documentation links."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/ui-shell-design'
report = json.loads((OUT / 'browser-checks.json').read_text(encoding='utf-8'))
assert not report['failures'] and all(x['passed'] for x in report['interactions'])
head = ('2026-10-21 **UI-SHELL-DESIGN 樣張交付，IN_PROGRESS（待布局／字體選擇）**：'
        '[三橫式候選與圖索引]({link})已交，六類頁面、F-B／F-C同文、長文保存異常／資源抽屜／訊息返回；'
        '隔離Edge三橫式29圖、9項樣張互動／resize檢查通過，非Godot正式UI或保存驗收。'
        '沿既有31份資產／字檔／授權來源，未新增美術或字型；未改GDScript／schema／build／玩家進度，未commit/push。'
        '本機比較工具為docs/visual-prototype/ui-shell-design；驗收見{verification}。'
        '下一New Chat先收布局與F-B／F-C選擇，接受後UI-SHELL-0；未自行展開實作。\n\n')
for name in ['README.md', 'ROADMAP.md', 'docs/ai-handoff.md', 'docs/development-status.md']:
    path = ROOT / name
    old = path.read_text(encoding='utf-8')
    prefix = 'docs/' if '/' not in name else ''
    new = head.format(link=prefix+'29-ui-shell-design-proposal.md',
                      verification=prefix+'verification/ui-shell-design.md')
    assert not old.startswith(new), 'Checkpoint already exists; do not duplicate'
    path.write_text(new+old, encoding='utf-8')
for name in ['docs/07-responsive-ui-web-spec.md', 'docs/19-ui-ux-guidelines.md',
             'docs/27-life-report-and-decision-ux-integration-plan.md',
             'docs/28-unified-ui-shell-and-visibility-plan.md']:
    path = ROOT / name
    old = path.read_text(encoding='utf-8')
    prefix = ('2026-10-21 **UI-SHELL-DESIGN樣張已交，尚待使用者選擇**：'
              '三橫式／六類頁面、F-B／F-C與顯示狀態比較見[docs29](29-ui-shell-design-proposal.md)。'
              '推薦方向仍是候選，正式UI、字型與當前規範未變；沒有美術接受或UI-SHELL-0實作聲稱。\n\n')
    path.write_text(prefix+old, encoding='utf-8')
checkpoint = '''2026-10-21 UI-SHELL-DESIGN DELIVERED; IN_PROGRESS, HUMAN LAYOUT/FONT CHOICE PENDING.
Read docs/29-ui-shell-design-proposal.md and docs/verification/ui-shell-design.md. Deliver six-page HTML design tool (home/buildings/manufacturing/skills/fortune/life) at docs/visual-prototype/ui-shell-design, 29 browser PNGs across 1280x720/844x390/800x360, F-B/F-C same-text comparisons, long text/save-error stress cases, inventory/message overlays, and early/living life previews. Ten candidate title conditions are proposals; only the biographical narrator perspective was already accepted.
Final Edge CDP9251 capture exited 0: 29 screens, 9 mouse/resize assertions, no broken images, undersized buttons, fixed-control overflow or page/horizontal overflow. These are HTML PROPOSAL checks, not Godot rendering/gameplay/persistence/FPS acceptance. Existing Godot version confirmed 4.7.2.stable.official.ed1daf0bf; no import, runners or game export. Three contact sheets and 31 existing source/font/license hashes saved. No new image/font assets, no GDScript/rules/schema/build/player-data changes, no commit/push. Preserve pre-existing dirty research/planning work.
Initial EACCES/ECONNREFUSED and inaccessible sandbox4391 server caused error-page captures and click failure; documented and replaced all captures after adding designState readiness gate and using reachable4392 service. Intermediate home terrain grid overflow and compressed epilogue judgment fixed; tool heading visibility corrected. Failed inline Node quoting replaced with saved diagnose.mjs. Do not treat earlier error screenshots as valid evidence.
Preview server: python tools/ui_shell_design_server.py --port 4392 (localhost only); open http://127.0.0.1:4392/index.html. It serves only proposal HTML and existing asset image/font types. Isolated Edge profile is probes/ui-shell-design-browser, not a player profile. Capture rerun: node --experimental-websocket tools/ui_shell_design_capture.mjs; artifacts: python tools/ui_shell_design_artifacts.py. Server/browser remain for user review.
STOP this design phase. Use NEW CHAT to receive layout and F-B/F-C choice or revisions. Do not mark DONE or change common typography until explicit human acceptance. Once accepted, next UI-SHELL-0 policy/state/canonical restoration audit, then UI-SHELL-1/2; no automatic large implementation in this session. Width-based sample HTML is not the final Godot policy. Existing full route tabs and pending/save/confirmation contracts must be retained and verified during implementation.

'''
path = ROOT / 'updata.txt'
path.write_text(checkpoint+path.read_text(encoding='utf-8'), encoding='utf-8')
proposal = ROOT / 'docs/29-ui-shell-design-proposal.md'
text = proposal.read_text(encoding='utf-8')
sample = '初居山中，築屋修行。其後開拓青木、玄礦兩島，往來漸遠。及至結丹，初居之外，已有數條穿雲而行的路。'
length = len(re.sub(r'[^\u4e00-\u9fff]', '', sample))
text = text.replace('小傳53字', f'小傳{length}字')
text = text.replace('畫框內沒有瀏覽器捲軸', '畫框內沒有瀏覽器頁面捲軸')
text = text.replace('## 候選布局', '樣張僅繪製本輪涵蓋的群組分頁；正式版仍須完整保留canonical分頁、開放門檻與共用未開規則，不依樣張省略正式入口。\n\n## 候選布局')
proposal.write_text(text, encoding='utf-8')
checks = {'utf8_files': 0, 'local_links': 0, 'errors': [], 'sample_chinese_characters': length}
for name in ['README.md', 'ROADMAP.md', 'docs/ai-handoff.md', 'docs/development-status.md',
             'docs/07-responsive-ui-web-spec.md', 'docs/19-ui-ux-guidelines.md',
             'docs/27-life-report-and-decision-ux-integration-plan.md',
             'docs/28-unified-ui-shell-and-visibility-plan.md',
             'docs/29-ui-shell-design-proposal.md', 'docs/verification/ui-shell-design.md', 'updata.txt']:
    path = ROOT / name
    content = path.read_text(encoding='utf-8', errors='strict')
    checks['utf8_files'] += 1
    if name in ['docs/29-ui-shell-design-proposal.md', 'docs/verification/ui-shell-design.md']:
        for link in re.findall(r'\]\(([^)]+)\)', content):
            if re.match(r'^[a-z]+:', link):
                continue
            target = link.split('#')[0]
            if target:
                checks['local_links'] += 1
                if not (path.parent / target).exists():
                    checks['errors'].append(f'{name}: {target}')
assert not checks['errors'], checks
(OUT / 'document-checks.json').write_text(json.dumps(checks, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps(checks, ensure_ascii=False))
