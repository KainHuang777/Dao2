"""Local-only P2 mouse verification shell; never reads player saves."""
from pathlib import Path
from http.server import ThreadingHTTPServer
import json
from web_static_server import CompressedStaticHandler

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / 'build/sks-p2-acceptance'
LOG = ROOT / 'docs/verification/artifacts/sks-p2-acceptance/browser-states.jsonl'
PAGE = '''<!doctype html><meta charset="utf-8"><title>SKS-P2 桌面滑鼠驗收</title>
<style>body{margin:0;background:#ddd;font:16px sans-serif}nav{height:48px;display:flex;align-items:center;gap:8px}button,select{height:44px;font-size:16px}iframe{display:block;border:0;width:1280px;height:720px}#summary{position:absolute;left:1290px;top:52px;width:360px;white-space:pre-wrap}#state{display:none}</style>
<nav><b>SKS-P2 隔離驗收</b><select id="era"><option>6</option><option>5</option><option>4</option><option>3</option></select><button id="load">切換已賺得存檔</button><button id="refill">合法模擬時間產點至上限</button><button id="fault">寫入：正常</button><button id="reload">重載</button><span>1280×720 · 暫停時鐘</span></nav>
<iframe id="game" src="/index.html"></iframe><pre id="summary"></pre><pre id="state"></pre>
<script>
const caseEra=Number(new URLSearchParams(location.search).get('era')||6);
window.caseEra=caseEra; window.refillRequest=0; window.shellFail=false; let last='';
document.getElementById('era').value=String(caseEra);
document.getElementById('load').onclick=()=>location.href='/review.html?era='+document.getElementById('era').value;
document.getElementById('refill').onclick=()=>window.refillRequest++;
document.getElementById('fault').onclick=()=>{window.shellFail=!window.shellFail;document.getElementById('fault').textContent='寫入：'+(window.shellFail?'拒絕':'正常')};
document.getElementById('reload').onclick=()=>document.getElementById('game').src='/index.html?reload='+Date.now();
window.receiveState=d=>{document.getElementById('state').textContent=JSON.stringify(d);document.getElementById('summary').textContent=JSON.stringify({era:d.era,points:d.points,skills:d.skills,save_failed:d.save_failed,refill:d.refill,viewport:d.viewport},null,2);const text=JSON.stringify(d);if(text!==last){last=text;fetch('/observation',{method:'POST',body:text})}};
</script>'''

class Handler(CompressedStaticHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BUILD), **kwargs)

    def do_GET(self):
        if self.path.split('?')[0] == '/review.html':
            body = PAGE.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            super().do_GET()

    def do_POST(self):
        if self.path != '/observation':
            self.send_error(404)
            return
        size = int(self.headers.get('Content-Length', 0))
        if not 0 < size < 100000:
            self.send_error(413)
            return
        data = json.loads(self.rfile.read(size))
        with LOG.open('a', encoding='utf-8') as stream:
            stream.write(json.dumps(data, ensure_ascii=False) + '\n')
        self.send_response(204)
        self.end_headers()

if __name__ == '__main__':
    print('SKS-P2: http://127.0.0.1:4468/review.html', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 4468), Handler).serve_forever()
