"""Explicit isolated desktop Web fixture controls; never serves player storage."""
import sys
from pathlib import Path
from http.server import ThreadingHTTPServer
sys.path.insert(0,str(Path(__file__).resolve().parent))
from web_static_server import CompressedStaticHandler
ROOT=Path(__file__).resolve().parents[1]
PAGE='''<!doctype html><meta charset="utf-8"><title>CONTENT-P1-SECT isolated acceptance</title>
<style>body{margin:0;background:#eee;color:#222;font:14px sans-serif}header{height:72px}iframe{border:0;display:block}pre{white-space:pre-wrap;max-width:1280px}button,select{min-height:28px}</style>
<header><b>隔離資助 Era3 宗門驗收；不是自然取得進度</b>
<select id="template"><option>home_supply_register</option><option>wood_ore_convoy</option><option>herb_island_inventory</option><option>specialist_pill_preparation</option><option>jade_fox_nursery</option><option>earned-era2</option></select>
<button id="reset">載入案例（只清測試空間）</button><button id="reload">重載保留進度</button><br>
<button data-w="1280" data-h="720">1280×720</button><button data-w="844" data-h="390">844×390</button><button data-w="800" data-h="360">800×360</button>
<label><input id="fault" type="checkbox">拒寫保存</label><label><input id="clock" type="checkbox">自然時間</label><label><input id="advance" type="checkbox">CLI等價模擬至委託完成</label>
</header><iframe id="game" width="1280" height="720" src="/index.html"></iframe><pre id="state"></pre>
<script>window.shellFail=false;fault.onchange=()=>window.shellFail=fault.checked;
document.querySelectorAll('[data-w]').forEach(b=>b.onclick=()=>{game.width=b.dataset.w;game.height=b.dataset.h});
reset.onclick=()=>{for(const k of Object.keys(localStorage))if(k.startsWith('dao2_content_p1_sect_acceptance:'))localStorage.removeItem(k);game.src='/index.html?case='+encodeURIComponent(template.value)+'&n='+Date.now()};
document.getElementById('reload').onclick=()=>game.contentWindow.location.reload();</script>'''
class Handler(CompressedStaticHandler):
    def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(ROOT/'build/content-p1-sect-acceptance'),**kwargs)
    def do_GET(self):
        if self.path.split('?')[0]=='/launcher':
            data=PAGE.encode(); self.send_response(200);self.send_header('Content-Type','text/html;charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
        else: super().do_GET()
if __name__=='__main__': ThreadingHTTPServer(('127.0.0.1',48423),Handler).serve_forever()
