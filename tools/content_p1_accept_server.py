"""Local earned-snapshot review; new origin and test-only storage namespace."""
from pathlib import Path
from http.server import ThreadingHTTPServer
from web_static_server import CompressedStaticHandler
ROOT = Path(__file__).resolve().parents[1]
PAGE = '''<!doctype html><meta charset="utf-8"><title>P1 同版整合審閱</title>
<style>body{margin:0;background:#eee;font:16px sans-serif}header{height:100px}button,select{min-height:44px}iframe{border:0;display:block}pre{white-space:pre-wrap}</style>
<header><b>隔離審閱：CLI合法取得快照；瀏覽器暫停，不代表自然等待</b><br>
<select id="scenario"><option value="second_base">第二世金丹／保留20道心</option><option value="integrated">首世P1整合成果</option><option value="reborn">首次壽盡輪迴後</option><option value="blank">空白新檔</option></select>
<button id="reset">載入案例（僅清測試儲存）</button><button id="reload">保留重載</button>
<button data-w="1280" data-h="720">1280×720</button><button data-w="844" data-h="390">844×390</button><button data-w="800" data-h="360">800×360</button>
<label><input id="fault" type="checkbox">拒寫</label><label><input id="clock" type="checkbox">自然時間</label></header>
<iframe id="game" width="1280" height="720" src="/index.html"></iframe><pre id="state"></pre>
<script>window.shellFail=false;fault.onchange=()=>window.shellFail=fault.checked;
document.querySelectorAll('[data-w]').forEach(b=>b.onclick=()=>{game.width=b.dataset.w;game.height=b.dataset.h});
reset.onclick=()=>{for(const k of Object.keys(localStorage))if(k.startsWith('dao2_content_p1_acceptance:'))localStorage.removeItem(k);game.src='/index.html?n='+Date.now()};
document.getElementById('reload').onclick=()=>game.contentWindow.location.reload();</script>'''
class Handler(CompressedStaticHandler):
    def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(ROOT/'build/content-p1-acceptance'),**kwargs)
    def do_GET(self):
        if self.path.split('?')[0]=='/launcher':
            data=PAGE.encode(); self.send_response(200);self.send_header('Content-Type','text/html;charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
        else: super().do_GET()
if __name__=='__main__': ThreadingHTTPServer(('127.0.0.1',48426),Handler).serve_forever()
