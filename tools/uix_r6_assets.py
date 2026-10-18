"""Import UIX-R6 ImageGen outputs without changing the generated alpha.
Run after generation-records.json is complete. No image synthesis or chroma key.
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, shutil, hashlib
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs/verification/artifacts/uix-r6'
RUNTIME = ROOT / 'assets/ui/achievements-painted'
def main():
    records = json.loads((OUT / 'generation-records.json').read_text(encoding='utf-8-sig'))
    RUNTIME.mkdir(parents=True, exist_ok=True)
    (OUT / 'originals').mkdir(exist_ok=True)
    (OUT / 'prompts').mkdir(exist_ok=True)
    manifest = {'task':'UIX-R6-ACHIEVEMENTS', 'date':'2026-10-16 to 2026-10-17', 'generator':'built-in ImageGen',
        'source':'AI-generated original assets; no external reference image used',
        'license_status':'Generated for this project; no third-party commercial license asserted',
        'layers':'One generated RGBA badge per achievement. UI text, state, rewards and interaction remain Godot Controls.',
        'assets':[]}
    sheet = Image.new('RGB', (6*200,3*220), '#efe7d2')
    draw = ImageDraw.Draw(sheet)
    for i, record in enumerate(records):
        ident = record['id']
        source = Path(record['generated_path'])
        original = OUT / 'originals' / (ident+'.png')
        shutil.copy2(source, original)
        (OUT / 'prompts' / (ident+'.txt')).write_text(record['prompt']+'\n', encoding='utf-8')
        image = Image.open(original).convert('RGBA')
        alpha = image.getchannel('A')
        assert alpha.getextrema() == (0,255), f'{ident}: missing transparent alpha'
        bbox = alpha.getbbox()
        assert bbox is not None
        # Fit complete generated bounds into a padded square; never remove alpha.
        fitted = ImageOps.contain(image.crop(bbox), (200,200), Image.Resampling.LANCZOS)
        runtime = Image.new('RGBA', (224,224))
        runtime.alpha_composite(fitted, ((224-fitted.width)//2,(224-fitted.height)//2))
        path = RUNTIME / (ident+'.png')
        runtime.save(path, optimize=True)
        preview = runtime.resize((160,160), Image.Resampling.LANCZOS)
        x,y = (i%6)*200,(i//6)*220
        sheet.paste(preview,(x+20,y+8),preview)
        draw.text((x+6,y+180), ident, fill='#343c3d')
        # Actual 72px target-size QC strip beside label.
        manifest['assets'].append({'asset_id':'achievement_'+ident,'achievement_id':ident,'category':record['category'],
            'purpose':'72px achievement card badge; category representative reused at 24px',
            'source':original.relative_to(ROOT).as_posix(),'runtime':path.relative_to(ROOT).as_posix(),
            'source_size':list(image.size),'runtime_size':[224,224],'alpha':'preserved generated RGBA',
            'processing':'alpha bounding-box fit to 200px in 224px transparent square; no painted pixels or state variants',
            'prompt':(OUT/'prompts'/(ident+'.txt')).relative_to(ROOT).as_posix(),
            'runtime_sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    sheet.save(OUT/'badge-contact-sheet.jpg',quality=94)
    target = Image.new('RGB',(6*144,3*112),'#efe7d2')
    td = ImageDraw.Draw(target)
    for i,rec in enumerate(records):
        im=Image.open(RUNTIME/(rec['id']+'.png')).convert('RGBA').resize((72,72),Image.Resampling.LANCZOS)
        x,y=(i%6)*144,(i//6)*112
        target.paste(im,(x+36,y),im)
        td.text((x+3,y+78),rec['id'],fill='#343c3d')
    target.save(OUT/'badge-target-72px.jpg',quality=95)
    (RUNTIME/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'PASS: {len(records)} unique alpha badges imported with original prompts and hashes')
if __name__=='__main__': main()
