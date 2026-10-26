"""Audit recorded final18px desktop observations; never drives game state."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
D = ROOT / 'docs/verification/artifacts/content-p2-sect-closure'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


observations = json.loads((D / 'browser-final18-observations.json').read_text(encoding='utf-8'))
by = {row['label']: row for row in observations}
checks = []


def check(value, label):
    assert value, label
    checks.append(label)


both = {'p2_pill_qi_conservation': 1, 'sacred_beast_feed_conservation': 1}
for label in ['final18-web-1280-first', 'final18-web-1280-refused', 'final18-web-1280-retry-refused']:
    sect = by[label]['state']['sect']
    check(sect['contribution'] == '495' and sect['techniques'] == {'p2_pill_qi_conservation': 1}, label + ' disk unchanged at495/one rank')
for label in ['final18-web-1280-recovered', 'final18-web-1280-reloaded', 'final18-web-1280-cards']:
    sect = by[label]['state']['sect']
    check(sect['contribution'] == '345' and sect['techniques'] == both, label + ' disk345/two rank1')
for label, width, height in [('final18-web-1280-cards', 1280, 720),
                             ('final18-web-844-plateau', 844, 390),
                             ('final18-web-800-plateau', 800, 360),
                             ('final18-web-800-qi', 800, 360)]:
    metrics = by[label]['metrics']
    canvas = metrics['canvas']
    check([canvas['width'], canvas['height']] == [width, height], label + ' backing')
    check([canvas['rect']['width'], canvas['rect']['height']] == [width - 1, height - 1], label + ' actual CSS')
screenshots = {}
for row in observations:
    p = D / (row['label'] + '.jpg')
    check(p.is_file() and p.read_bytes().startswith(bytes.fromhex('ffd8ff')), row['label'] + ' screenshot exists')
    screenshots[p.name] = digest(p)
console = json.loads((D / 'browser-final18-console.json').read_text(encoding='utf-8'))
check(console == [], 'observed final tab warn/error window empty (bounded only)')
result = dict(status='PASS', date='2026-10-26', origin='http://127.0.0.1:48474',
    checks=checks, screenshots=screenshots,
    pck_sha256=digest(ROOT / 'build/web-content-p2-sect/index.pck'),
    observations_sha256=digest(D / 'browser-final18-observations.json'),
    source='Final18px candidate from title-final export; unchanged runtime sources audited by delivery audit',
    visual_review=['1280 both full cards and actions visible before learning and after reload',
                   '844 full turtle/phoenix card with18px title/cost/effect/action visible',
                   '800 each P2 card can be scrolled fully into its reading area; no clipped action',
                   'Phoenix9->9 plateau and second-to-fifth-rank same grass cost visible',
                   'Save refusal/retry protection and recovered result visible; actual mouse used'],
    limitations=['No FPS/long-idle/IndexedDB claim',
                 'Market fault matrix reuses2026-10-25 unchanged-code L2 evidence',
                 'Old final-web-* images are historical16px and are not final18px proof'])
(D / 'browser-final-18px.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('FINAL18 BROWSER AUDIT PASS', len(checks), 'checks;', len(screenshots), 'screenshots')
