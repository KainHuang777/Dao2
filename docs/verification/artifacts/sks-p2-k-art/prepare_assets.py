"""Package K-art images; no gameplay/code integration. Run from project root."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json
import shutil

ROOT = Path.cwd()
OUT = ROOT / 'docs/verification/artifacts/sks-p2-k-art'
RUNTIME = ROOT / 'assets/ui/skills-painted'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    inputs = json.loads((OUT / 'generation-inputs.json').read_text(encoding='utf-8'))
    skills = json.loads((ROOT / 'docs/design-data/sks-p2-proposal.json').read_text(encoding='utf-8'))['skills']
    assert len(inputs) == len(skills) == 12
    assert set(inputs) == {s['id'] for s in skills}
    assets = []
    preview = Image.new('RGB', (1200, 1230), '#f2ebdb')
    font = ImageFont.truetype('C:/Windows/Fonts/msjh.ttc', 20)
    small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 13)
    draw = ImageDraw.Draw(preview)
    for index, skill in enumerate(skills):
        sid = skill['id']
        source = Path(inputs[sid]['source'])
        original = OUT / 'originals' / (sid + '.png')
        prompt_path = OUT / 'prompts' / (sid + '.txt')
        original.parent.mkdir(parents=True, exist_ok=True)
        prompt_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, original)
        prompt_path.write_text(inputs[sid]['prompt'] + '\n', encoding='utf-8')
        with Image.open(original) as image:
            assert image.format == 'PNG' and image.mode == 'RGBA', sid
            rgba = image.copy()
        alpha = rgba.getchannel('A')
        assert alpha.getextrema() == (0, 255), sid
        bounds = alpha.getbbox()
        assert bounds, sid
        cropped = rgba.crop(bounds)
        cropped.thumbnail((304, 304), Image.Resampling.LANCZOS)
        final = Image.new('RGBA', (336, 336))
        final.alpha_composite(cropped, ((336-cropped.width)//2, (336-cropped.height)//2))
        runtime_bounds = final.getchannel('A').getbbox()
        assert runtime_bounds[0] >= 16 and runtime_bounds[1] >= 16 and runtime_bounds[2] <= 320 and runtime_bounds[3] <= 320, sid
        target = RUNTIME / (sid + '.png')
        assert not target.exists(), 'Do not overwrite ' + str(target)
        final.save(target)
        entry = {
            'id': sid, 'name': skill['name'], 'subject': skill['art_subject'],
            'status': 'GENERATED', 'human_art_acceptance': 'PENDING',
            'runtime_integration': 'OPEN_CODE_OWNED_NOT_CHANGED_BY_THIS_TASK',
            'source': original.relative_to(ROOT).as_posix(),
            'runtime': target.relative_to(ROOT).as_posix(),
            'prompt': prompt_path.relative_to(ROOT).as_posix(),
            'source_size': list(rgba.size), 'runtime_size': [336,336],
            'source_alpha_bounds': list(bounds), 'alpha': True,
            'runtime_alpha_bounds': list(runtime_bounds),
            'source_sha256': sha(original), 'sha256': sha(target),
            'processing': 'Preserve original RGBA; crop complete nonzero alpha bounds, Lanczos fit within 304px, center on transparent 336px canvas with >=16px padding. No repaint, chroma key, baked B outline or shadow.',
        }
        assets.append(entry)
        thumb = final.copy()
        thumb.thumbnail((210, 210), Image.Resampling.LANCZOS)
        x, y = (index%4)*300, (index//4)*410
        preview.paste(thumb, (x+45, y+15), thumb)
        draw.text((x+20,y+242), skill['name'], font=font, fill='#423b30')
        draw.text((x+12,y+277), sid, font=small, fill='#5c5345')
        for n, size in enumerate((112,64)):
            icon = final.resize((size,size), Image.Resampling.LANCZOS)
            preview.paste(icon,(x+25+n*145,y+295),icon)
    manifest = {
        'task': 'SKS-P2/K-art', 'date': '2026-10-24',
        'generation_status': 'COMPLETE', 'human_art_acceptance': 'PENDING',
        'generator': 'built-in ImageGen',
        'source': 'Original AI-generated images; text prompts based on sks-p2-proposal-1. No external image inputs.',
        'license_status': 'Generated for this project; no third-party commercial license asserted.',
        'layers': 'One flattened RGBA object grouping per skill; no layered source. UI text, controls and B edge/shadow remain Godot presentation concerns.',
        'purpose': '12 skill card illustrations for P2-S2. Only resources and delivery metadata produced here; OpenCode owns integration.',
        'assets': assets,
    }
    (RUNTIME/'content-p2-skills-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    preview.save(OUT/'contact-sheet.png')
    baseline = json.loads((OUT/'baseline.json').read_text(encoding='utf-8'))
    changed = [p for p,h in baseline.items() if not (ROOT/p).exists() or sha(ROOT/p) != h]
    audit = {'level':'L1 static asset audit', 'assets':len(assets), 'rgba_png_checks':12, 'padding_checks':12, 'id_matches':12, 'baseline_files':len(baseline), 'baseline_changed':changed, 'failures':[]}
    (OUT/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(audit,ensure_ascii=False))

if __name__ == '__main__':
    main()
