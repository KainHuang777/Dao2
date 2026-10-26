"""Dev-only art review HTML and audio companions, independent of Godot rules."""
from pathlib import Path
import json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification/artifacts/content-p2-pills-ui'
BUILD=ROOT/'build/pill2-acceptance'
def main():
 entries=json.loads((OUT/'art-manifest.json').read_text(encoding='utf-8'))['assets']
 cards=''.join(f'<figure><img src="{e["id"]}-original.png" alt="{e["name"]}"><figcaption>{e["name"]}</figcaption></figure>' for e in entries)
 html='<!doctype html><meta charset="utf-8"><title>PILL-2 八丹圖稿</title><style>body{margin:0;background:#eee8d8;color:#343c3d;font:20px sans-serif}main{max-width:1400px;margin:auto;padding:20px}h1{font-size:26px;margin:0 0 8px}p{font-size:16px;margin:0 0 12px}section{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}figure{margin:0;padding:12px;background:#f8f4e9;border:1px solid #b7b29e;border-radius:8px;text-align:center}img{width:100%;height:230px;object-fit:contain}figcaption{padding-top:6px}</style><main><h1>PILL-2 · 八丹圖稿</h1><p>內建 ImageGen 原創透明圖 · 實際美術待接受 · 此頁為原圖審閱，遊戲內沿共用 UiIllustration B</p><section>'+cards+'</section></main>'
 (OUT/'art-gallery.html').write_text(html,encoding='utf-8')
 gallery=BUILD/'review-art';gallery.mkdir(parents=True,exist_ok=True)
 shutil.copyfile(OUT/'art-gallery.html',gallery/'index.html')
 for e in entries:shutil.copyfile(ROOT/e['original'],gallery/(e['id']+'-original.png'))
 audio=BUILD/'audio/bgm';audio.mkdir(parents=True,exist_ok=True)
 for entry in json.loads((ROOT/'assets/audio/bgm/library.json').read_text(encoding='utf-8')):shutil.copyfile(ROOT/'src/BGM'/entry['filename'],audio/entry['filename'])
 print('art review HTML, 8 unchanged originals, 4 BGM companions copied')
if __name__=='__main__':main()
