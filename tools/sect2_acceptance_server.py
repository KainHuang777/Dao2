"""Local-only, paused SECT-2 desktop mouse shell. No player namespaces."""
from pathlib import Path
from http.server import ThreadingHTTPServer
import json
from web_static_server import CompressedStaticHandler
ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / 'build/sect2-acceptance'
LOG = ROOT / 'docs/verification/artifacts/content-p2-sect-ui/browser-states.jsonl'
PAGE = '''<!doctype html><meta charset="utf-8"><title>SECT-2 桌面驗收</title>
<style>body{margin:0;background:#ddd;font:16px sans-serif}nav{height:48px;display:flex;align-items:center;gap:8px}button,select{height:44px;font-size:16px}iframe{display:block;border:0;width:1280px;height:720px}#summary{position:absolute;left:1290px;top:52px;width:360px;white-space:pre-wrap}#state{display:none}</style>
<nav><b>SECT-2 隔離驗收</b><select id="case"><option>era4</option><option>era6</option></select><button id="load">切換測試情境</button><button id="fault">寫入：正常</button><button id="reload">重載</button><span>1280×720 暫停時鐘；已賺得起點，正式命令分支</span></nav>
<iframe id="game" src="about:blank"></iframe><pre id="summary"></pre><pre id="state"></pre>
<script>
window.caseId=new URLSearchParams(location.search).get('case')||'era4';window.shellFail=false;let last='';
document.getElementById('case').value=caseId;
document.getElementById('load').onclick=()=>location.href='/review.html?case='+document.getElementById('case').value;
const fault=document.getElementById('fault');fault.textContent='寫入：'+(shellFail?'拒絕':'正常');
fault.onclick=()=>{shellFail=!shellFail;fault.textContent='寫入：'+(shellFail?'拒絕':'正常')};
document.getElementById('reload').onclick=()=>document.getElementById('game').src='/index.html?reload='+Date.now();
window.receiveState=d=>{document.getElementById('state').textContent=JSON.stringify(d);document.getElementById('summary').textContent=JSON.stringify({case:d.case,ready:d.ready,era:d.era,techniques:d.techniques,purchases:d.purchases,contribution:d.contribution,revision:d.revision,save_failed:d.save_failed,migration_pending:d.migration_pending},null,2);const text=JSON.stringify(d);if(text!==last){last=text;fetch('/observation',{method:'POST',body:text})}};
document.getElementById('game').src='/index.html';
</script>'''
class Handler(CompressedStaticHandler):
    def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(BUILD),**kwargs)
    def do_GET(self):
        if self.path.split('?')[0]=='/review.html':
            body=PAGE.encode('utf-8');self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body)
        else: super().do_GET()
    def do_POST(self):
        size=int(self.headers.get('Content-Length',0))
        if self.path!='/observation' or not 0<size<100000: self.send_error(400);return
        data=json.loads(self.rfile.read(size))
        with LOG.open('a',encoding='utf-8') as stream: stream.write(json.dumps(data,ensure_ascii=False)+'\n')
        self.send_response(204);self.end_headers()
if __name__=='__main__':
    print('SECT-2 http://127.0.0.1:4476/review.html',flush=True)
    ThreadingHTTPServer(('127.0.0.1',4476),Handler).serve_forever()
