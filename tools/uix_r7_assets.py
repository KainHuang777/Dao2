"""Import generated alpha assets; preserve originals and prompts, fit runtime bounds."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, shutil, hashlib
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'docs/verification/artifacts/uix-r7'
RUNTIME = ROOT/'assets/ui/reincarnation-painted'
def main():
    records=json.loads((OUT/'generation-records.json').read_text(encoding='utf-8-sig'))
    RUNTIME.mkdir(exist_ok=True,parents=True)
    (OUT/'originals').mkdir(exist_ok=True)
    manifest={'task':'UIX-R7-REINCARNATION','date':'2026-10-17','generator':'built-in ImageGen',
      'source':'Original AI-generated assets; no external reference images',
      'license_status':'Generated for this project; no third-party commercial license asserted',
      'layers':'One isolated RGBA object per file. Text, state, controls and transition remain Godot.', 'assets':[]}
    sheet=Image.new('RGB',(800,250),'#efe7d2')
    draw=ImageDraw.Draw(sheet)
    for i,record in enumerate(records):
        ident=record['id']
        original=OUT/'originals'/f'{ident}.png'
        shutil.copy2(record['generated_path'],original)
        im=Image.open(original).convert('RGBA')
        alpha=im.getchannel('A')
        assert alpha.getextrema()==(0,255),ident
        box=alpha.getbbox()
        edge=512 if ident=='reincarnation_wheel' else 336
        fit=ImageOps.contain(im.crop(box),(edge-32,edge-32),Image.Resampling.LANCZOS)
        runtime=Image.new('RGBA',(edge,edge))
        runtime.alpha_composite(fit,((edge-fit.width)//2,(edge-fit.height)//2))
        target=RUNTIME/f'{ident}.png'
        runtime.save(target,optimize=True)
        preview=runtime.resize((160,160),Image.Resampling.LANCZOS)
        sheet.paste(preview,(i*200+20,8),preview)
        draw.text((i*200+4,185),ident,fill='#343c3d')
        manifest['assets'].append({'id':ident,'source':original.relative_to(ROOT).as_posix(),
          'runtime':target.relative_to(ROOT).as_posix(),'source_size':list(im.size),'runtime_size':[edge,edge],
          'purpose':'160px settlement illustration' if i==0 else '112px desktop / 80px compact talent art',
          'processing':'Fit complete alpha bounds with 16px transparent padding; generated alpha retained',
          'prompt':record['prompt'],'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
    (RUNTIME/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    sheet.save(OUT/'art-contact-sheet.jpg',quality=95)
    print('PASS: four alpha assets, originals, prompts and runtime hashes')
if __name__=='__main__':main()
