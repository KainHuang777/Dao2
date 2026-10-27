"""Trim stacked dated closure paragraphs above the real heading of status docs.

Keeps the newest KEEP entries in place; moves older ones verbatim to docs/archive/.
Idempotent: a second run finds nothing more than KEEP entries to move.
"""
from pathlib import Path
import re, sys
ROOT = Path(__file__).resolve().parents[1]
KEEP = 3
# file -> regex of the real document heading line
TARGETS = {
    'README.md': r'^# 修仙問道 v2$',
    'ROADMAP.md': r'^# 修仙問道 v2 .+ Roadmap',
    'docs/ai-handoff.md': r'^# 給下一位 AI 的開發交接',
    'docs/development-status.md': r'^# 開發狀態與交接紀錄',
    'docs/25-system-content-expansion-plan.md': r'^# CONTENT-EXP-PLAN',
}
def main():
    for name, head in TARGETS.items():
        p = ROOT / name
        text = p.read_text(encoding='utf-8-sig')
        lines = text.split('\n')
        idx = next((i for i, l in enumerate(lines) if re.match(head, l.rstrip('\r'))), None)
        if idx is None:
            print('SKIP (heading not found)', name); continue
        prelude = lines[:idx]
        kept_entries = 0; cut = 0
        for i, l in enumerate(prelude):
            if l.strip() and not l.startswith('> 較舊的日期化結案段落'):
                kept_entries += 1
                if kept_entries > KEEP:
                    cut = i; break
        else:
            print('OK nothing to trim', name); continue
        old = '\n'.join(prelude[cut:idx]).strip('\r\n')
        arch = ROOT / 'docs/archive' / (Path(name).stem + '-prelude-archive-2026-10.md')
        arch.parent.mkdir(parents=True, exist_ok=True)
        prev = arch.read_text(encoding='utf-8') if arch.exists() else ''
        arch.write_text(old + '\n\n' + prev, encoding='utf-8')
        base = 'docs/archive/' if '/' not in name else 'archive/'
        pointer = f'> 較舊的日期化結案段落已原文搬至 [{arch.name}]({base}{arch.name})。'
        new = '\n'.join(prelude[:cut]) + '\n' + pointer + '\n\n' + '\n'.join(lines[idx:])
        p.write_text(new, encoding='utf-8')
        print('TRIMMED', name, 'archived chars', len(old))
if __name__ == '__main__':
    main()
