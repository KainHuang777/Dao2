"""Preserve built-in ImageGen RGBA originals, prompts, and runtime copies."""
from pathlib import Path
import json, hashlib, shutil
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'docs/verification/artifacts/content-p2-beasts-ui'
ART = ROOT/'assets/ui/beasts-painted'
SOURCE = Path('C:/Users/asus/.codex/generated_images/01a177e6-3392-73c3-82ab-8be5a9b0ada3')
FILES = ['exec-70dc28c8-3c20-4231-99f8-31642e1a5477.png','exec-1894ab84-73d7-4130-ac46-6f415619329d.png']
EDIT = 'Edit the frost stag image. Preserve its identity, painterly style, colors and anatomy. Pull the entire animal back within the image so ALL crystal antler tips and hooves and tail are fully visible, with at least 10 percent generous genuinely transparent empty padding around the entire silhouette on all four sides. Do not crop antlers. No scenery, text, UI or ground. Keep transparent background.'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 OUT.mkdir(parents=True,exist_ok=True); ART.mkdir(parents=True,exist_ok=True)
 proposal=json.loads((ROOT/'docs/design-data/content-p2-beasts-proposal.json').read_text(encoding='utf-8'))
 entries=[]
 for beast,filename in zip(proposal['beasts'],FILES):
  source=SOURCE/filename; original=OUT/(beast['id']+'-original.png'); runtime=ART/(beast['id']+'.png')
  for dst in [original,runtime]:
   if dst.exists() and sha(dst)!=sha(source): raise RuntimeError('Refuse overwrite '+str(dst))
   shutil.copyfile(source,dst)
  im=Image.open(runtime)
  assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
  entries.append(dict(id=beast['id'],source=str(source),original=original.relative_to(ROOT).as_posix(),runtime=runtime.relative_to(ROOT).as_posix(),sha256=sha(source),size=im.size,alpha_bbox=im.getchannel('A').getbbox(),prompt=beast['art']['prompt'],edit_prompt=EDIT if beast['id']=='frost_stag' else None))
 draft=SOURCE/'exec-7770d1eb-91d4-461c-abde-0a0d1a37db2c.png'
 shutil.copyfile(draft,OUT/'frost_stag-first-draft.png')
 manifest=dict(date='2026-10-26',tool='built-in image_gen.imagegen',transparent_background=True,purpose='BEAST-2 creature cards and owning talent thumbnails',layers='single RGBA creature per file; no world placement',processing='byte-identical copies; no crop, resize, or baked outlines; shared UiIllustration B',acceptance='PENDING_USER_ART_ACCEPTANCE',rights='AI-generated original candidates under applicable OpenAI terms; no third-party references or exclusive-rights claim',assets=entries,draft=dict(source=str(draft),sha256=sha(draft),reason='antler padding revision'))
 for dst in [OUT/'art-manifest.json',ART/'beast2-manifest.json']: dst.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 print('Two RGBA originals/runtime copies verified')
if __name__=='__main__': main()
