"""Local isolated STORY-2 review; observations go only to ignored test output."""
from pathlib import Path
from http.server import ThreadingHTTPServer
import json
from web_static_server import CompressedStaticHandler
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'.test-output/story2-browser'
PAGE='''<!doctype html><meta charset="utf-8"><title>STORY-2 桌面驗收</title>
<style>body{margin:0;background:#ddd;font:16px sans-serif}nav{height:48px;display:flex;gap:8px;align-items:center}button{height:44px;font-size:16px}iframe{display:block;border:0;width:1280px;height:720px}#summary{white-space:pre-wrap}#state{display:none}</style>
<nav><b>STORY-2 已賺得起點／暫停時鐘</b><button id="album">成就冊</button><button id="event">自然生成機緣</button><button id="fault">寫入：正常</button><button id="reload">重載</button></nav><iframe id="game" src="about:blank"></iframe><pre id="summary"></pre><pre id="state"></pre>
<script>window.caseId=new URLSearchParams(location.search).get('case')||'album';window.shellFail=false;let last='';
album.onclick=()=>location.href='/review.html?case=album';document.getElementById('event').onclick=()=>location.href='/review.html?case=event';
fault.onclick=()=>{shellFail=!shellFail;fault.textContent='寫入：'+(shellFail?'拒絕':'正常')};
document.getElementById('reload').onclick=()=>game.src='/index.html?n='+Date.now();
const sizes={'1280':[1280,720],'844':[844,390],'800':[800,360]};const size=sizes[new URLSearchParams(location.search).get('size')]||sizes['1280'];game.style.width=size[0]+'px';game.style.height=size[1]+'px';
window.receiveState=d=>{state.textContent=JSON.stringify(d);summary.textContent=JSON.stringify({case:d.case,era:d.era,revision:d.revision,save_failed:d.save_failed,viewport:d.viewport,route:d.route,pending:d.fortune.pending_encounter.id,claimed:d.achievements.claimed,decisions:d.book.receipts.length},null,2);let s=JSON.stringify(d);if(s!==last){last=s;fetch('/observation',{method:'POST',body:s})}};game.src='/index.html';</script>'''
class Handler(CompressedStaticHandler):
    def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(ROOT/'build/story2-acceptance'),**kwargs)
    def do_GET(self):
        if self.path.split('?')[0]=='/review.html':
            b=PAGE.encode();self.send_response(200);self.send_header('Content-Type','text/html;charset=utf-8');self.send_header('Content-Length',str(len(b)));self.end_headers();self.wfile.write(b)
        else:super().do_GET()
    def do_POST(self):
        n=int(self.headers.get('Content-Length',0))
        if self.path!='/observation' or not 0<n<150000:self.send_error(400);return
        d=json.loads(self.rfile.read(n));OUT.mkdir(parents=True,exist_ok=True)
        with (OUT/'states.jsonl').open('a',encoding='utf-8') as f:f.write(json.dumps(d,ensure_ascii=False)+'\n')
        self.send_response(204);self.end_headers()
if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('--port',type=int,default=48486)
    parser.add_argument('--output',default='.test-output/story2-browser')
    args=parser.parse_args()
    OUT=ROOT/args.output
    OUT.mkdir(parents=True,exist_ok=True)
    server=ThreadingHTTPServer(('127.0.0.1',args.port),Handler)
    print(f'STORY2 http://127.0.0.1:{args.port}/review.html',flush=True)
    server.serve_forever()
