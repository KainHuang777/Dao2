"""Explicit isolated desktop Web fixture controls; never serves player storage."""
import sys
from pathlib import Path
from http.server import ThreadingHTTPServer
sys.path.insert(0,str(Path(__file__).resolve().parent))
from web_static_server import CompressedStaticHandler
ROOT=Path(__file__).resolve().parents[1]
PAGE='''<!doctype html><meta charset="utf-8"><title>CONTENT-P1-STORY isolated acceptance</title>
<style>body{margin:0;background:#eee;color:#222;font:14px sans-serif}header{height:72px}iframe{border:0;display:block}pre{white-space:pre-wrap;max-width:1280px}button,select{min-height:28px}</style>
<header><b>隔離合成成就／機緣驗收；不是自然取得進度</b>
<select id="template"><option value="album">成就冊</option><option value="full-album">滿倉成就</option><option value="enc_p1_dry_spring">枯泉分流</option><option value="enc_p1_seed_merchant">散修換苗</option><option value="enc_p1_workshop_offcuts">木坊餘料</option><option value="enc_p1_returning_boat">歸舟補帆</option><option value="enc_p1_sect_lamp">丹房借燈</option><option value="enc_p1_supply_margin">委託簿邊註</option><option value="enc_p1_alchemist_measures">丹師校量</option><option value="enc_p1_fourfold_note">四脈丹箋</option><option value="enc_p1_fox_path">靈狐引徑</option><option value="enc_p1_fox_nightwatch">狐守夜爐</option><option value="enc_p1_old_lamp">前塵舊燈</option><option value="enc_p1_wisdom_exchange">宿慧問答</option></select>
<button id="reset">載入案例（只清測試空間）</button><button id="reload">重載保留進度</button><br>
<button data-w="1280" data-h="720">1280×720</button><button data-w="844" data-h="390">844×390</button><button data-w="800" data-h="360">800×360</button>
<label><input id="fault" type="checkbox">拒寫保存</label><label><input id="clock" type="checkbox">自然時間</label>
</header><iframe id="game" width="1280" height="720" src="/index.html"></iframe><pre id="state"></pre>
<script>window.shellFail=false;fault.onchange=()=>window.shellFail=fault.checked;
document.querySelectorAll('[data-w]').forEach(b=>b.onclick=()=>{game.width=b.dataset.w;game.height=b.dataset.h});
reset.onclick=()=>{for(const k of Object.keys(localStorage))if(k.startsWith('dao2_content_p1_story_acceptance:'))localStorage.removeItem(k);game.src='/index.html?case='+encodeURIComponent(template.value)+'&n='+Date.now()};
document.getElementById('reload').onclick=()=>game.contentWindow.location.reload();</script>'''
class Handler(CompressedStaticHandler):
    def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(ROOT/'build/content-p1-story-acceptance'),**kwargs)
    def do_GET(self):
        if self.path.split('?')[0]=='/launcher':
            data=PAGE.encode(); self.send_response(200);self.send_header('Content-Type','text/html;charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
        else: super().do_GET()
if __name__=='__main__': ThreadingHTTPServer(('127.0.0.1',48424),Handler).serve_forever()
