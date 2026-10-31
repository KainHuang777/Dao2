"""Local-only, paused SECT-REFORM-UI desktop mouse shell. No player namespaces."""
from pathlib import Path
from http.server import ThreadingHTTPServer
import json
import argparse
from web_static_server import CompressedStaticHandler
ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / 'build/sect-reform-ui-review'
LOG = ROOT / '.test-output/sect-ui-browser.jsonl'
PAGE = '''<!doctype html><meta charset="utf-8"><title>SECT-REFORM-UI 桌面驗收</title>
<style>body{margin:0;background:#ddd;font:16px sans-serif}nav{height:48px;display:flex;align-items:center;gap:8px}button,select{height:44px;font-size:16px}iframe{display:block;border:0;width:1280px;height:720px}#summary{position:absolute;left:1290px;top:52px;width:360px;white-space:pre-wrap}#state{display:none}</style>
<nav><b>SECT-REFORM-UI 隔離驗收</b><button id="fault">寫入：正常</button><button id="reload">重載</button><span>1280×720 暫停時鐘；金丹合成起點；正式命令／localStorage</span></nav>
<iframe id="game" src="about:blank"></iframe><pre id="summary"></pre><pre id="state"></pre>
<script>
window.shellFail=false;let last='';
const fault=document.getElementById('fault');fault.textContent='寫入：'+(shellFail?'拒絕':'正常');
fault.onclick=()=>{shellFail=!shellFail;fault.textContent='寫入：'+(shellFail?'拒絕':'正常')};
document.getElementById('reload').onclick=()=>document.getElementById('game').src='/index.html?reload='+Date.now();
window.receiveState=d=>{document.getElementById('state').textContent=JSON.stringify(d);document.getElementById('summary').textContent=JSON.stringify({revision:d.revision,tokens:d.tokens,permits:d.permits,active:d.active,techniques:d.techniques,lineage:d.lineage,pending:d.pending,route:d.route},null,2);const text=JSON.stringify(d);if(text!==last){last=text;fetch('/observation',{method:'POST',body:text})}};
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=4492)
    port = parser.parse_args().port
    print(f'SECT-REFORM-UI http://127.0.0.1:{port}/review.html',flush=True)
    ThreadingHTTPServer(('127.0.0.1',port),Handler).serve_forever()
