"""Create design contact sheets and hash existing sources; does not modify source art."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/verification/artifacts/ui-shell-design'
report = json.loads((OUT / 'browser-checks.json').read_text(encoding='utf-8'))
assert len(report['screens']) == 29 and not report['failures']
assert len(report['interactions']) == 9 and all(x['passed'] for x in report['interactions'])
for width, height in [(1280, 720), (844, 390), (800, 360)]:
    names = [s['name'] for s in report['screens'] if s['name'].endswith(f'{width}x{height}')]
    tile_w = 640 if width == 1280 else 422
    tile_h = round(tile_w * height / width)
    sheet = Image.new('RGB', (tile_w * 2, (tile_h + 26) * ((len(names) + 1) // 2)), '#29332e')
    draw = ImageDraw.Draw(sheet)
    for i, name in enumerate(names):
        with Image.open(OUT / f'{name}.png') as im:
            assert im.size == (width, height), (name, im.size)
            x, y = i % 2 * tile_w, i // 2 * (tile_h + 26)
            sheet.paste(im.convert('RGB').resize((tile_w, tile_h)), (x, y + 26))
            draw.text((x + 8, y + 6), name, fill='#f3e6cb')
    sheet.save(OUT / f'overview-{width}.jpg', quality=91)

used = [
    'assets/abode/sky_tearfall_v1.png', 'assets/abode/terrain.png',
    'assets/abode/island1/courtyard.png',
    'assets/fonts/SourceHanSansTW-VF.ttf', 'assets/fonts/NotoSerifTC-VF.ttf',
    'assets/fonts/reincarnation-f5b/LXGWWenKaiTC-Regular.ttf',
    'assets/fonts/SourceHanSans-LICENSE.txt', 'assets/fonts/NotoSerifTC-LICENSE.txt',
    'assets/fonts/reincarnation-f5b/OFL.txt',
]
for directory, names in {
    'buildings-painted': ['courtyard', 'foundation_reservoir', 'scripture_hall', 'herb_farm', 'forest_farm'],
    'resources-painted': ['lingli', 'wood', 'stone_low', 'spirit_grass_low', 'bronze_essence', 'spirit_timber', 'liquid'],
    'skills-painted': ['golden_core_formation', 'basic_meditation', 'foundation_building'],
    'reincarnation-painted': ['life_lamp_spent'], 'fortune-painted': ['traveler']
}.items():
    used.extend(f'assets/ui/{directory}/{name}.png' for name in names)
    manifest = ROOT / f'assets/ui/{directory}/manifest.json'
    if manifest.exists():
        used.append(manifest.relative_to(ROOT).as_posix())
sources = []
for name in sorted(set(used)):
    path = ROOT / name
    sources.append({'path': name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
provenance = {
    'date': '2026-10-21', 'task': 'UI-SHELL-DESIGN',
    'new_graphic_assets': False, 'new_font_files': False,
    'use': 'Existing local assets referenced read-only for design comparison; no asset pixels changed.',
    'layers': 'Background, island and residence are separate HTML preview image layers, not a finished Godot world.',
    'license': 'Retain existing source manifests/prompts/licenses; no new third-party commercial-rights claim.',
    'text': 'Original fictional design fixture; not player history or runtime rules.',
    'sources': sources,
    'browser_result': {'screens': 29, 'interactions': 9, 'failures': 0},
}
(OUT / 'provenance.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'screens': 29, 'interactions': 9, 'failures': 0, 'sources': len(sources), 'contact_sheets': 3}))
