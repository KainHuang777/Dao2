"""Isolated SKILL-B1 UI origin; seed only when both slots are absent."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
PAGE = """<!doctype html><meta charset="utf-8"><title>技能 B 隔離驗證</title>
<style>body{margin:0;background:#10232c;color:white;font:16px sans-serif}button{height:40px}iframe{width:1280px;height:720px;border:0;display:block}pre{white-space:pre-wrap}</style>
<button id="seed">載入隔離技能測試檔</button><button id="play">開啟／重載遊戲</button><button id="compact">844×390</button><button id="wide">1280×720</button><button id="report">讀取保存結果</button><span id="status">此 origin 與玩家 origin 隔離</span><iframe id="game"></iframe><pre id="result"></pre>
<script>
const prefix='dao2_saves:';
seed.onclick=async()=>{if(localStorage.getItem(prefix+'save_main')||localStorage.getItem(prefix+'save_backup')){status.textContent='保留此 origin 既有進度';return;}const raw=await(await fetch('/fixture')).text();const s=JSON.parse(raw);localStorage.setItem(prefix+'save_main',raw);localStorage.setItem(prefix+'save_index',JSON.stringify({active_slot:'save_main',revision:s.revision,commit_sequence:1}));game.src='/index.html';};
play.onclick=()=>{game.src='/index.html?reload='+Date.now();};
compact.onclick=()=>{game.style.width='844px';game.style.height='390px';};wide.onclick=()=>{game.style.width='1280px';game.style.height='720px';};
report.onclick=()=>{const slots=['save_main','save_backup'].map(k=>{try{return JSON.parse(localStorage.getItem(prefix+k))}catch{return null}}).filter(Boolean).sort((a,b)=>b.revision-a.revision);const s=slots[0];result.textContent=JSON.stringify(s?{rules:s.rules_version,revision:s.revision,skill_version:s.state.skill_version,skills:s.state.skills,skill_point:s.state.resources.skill_point,buildings:{library:s.state.buildings.library,scripture_hall:s.state.buildings.scripture_hall},archives:Object.keys(localStorage).filter(k=>k.includes('save_before_skills'))}:{error:'no saved slots'},null,2);};
</script>"""
class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/launcher':
            data=PAGE.encode('utf-8'); mime='text/html; charset=utf-8'
        elif self.path == '/fixture':
            data=(ROOT/'docs/verification/artifacts/skills-b1-fixture.json').read_bytes(); mime='application/json'
        else: return super().do_GET()
        self.send_response(200); self.send_header('Content-Type',mime); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
if __name__ == '__main__':
    from functools import partial
    print('http://127.0.0.1:4265/launcher',flush=True)
    ThreadingHTTPServer(('127.0.0.1',4265),partial(Handler,directory=str(ROOT/'build/skills-b1-web'))).serve_forever()
