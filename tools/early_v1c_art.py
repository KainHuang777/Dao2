"""Package generated alpha unchanged apart from crop/resize; never paint pixels."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs/verification/artifacts/early-v1-c'
SOURCE = Path('C:/Users/asus/.codex/generated_images/01a159bc-ebd2-78c3-a29d-266f2f61d033/exec-81a14757-3a21-46c3-ad5d-9354711eb6ed.png')

def main():
    original = OUT / 'originals/golden_core_formation.png'
    original.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE, original)
    im = Image.open(original).convert('RGBA')
    bounds = im.getchannel('A').getbbox()
    assert bounds and im.getchannel('A').getextrema() == (0, 255)
    art = im.crop(bounds)
    art.thumbnail((304, 304), Image.Resampling.LANCZOS)
    runtime = Image.new('RGBA', (336, 336))
    runtime.paste(art, ((336-art.width)//2, (336-art.height)//2))
    target = ROOT / 'assets/ui/skills-painted/golden_core_formation.png'
    assert not target.exists(), 'Do not overwrite an existing asset'
    runtime.save(target)
    manifest_path = ROOT / 'assets/ui/skills-painted/manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    entry = next(e for e in manifest['assets'] if e['id'] == 'golden_core_formation')
    entry.pop('runtime_png', None)
    entry.update(status='pending_human_acceptance', task='EARLY-V1-C', date='2026-10-20',
        source=original.relative_to(ROOT).as_posix(), runtime=target.relative_to(ROOT).as_posix(),
        source_size=list(im.size), runtime_size=list(runtime.size), alpha=True,
        source_alpha_bounds=list(bounds),
        processing='Complete alpha bounds fitted into 304px with >=16px padding on 336px canvas; LANCZOS resize only; generated alpha preserved; no painted edits',
        prompt='docs/verification/artifacts/early-v1-c/golden_core_formation-prompt.txt',
        sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
        source_sha256=hashlib.sha256(original.read_bytes()).hexdigest())
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    # Inspection sheets include the final 112px and 80px display sizes on UI paper.
    sheet = Image.new('RGB', (720, 380), '#efe7d1')
    sheet.paste(runtime, (0, 20), runtime)
    for edge, x in [(112, 380), (80, 550)]:
        thumb = runtime.resize((edge, edge), Image.Resampling.LANCZOS)
        sheet.paste(thumb, (x, 130), thumb)
    sheet.save(OUT / 'art-paper-preview.png')
    print(json.dumps(entry, ensure_ascii=False))

if __name__ == '__main__':
    main()
