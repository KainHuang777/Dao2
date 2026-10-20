"""Synchronize this delivery checkpoint without rewriting historical records."""
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
summary = ('2026-10-20 **EARLY-V1-C 實作／桌面Web交付，IN_PROGRESS（僅待金丹新圖人工接受）**：'
    '內建ImageGen金丹／青玉丹座透明圖、原稿／prompt／manifest已交；短橫式成功訊息併固定頁首，800完整122px技能卡與44px操作。'
    'Godot4.7.2專項159／SKS-P1 58／B1 41／UI106、輪迴及五項共用panel回歸exit0，原生19 checks／三尺寸六圖通過；'
    '最終Web三橫式真實滑鼠研習、拒寫再試恢復及重載回執不重扣已驗。字型check／候選匯出／壓縮exit0；'
    'build/web-early-v1c，凍結build/web hash7E7E619D…保持。初次訊息高度測試、log路徑／socket／瀏覽器工具失敗及退出診斷詳見驗收。'
    '未改規則／schema／玩家進度，未commit/push。下一New Chat收結丹圖美術回饋，本輪停止。')
for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md']:
    p = ROOT / name
    link = 'verification/early-v1-c.md' if name.startswith('docs/') else 'docs/verification/early-v1-c.md'
    p.write_text(summary + f' [驗收與命令]({link})。\n\n' + p.read_text(encoding='utf-8'), encoding='utf-8')
p = ROOT / 'docs/23-early-version-closure-plan.md'
s = p.read_text(encoding='utf-8').replace('C 仍有金丹圖／桌面 Web 缺口，狀態為 IN_PROGRESS', 'C 已於 2026-10-20 補齊金丹圖、CLI／原生及三橫式桌面 Web，僅待新圖人工美術接受，狀態為 IN_PROGRESS')
s = s.replace('SKS-P1 金丹題材圖與最終 Web／三橫式驗收尚缺；', 'SKS-P1 金丹題材圖與最終 Web／三橫式已交付，僅待新圖人工接受；')
s = s.replace('`EARLY-V1-C` IN_PROGRESS（CLI／Web 匯出與字型已交付；金丹圖、三橫式實研習待補）', '`EARLY-V1-C` IN_PROGRESS（2026-10-20：CLI／原生／三橫式Web實研習與保存恢復已交；僅待新金丹圖人工接受）')
p.write_text(s, encoding='utf-8')
p = ROOT / 'docs/21-res1-e-skills-expansion-plan.md'
s = p.read_text(encoding='utf-8')
s = s.replace('金丹題材圖仍 `pending_art`，三橫式真實瀏覽器研習尚待補', '2026-10-20已補金丹題材圖（`pending_human_acceptance`）、三橫式真實瀏覽器研習／拒寫恢復／重載，僅待新圖人工接受')
s = s.replace('金丹題材圖與Web待補', '金丹題材圖與Web已交，待圖接受').replace('金丹題材圖與桌面Web驗收待補', '金丹題材圖與桌面Web已交，待圖接受')
p.write_text(s, encoding='utf-8')
p = ROOT / 'docs/19-ui-ux-guidelines.md'
p.write_text(p.read_text(encoding='utf-8') + '\n2026-10-20 EARLY-V1-C技能頁驗證修正：短橫式成功／恢復訊息併入固定點數頁首，來源說明留TIP；保存錯誤與重試沿原明確顯示。800×360仍保留完整技能卡與44px動作，沿原共用分頁／黑體／CloseSeal，沒有新增共用視覺樣式。[驗收](verification/early-v1-c.md)。\n', encoding='utf-8')
p = ROOT / 'updata.txt'
checkpoint = '''2026-10-20 EARLY-V1-C CHECKPOINT — IMPLEMENTATION / DESKTOP WEB DELIVERED; HUMAN ART ACCEPTANCE PENDING
Generated original transparent golden-core / celadon-basin art with built-in ImageGen. Runtime PNG, raw source, full prompt, alpha-preserving crop/resize metadata, hashes and provenance are in assets/ui/skills-painted/manifest.json and docs/verification/artifacts/early-v1-c/. Status is pending_human_acceptance; do not infer acceptance from the old R8 six-image approval.
Fixed compact success feedback consuming the skill scroll area: merge successful/recovered status into the fixed points heading and reduce vertical gap to 2px. Errors/retry remain explicit. Final UI runner 106 checks, native 19 checks (six images), core159 / SKS-P1 58 / B1 41, reincarnation plus five shared-panel regressions exited 0. Font check, import, candidate Web export and brotli/BGM preparation exited 0. Retained initial failing layout tests, invalid log-path/socket/tool diagnostics and existing exit leaks in the verification report.
Real IAB mouse interaction on isolated origin 48938: golden_core_formation 0->1 cost7650 once, training240->216; final-build basic_meditation 2->3 at800, 3->4 at844 with denied retry then recovery, 4->5 at1280. Reload preserved five90-point receipts and one7650-point receipt, no new learns. This funded Era3/talisman3 fixture is UI evidence, not natural progression. CLI seven-skill reachability and reincarnation evidence remain separately labelled.
Candidate build/web-early-v1c PCK C24B8098BE761CE4CB4D9B40EB981CB0EA0F959F128B1D8B1FA0F74A9A05D66B. Frozen build/web PCK remains 7E7E619DCAA28FB05E1C397ADCC24CE9071D9B53B4E8FA6379C186E0AF9F9400. No economics/schema/player-save changes, no commit/push, preserve unrelated dirty work.
STOP this phase. In a New Chat, collect human feedback/acceptance for the new golden-core image, then close C if accepted. EARLY-V1-D human pacing remains separate; do not start Era4 or TRIB-C implicitly. Full report and commands: docs/verification/early-v1-c.md.

'''
p.write_text(checkpoint + p.read_text(encoding='utf-8'), encoding='utf-8')
print('EARLY-V1-C checkpoint synchronized; history preserved')
