"""Preserve original generated alpha and fit runtime icons without repainting."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, shutil, hashlib
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'docs/verification/artifacts/uix-r8'
RUNTIME = ROOT/'assets/ui/skills-painted'
def main():
    records = json.loads((OUT/'generation-records.json').read_text(encoding='utf-8-sig'))
    RUNTIME.mkdir(exist_ok=True, parents=True)
    (OUT/'originals').mkdir(exist_ok=True)
    manifest = {'task':'UIX-R8-SKILLS', 'date':'2026-10-17', 'generator':'built-in ImageGen',
      'source':'Original AI-generated art; no external reference images',
      'license_status':'Generated for this project; no third-party commercial license asserted',
      'layers':'One RGBA object grouping per image. Controls, text and state remain Godot.', 'assets':[]}
    sheet = Image.new('RGB', (1008,360), '#efe7d2')
    draw = ImageDraw.Draw(sheet)
    for i, record in enumerate(records):
        ident = record['id']
        original = OUT/'originals'/f'{ident}.png'
        shutil.copy2(record['generated_path'],original)
        im = Image.open(original).convert('RGBA')
        alpha = im.getchannel('A')
        assert alpha.getextrema() == (0,255), ident
        box = alpha.getbbox()
        fit = ImageOps.contain(im.crop(box),(304,304),Image.Resampling.LANCZOS)
        runtime = Image.new('RGBA',(336,336))
        runtime.alpha_composite(fit,((336-fit.width)//2,(336-fit.height)//2))
        target = RUNTIME/f'{ident}.png'
        runtime.save(target,optimize=True)
        x,y = (i%4)*252,(i//4)*180
        preview = runtime.resize((144,144),Image.Resampling.LANCZOS)
        sheet.paste(preview,(x+54,y),preview)
        draw.text((x+8,y+150),ident,fill='#343c3d')
        (OUT/f'{ident}-prompt.txt').write_text(record['prompt']+'\n',encoding='utf-8')
        manifest['assets'].append({'id':ident,'game_id':ident if ident!='study_scroll' else None,
          'source':original.relative_to(ROOT).as_posix(),'runtime':target.relative_to(ROOT).as_posix(),
          'source_size':list(im.size),'runtime_size':[336,336],'alpha':True,
          'purpose':'64px desktop header' if ident=='study_scroll' else '112px desktop / 80px compact skill icon',
          'processing':'Complete alpha bounds fitted with16px padding; generated alpha preserved; no painted edits',
          'prompt':(OUT/f'{ident}-prompt.txt').relative_to(ROOT).as_posix(),
          'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
    (RUNTIME/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    sheet.save(OUT/'art-contact-sheet.jpg',quality=95)
    print('PASS seven alpha images, preserved sources/prompts, manifest and contact sheet')
if __name__=='__main__': main()
