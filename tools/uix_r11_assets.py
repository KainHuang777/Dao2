"""Preserve generated alpha, retain sources/prompts and fit runtime art."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, shutil, hashlib
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'docs/verification/artifacts/uix-r11'
DEST=ROOT/'assets/ui/decisions-painted'
def main():
 records=json.loads((OUT/'generation-records.json').read_text(encoding='utf-8-sig'))
 (OUT/'originals').mkdir(exist_ok=True)
 manifest={'task':'UIX-R11-DECISIONS','date':'2026-10-18','generator':'built-in ImageGen','source':'Original AI-generated art; no external reference','license_status':'Generated for project; no third-party commercial license asserted','layers':'Single RGBA object; all UI text, values and actions remain Godot','assets':[]}
 sheet=Image.new('RGB',(672,672),'#efe7d2'); draw=ImageDraw.Draw(sheet)
 for i,r in enumerate(records):
  ident=r['id']; original=OUT/'originals'/f'{ident}.png'; shutil.copy2(r['generated_path'],original)
  im=Image.open(original).convert('RGBA'); alpha=im.getchannel('A'); assert alpha.getextrema()[0]==0
  fit=ImageOps.contain(im.crop(alpha.getbbox()),(448,448),Image.Resampling.LANCZOS)
  runtime=Image.new('RGBA',(480,480)); runtime.alpha_composite(fit,((480-fit.width)//2,(480-fit.height)//2))
  target=DEST/f'{ident}.png'; runtime.save(target,optimize=True)
  (OUT/f'{ident}-prompt.txt').write_text(r['prompt']+'\n',encoding='utf-8')
  thumb=runtime.resize((280,280)); x=(i%2)*336+28; y=(i//2)*336
  sheet.paste(thumb,(x,y),thumb); draw.text((x,y+286),ident,fill='#343c3d')
  manifest['assets'].append({'id':ident,'decision_id':ident,'purpose':'Theme emblem only; effects rendered by Godot','source':original.relative_to(ROOT).as_posix(),'runtime':target.relative_to(ROOT).as_posix(),'source_size':list(im.size),'runtime_size':[480,480],'alpha':True,'processing':'Full alpha bounds fitted to448px,16px padding; original alpha retained','prompt':f'docs/verification/artifacts/uix-r11/{ident}-prompt.txt','sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
 all_decisions=json.loads((ROOT/'content/realms/realm_decisions.json').read_text(encoding='utf-8-sig'))
 manifest['deferred_unreachable']=[{'id':d['id'],'realm_id':d['realm_id']} for d in all_decisions if d['realm_id'] not in ('realm_human','realm_spirit')]
 assert len(manifest['assets'])==4 and len(manifest['deferred_unreachable'])==10
 (DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 sheet.save(OUT/'art-contact-sheet.jpg',quality=95)
 print('PASS4 transparent sources/prompts/runtime assets;10 unreachable decisions recorded')
if __name__=='__main__': main()
