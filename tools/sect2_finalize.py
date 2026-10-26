"""Publish SECT closure metadata only after the evidence audit succeeds."""
import json
from sect2_closure import ROOT, D, read, save


def finalize():
    audit = json.loads(read(D / 'delivery-audit.json'))
    assert not audit['failures'], 'Delivery audit must pass first'
    browser = json.loads(read(D / 'browser-final-18px.json'))
    assert browser['status'] == 'PASS'
    restored = json.loads(read(D / 'restored.json'))
    count = len(restored['changed_archived_restored'])
    summary = (
        '2026-10-26 **CONTENT-P2-SECT DONE（兩圖／卡片／目前節奏已接受；L3／桌面Web有界）**：'
        '129／129唯一runner最終分段通過，原Full exit1與五支補驗exit1保留；供給94項另以單支補驗通過，'
        '原始日誌直接存入專案並封存。最終18px正常候選三橫式、兩法研習、拒寫／再次重試／恢復／重載已驗；'
        f'交付稽核{audit["checks"]}項通過，{count}份測試差異先封存後復原。'
        '兩PNG與規則不變，既有長時WebGL限制保留，未宣稱FPS通過；未玩家進度／commit／push。'
        '見[整批驗收](LINK)。本階段停止；下一大型任務請New Chat指定，不自動開其他P2／P3。下方為日期化歷史。'
    )
    for name in ['README.md', 'ROADMAP.md', 'docs/ai-handoff.md',
                 'docs/development-status.md', 'docs/25-system-content-expansion-plan.md',
                 'docs/38-content-p2-sect-design.md']:
        p = ROOT / name
        link = 'docs/verification/content-p2-sect-closure.md' if '/' not in name else 'verification/content-p2-sect-closure.md'
        p.write_text(summary.replace('LINK', link) + '\n\n' + read(p), encoding='utf-8')
    p = ROOT / 'ROADMAP.md'
    lines = read(p).splitlines()
    for i, line in enumerate(lines):
        if line.startswith('| CONTENT-P2-SECT |'):
            lines[i] = '| CONTENT-P2-SECT | P1與P2供給／技能／天賦／丹藥已收結 | **DONE（2026-10-26，L3／桌面Web有界）**：兩圖／卡片／節奏已接受；8功法／30模板／8商品與保存閘，129支最終分段通過，原失敗保留。最終18px三橫式與保存故障／重載已驗，供給原始日誌補驗封存。[整批驗收](docs/verification/content-p2-sect-closure.md)。 |'
    p.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    p = ROOT / 'docs/design-data/content-p2-sect-proposal.json'
    proposal = json.loads(read(p))
    proposal['status'] = 'DONE_BOUNDED_DESKTOP_L3'
    proposal['art_plan']['status'] = 'GENERATED_INTEGRATED_ACCEPTED'
    proposal['delivery'].update(implementation='DONE', overall='DONE', art='ACCEPTED',
                                verification='docs/verification/content-p2-sect-closure.md')
    proposal['closure'] = dict(date='2026-10-26', unique_runners=129,
        original_full_exit=1, final_supplement_exit=1, supply_complete_exit=0,
        supply_recovered_exit=0, art='ACCEPTED', cards='ACCEPTED', pacing='ACCEPTED',
        scope='L3 bounded desktop Web', final_browser='browser-final-18px.json',
        raw_log_history='Original sandbox completion logs lost; fresh single-run raw logs archived without replacing historical summaries',
        long_idle_webgl='Prior unresolved observation retained; no stability/FPS pass')
    p.write_text(json.dumps(proposal, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    save('closure-decision.json', dict(date='2026-10-26', user_quote='接受現版兩圖、卡片與目前節奏',
        batch='DONE', scope='L3 bounded desktop Web', limitations=proposal['closure']))
    report = ROOT / 'docs/verification/content-p2-sect-closure.md'
    # Earlier evidence stays dated; the current section identifies the authoritative final18px files.
    current = (
        '2026-10-26最終結果：**CONTENT-P2-SECT DONE（L3／桌面Web有界）。** '
        f'交付稽核{audit["checks"]}項／failures=[]；129／129唯一runner最終分段通過。'
        '原Full exit1、五支補驗exit1與1800秒供給逾時永久保留。\n\n'
        '最後兩項已完成：前次1968.2秒供給通過的沙箱raw logs已不存在，搜尋後未找到副本；'
        '未偽造或重建原日誌，改以同來源L2單支3600秒watchdog補驗（承接既有L3收尾），實跑1474.4秒、exit0、94項通過，'
        'stdout／stderr直接寫入專案persistent-temp，再封存至logs。原command與earned-flow結果保留。'
        '本輪沒有重跑Full、Web匯出或重問美術。4支驗收工具語法靜態檢查通過；逐項操作／失敗見final-two-actions.json。\n\n'
        '最終18px正常候選於隔離origin 127.0.0.1:48474實際滑鼠補驗。'
        '1280×720／844×390／800×360 iframe，canvas CSS實測1279×719／843×389／799×359，'
        'backing與目標尺寸一致。兩法標題／成本／效果／44px操作可達、火鳳9→9平台可讀；'
        '615→495首學、第二法拒寫與拒寫重試磁碟仍495／一法一階，恢復後345／兩法一階，'
        '重載保持345／兩法一階。正常時鐘啟用，不宣稱木材精確差額；兩商品故障矩陣沿2026-10-25有效L2證據。'
        '24項瀏覽器稽核、9張原始JPEG截圖／逐項狀態／包hash見browser-final-18px.json與browser-final18-observations.json；'
        '舊final-web-*截圖為16px歷史，不能作18px證據。本輪IAB截圖恢復，沒有使用Windows原生輸入。\n\n'
        f'5955份起點清單，{restored["checked"]}份原檔核對，{count}份測試差異先封存後復原；'
        '接受metadata保持。原始失敗、截圖故障與長時WebGL RangeError留存；長時穩定性／FPS未通過。'
        '未改玩家進度、正式規則、PNG，未commit／push。下方為原始驗收過程與歷史限制。\n\n'
        '![最終18px最短式龜鳳卡](artifacts/content-p2-sect-closure/final18-web-800-plateau.jpg)\n\n'
        '![最終18px最短式玄煉卡](artifacts/content-p2-sect-closure/final18-web-800-qi.jpg)\n\n'
    )
    report.write_text(current + read(report), encoding='utf-8')
    p = ROOT / 'docs/verification/content-p2-sect-ui.md'
    p.write_text('2026-10-26整批更新：兩圖／卡片／節奏已接受，最終18px正常候選與供給原始日誌補驗完成，整批DONE；見[收尾驗收](content-p2-sect-closure.md)。下方為歷史。\n\n' + read(p), encoding='utf-8')
    checkpoint = f'''2026-10-26 CONTENT-P2-SECT DONE — FINAL TWO CLOSURE GATES COMPLETE. STOP / NEW CHAT.
Human art/cards/pacing acceptance remains "接受現版兩圖、卡片與目前節奏". No repeat approval, W/R46/rules/schema/PNG change. 129/129 unique runners pass across the original Full and bounded supplements; original Full exit1 and five-runner supplement exit1 remain historical failures, not a single green Full run. Original supply completion was exit0/1968.2s/94 checks, but its sandbox raw-log folder no longer exists, even under authorized access and a targeted temp search. Repeated ONLY this supply runner with3600s watchdog, isolated-supply-recovered output and project persistent-temp logs; final1474.4s/exit0/94 checks, raw stdout/stderr archived. No Full/export/compression repeated this turn.
IAB screenshots recovered. Final18px candidate unchanged; actual mouse on isolated48474, earned fixture resealed timestamps only (state_equal=true). 1280/844/800 iframe layouts, actual canvas CSS1279x719/843x389/799x359 and exact target backing sizes. Complete short cards, title/cost/effect/44px action and phoenix9->9 plateau verified. Final package transactions615->495; second technique denial and denied retry retained disk495/one rank; recovery345/two rank1; reload retains345/two rank1. New final18-web-* JPEGs and browser-final18-observations.json are authoritative final18px evidence; old final-web-* PNGs remain historical16px. Existing dated L2 two-market fault evidence reused. No browser natural long-run/IndexedDB/FPS claim. Prior WebGL RangeError remains unresolved.
Audit {audit['checks']} checks/failures=[]; {restored['checked']} baseline files verified, {count} generated differences archived/restored. Finalizer corrected anticipated old prose/counts/date and now requires completed audit. Changed verification tooling and closure metadata only this turn; no player progress, runtime rules/art, commit or push. See docs/verification/content-p2-sect-closure.md. STOP; next large task must be user-selected in a New Chat. Do not rerun regression for metadata or start another P2/P3 automatically.

'''
    p = ROOT / 'updata.txt'
    p.write_text(checkpoint + read(p), encoding='utf-8')
    print('FINALIZED', audit['checks'], 'checks;', count, 'differences restored')
