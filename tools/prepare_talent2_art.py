"""Preserve ImageGen originals and copy byte-identical runtime assets; no image editing."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('C:/Users/asus/.codex/generated_images/01a16e5e-ff0d-7bb0-840f-23a3e6784541')
OUT = ROOT / 'docs/verification/artifacts/content-p2-talents-ui'
ART = ROOT / 'assets/ui/reincarnation-painted'
FILES = ['exec-faa2ce70-ae50-4481-ac76-bf828b4f1437.png','exec-4c513a07-464c-4b57-8973-d404728e0385.png','exec-8d8bb3e6-48b9-4ea2-a2d8-1370213d6546.png']
proposal = json.loads((ROOT/'docs/design-data/content-p2-talents-proposal.json').read_text(encoding='utf-8'))
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    entries=[]
    for item, filename in zip(proposal['talents'],FILES):
        source=SOURCE/filename
        original=OUT/(item['id']+'-original.png')
        runtime=ART/(item['id']+'.png')
        for target in (original,runtime):
            if target.exists() and digest(target)!=digest(source): raise RuntimeError('refusing overwrite '+str(target))
            shutil.copyfile(source,target)
        im=Image.open(runtime)
        assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
        entries.append({'id':item['id'],'source':str(source),'original':original.relative_to(ROOT).as_posix(),'runtime':runtime.relative_to(ROOT).as_posix(),'sha256':digest(runtime),'size':im.size,'alpha_extrema':im.getchannel('A').getextrema(),'prompt':item['art_prompt']})
    manifest={'date':'2026-10-24','tool':'built-in image_gen.imagegen','transparent_background':True,'purpose':'TALENT-2 three talent card illustrations','layers':'one RGBA illustration per ID, no baked labels or UI; UiIllustration B applies shared rendering','processing':'byte-identical copies; original alpha preserved, no chroma key or resizing','acceptance':'PENDING_USER_ART_ACCEPTANCE','rights':'AI-generated original candidates under applicable OpenAI service terms; no third-party source material used; no exclusive or third-party commercial-license claim','assets':entries}
    (OUT/'art-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (ART/'talent2-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'prompts.json').write_text(json.dumps([{'id':a['id'],'prompt':a['prompt']} for a in entries],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'assets':len(entries),'alpha':'RGBA 0..255','acceptance':'PENDING'},ensure_ascii=False))
if __name__=='__main__': main()
