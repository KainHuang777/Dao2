"""Build contact sheets/source hashes and check this design's document links."""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/atm-life-design'
report = json.loads((OUT/'browser-checks.json').read_text(encoding='utf-8'))
assert not report['failures']
sources = {
    'assets/abode/sky_tearfall_v1.png': 'Existing read-only sky background; prior provenance retained.',
    'assets/ui/reincarnation-painted/life_lamp_spent.png': 'Ended-life illustration; separate transparent layer.',
    'assets/ui/reincarnation-painted/reincarnation_wheel.png': 'Living/early preview illustration; separate transparent layer.',
    'assets/ui/reincarnation-painted/manifest.json': 'Original ImageGen sources, prompts, alpha processing and license status.',
    'assets/fonts/SourceHanSansTW-VF.ttf': 'Numbers, receipts and controls; existing Sans.',
    'assets/fonts/SourceHanSans-LICENSE.txt': 'Existing Sans license.',
    'assets/fonts/NotoSerifTC-VF.ttf': 'Title 800 / seal 900, existing font.',
    'assets/fonts/NotoSerifTC-LICENSE.txt': 'Existing Serif license.',
    'assets/fonts/reincarnation-f5b/LXGWWenKaiTC-Regular.ttf': 'Biography and closing, existing WenKai.',
    'assets/fonts/reincarnation-f5b/OFL.txt': 'Existing WenKai SIL OFL.',
    'assets/fonts/reincarnation-f5b/README.md': 'Existing download provenance.',
    'docs/verification/artifacts/ui-shell-design/provenance.json': 'Prior background/font reuse provenance.',
}
provenance = {'task': 'ATM-LIFE-DESIGN', 'date': '2026-10-22',
              'new_assets': False, 'new_fonts': False,
              'license': 'Retain existing licenses; no new third-party commercial-rights claim.',
              'text': 'Original fictional copy. No source-game text copied.',
              'layers': 'HTML text and controls separate from existing sky and object illustrations.',
              'sources': [{'path': p, 'purpose': why, 'sha256': hashlib.sha256((ROOT/p).read_bytes()).hexdigest()}
                          for p, why in sources.items()]}
(OUT/'provenance.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
for start in range(0, len(report['screens']), 12):
    batch = report['screens'][start:start+12]
    sheet = Image.new('RGB', (1280, ((len(batch)+2)//3)*226), '#253730')
    draw = ImageDraw.Draw(sheet)
    for i, screen in enumerate(batch):
        thumb = Image.open(OUT/(screen['name']+'.png')).convert('RGB')
        thumb.thumbnail((416, 195))
        x, y = (i%3)*426, (i//3)*226
        sheet.paste(thumb, (x,y+25))
        draw.text((x+4,y+5), screen['name'], fill='white')
    sheet.save(OUT/f'contact-{start//12+1}.jpg', quality=90)

checks = {'utf8_files': 0, 'links': 0, 'errors': []}
for name in ['docs/30-atm-life-design.md', 'docs/verification/atm-life-design.md']:
    path = ROOT/name
    text = path.read_text(encoding='utf-8',errors='strict')
    checks['utf8_files'] += 1
    for target in re.findall(r'\]\(([^)]+)\)', text):
        if '://' in target or target.startswith('#'):
            continue
        checks['links'] += 1
        if not (path.parent/target.split('#')[0]).exists():
            checks['errors'].append({'file':name,'target':target})
(OUT/'document-checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert not checks['errors'], checks
print(json.dumps({'screens':len(report['screens']),'sources':len(sources),'contacts':3,**checks},ensure_ascii=False))
