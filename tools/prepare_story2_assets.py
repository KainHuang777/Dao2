"""Extract six-cell ImageGen sheets without repainting or alpha modification."""
from pathlib import Path
from PIL import Image
import hashlib, json, shutil
ROOT = Path(__file__).resolve().parents[1]
GENERATED = Path(r'C:\Users\asus\.codex\generated_images\01a1793e-abd3-7443-8b6c-123ff135fded')
SOURCES = [
 'exec-385e1b0c-581d-4878-8aff-6383982e55ef.png',
 'exec-69f44511-6020-415c-8520-adf99e678062.png',
 'exec-4cfdebe5-683b-4f56-a74f-3e8c8116d273.png',
 'exec-ea0e4095-e090-42d2-8313-3ba85e7a4ef7.png',
 'exec-d1b64d72-dda4-4949-8dcb-97e2c4612e21.png',
]
def main():
    proposal = json.loads((ROOT/'docs/design-data/content-p2-story-proposal.json').read_text(encoding='utf-8'))
    archive = ROOT/'docs/art-assets/story2'
    archive.mkdir(parents=True, exist_ok=True)
    rows = []
    for batch, filename in enumerate(SOURCES):
        source = GENERATED/filename if (GENERATED/filename).exists() else archive/filename
        if source.resolve() != (archive/filename).resolve(): shutil.copy2(source,archive/filename)
        sheet = Image.open(source)
        assert sheet.mode == 'RGBA' and sheet.getextrema()[3][0] == 0
        entries = proposal['art_assets'][batch*6:batch*6+6] if batch < 3 else [proposal['art_assets'][18+batch-3]]
        for index, entry in enumerate(entries):
            if batch < 3:
                x,y = index%3,index//3
                box = (x*sheet.width//3,y*sheet.height//2,(x+1)*sheet.width//3,(y+1)*sheet.height//2)
                output = sheet.crop(box)
                directory = 'assets/ui/achievements-painted'
            else:
                output = sheet; box = None; directory = 'assets/ui/fortune-painted'
            original = archive/(entry['id']+'.png')
            output.save(original)
            runtime = ROOT/directory/(entry['id']+'.png')
            shutil.copy2(original,runtime)
            alpha = output.getchannel('A')
            rows.append(dict(id=entry['id'],kind=entry['kind'],subject=entry['subject'],runtime=runtime.relative_to(ROOT).as_posix(),original=original.relative_to(ROOT).as_posix(),sheet='docs/art-assets/story2/'+filename,crop=box,sha256=hashlib.sha256(runtime.read_bytes()).hexdigest(),size=list(output.size),alpha_extrema=list(alpha.getextrema()),layers=entry['layers']))
    assert len(rows) == 20
    manifest=dict(task='CONTENT-P2-STORY / STORY-2',date='2026-10-27',acceptance='PENDING',source='Built-in ImageGen; prompts in assets/ui/story2-source-prompts.json',license='Original AI-generated artwork; no third-party commercial license asserted',processing='Equal-cell lossless extraction only; original alpha and colors preserved. Source sheets retained.',assets=rows)
    (ROOT/'assets/ui/content-p2-story-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Prepared',len(rows),'RGBA assets; acceptance PENDING')
if __name__=='__main__': main()
