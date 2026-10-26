"""Copy built-in ImageGen originals byte-for-byte. Preserve alpha and full prompts."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path('C:/Users/asus/.codex/generated_images/01a16f3b-e476-74a0-87f1-cbc4ca6024e4')
FILES=['exec-62c40505-a7bc-4185-b731-008d1b2e1579.png','exec-d5d8b9e8-ee48-45f1-b2f6-1fbbd146ce79.png','exec-9ba5cb22-1874-41bd-ae62-ca986a9e23a2.png','exec-743f2017-4aeb-4817-a839-c5e8b5cc1a3f.png','exec-47b2234f-c65a-4284-8621-6b395c7b3fd4.png','exec-4f69cc7f-6b13-4df3-aaad-9a700132a325.png','exec-8a7a5b94-79c4-49b6-923e-9e8c5092b972.png','exec-eefeee57-9396-43c0-bbe1-084681a23e7b.png']
OUT=ROOT/'docs/verification/artifacts/content-p2-pills-ui'
ART=ROOT/'assets/ui/pills-painted'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 proposal=json.loads((ROOT/'docs/design-data/content-p2-pills-proposal.json').read_text(encoding='utf-8'))
 OUT.mkdir(parents=True,exist_ok=True);ART.mkdir(parents=True,exist_ok=True)
 entries=[]
 for item,filename in zip(proposal['pills'],FILES):
  source=SOURCE/filename;original=OUT/(item['id']+'-original.png');runtime=ART/(item['id']+'.png')
  for dst in [original,runtime]:
   if dst.exists() and sha(dst)!=sha(source):raise RuntimeError('refuse overwrite '+str(dst))
   shutil.copyfile(source,dst)
  im=Image.open(runtime)
  assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
  prompt=item['prompt']+' Square composition, single centered pearl fills 70 percent of canvas, legible at 44px.'
  # First request included the same explicit no-humanoid-infant constraint.
  entries.append(dict(id=item['id'],name=item['name'],source=str(source),original=original.relative_to(ROOT).as_posix(),runtime=runtime.relative_to(ROOT).as_posix(),sha256=sha(runtime),size=im.size,alpha_extrema=im.getchannel('A').getextrema(),prompt=prompt))
 manifest=dict(date='2026-10-25',tool='built-in image_gen.imagegen',transparent_background=True,purpose='PILL-2 eight consumable card illustrations',layers='single RGBA foreground per ID; no labels/UI/scenery; shared UiIllustration B',processing='byte-identical copies; no edits, crop, resizing or chroma key',acceptance='PENDING_USER_ART_ACCEPTANCE',rights='AI-generated original candidates under applicable OpenAI service terms; no third-party reference material, no exclusive or third-party commercial-license claim',assets=entries)
 (OUT/'art-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 (ART/'pill2-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 (OUT/'prompts.json').write_text(json.dumps({e['id']:e['prompt'] for e in entries},ensure_ascii=False,indent=2),encoding='utf-8')
 print('8 byte-identical RGBA originals/runtime assets validated')
if __name__=='__main__':main()
