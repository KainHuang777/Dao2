"""Fit complete ImageGen alpha bounds; record source, prompt and runtime hash."""
from pathlib import Path
from PIL import Image, ImageOps
import json, hashlib
ROOT = Path(__file__).resolve().parent.parent
source = ROOT/'docs/verification/artifacts/uix-r7-f1/life_lamp_spent-original.png'
im = Image.open(source).convert('RGBA')
assert im.getchannel('A').getextrema() == (0,255)
fit = ImageOps.contain(im.crop(im.getchannel('A').getbbox()), (480,480), Image.Resampling.LANCZOS)
out = Image.new('RGBA',(512,512))
out.alpha_composite(fit,((512-fit.width)//2,(512-fit.height)//2))
target = ROOT/'assets/ui/reincarnation-painted/life_lamp_spent.png'
out.save(target,optimize=True)
manifest = ROOT/'assets/ui/reincarnation-painted/manifest.json'
data = json.loads(manifest.read_text(encoding='utf-8-sig'))
data['assets'] = [a for a in data['assets'] if a['id'] != 'life_lamp_spent']
data['assets'].append({'id':'life_lamp_spent','source':source.relative_to(ROOT).as_posix(),
 'runtime':target.relative_to(ROOT).as_posix(),'source_size':list(im.size),'runtime_size':[512,512],
 'purpose':'Exhausted lifespan hero, 192px desktop / 72px short landscape',
 'processing':'Fit complete alpha bounds, 16px transparent margin; preserve generated alpha',
 'prompt':(ROOT/'docs/verification/artifacts/uix-r7-f1/prompt.txt').read_text(encoding='utf-8'),
 'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
manifest.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS alpha, full silhouette fit, manifest, prompt and SHA256')
