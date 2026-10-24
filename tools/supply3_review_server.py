"""Local-only Godot desktop review, earned snapshot and optional storage fault."""
from pathlib import Path
from http.server import ThreadingHTTPServer
from web_static_server import CompressedStaticHandler
import argparse
ROOT=Path(__file__).resolve().parents[1]
PAGE='''<!doctype html><meta charset="utf-8"><title>SUPPLY-3 desktop review</title>
<style>body{margin:0;background:#eee;font:16px sans-serif}button{min-height:44px}iframe{border:0;display:block}</style>
<button id="seed">載入已賺得隔離案例</button><button id="play">保留重載</button><label><input id="fault" type="checkbox">拒寫</label><span id="status">獨立本機origin，不讀玩家origin</span>
<iframe id="game" width="1280" height="720"></iframe><pre id="state"></pre>
<script>window.rejectSupplyWrite=false;fault.onchange=()=>window.rejectSupplyWrite=fault.checked;
seed.onclick=async()=>{if(localStorage.getItem('dao2_saves:save_main')){status.textContent='已有案例，請保留重載';return}const raw=await(await fetch('/fixture')).text(),s=JSON.parse(raw);localStorage.setItem('dao2_saves:save_main',raw);localStorage.setItem('dao2_saves:save_index',JSON.stringify({active_slot:'save_main',revision:s.revision,commit_sequence:1}));game.src='/index.html'};
play.onclick=()=>game.src='/index.html';
setInterval(()=>{try{const i=JSON.parse(localStorage.getItem('dao2_saves:save_index')),x=JSON.parse(localStorage.getItem('dao2_saves:'+i.active_slot));state.textContent=JSON.stringify({revision:x.revision,era:x.state.era_id,level:x.state.level,economy:x.state.economy.version,islands:x.state.economy.islands,routes:x.state.economy.routes},null,2)}catch{}},1000);</script>'''
class Handler(CompressedStaticHandler):
 def __init__(self,*a,**kw): super().__init__(*a,directory=str(ROOT/'build/web-supply3-local'),**kw)
 def do_GET(self):
  path=self.path.split('?')[0]
  if path in ['/launcher','/fixture','/index.html']:
   if path=='/launcher': data=PAGE.encode()
   elif path=='/fixture': data=Path(ARGS.fixture).read_bytes()
   else:
    raw=(ROOT/'build/web-supply3-local/index.html').read_text(encoding='utf-8')
    hook='<script>const origSet=Storage.prototype.setItem;Storage.prototype.setItem=function(k,v){if(parent.rejectSupplyWrite&&k.startsWith("dao2_saves:"))throw new Error("SUPPLY3_TEST_REFUSAL");return origSet.call(this,k,v)}</script>'
    data=raw.replace('<head>','<head>'+hook,1).encode()
   self.send_response(200);self.send_header('Content-Type','application/json' if path=='/fixture' else 'text/html;charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
  else: super().do_GET()
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--port',type=int,default=48440);p.add_argument('--fixture',default=str(ROOT/'docs/verification/artifacts/content-p2-supply-3/review-old.json'));ARGS=p.parse_args();ThreadingHTTPServer(('127.0.0.1',ARGS.port),Handler).serve_forever()
