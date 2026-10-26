"""Loopback review of the normal talent batch Web candidate."""
from pathlib import Path
from http.server import ThreadingHTTPServer
import supply3_review_server as base
ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'build/web-content-p2-talents'
ART=ROOT/'docs/verification/artifacts/content-p2-talents-closure'
PAGE=base.PAGE.replace('SUPPLY-3 desktop review','CONTENT-P2-TALENT closure')
PAGE=PAGE.replace('<iframe id="game"','<button onclick="game.width=1280;game.height=720">1280×720</button><button onclick="game.width=844;game.height=390">844×390</button><button onclick="game.width=800;game.height=360">800×360</button><iframe id="game"')
PAGE=PAGE.replace('economy:x.state.economy.version,','economy:x.state.economy.version,talent_version:x.state.talent_version,talents:x.state.talents,hearts:x.state.dao_heart,')
class Handler(base.CompressedStaticHandler):
    def __init__(self,*a,**kw): super().__init__(*a,directory=str(BUILD),**kw)
    def do_GET(self):
        path=self.path.split('?')[0]
        if path=='/launcher': data=PAGE.encode('utf-8')
        elif path=='/fixture': data=(ART/'review-earned.json').read_bytes()
        elif path=='/index.html':
            hook='<script>const origSet=Storage.prototype.setItem;Storage.prototype.setItem=function(k,v){if(parent.rejectSupplyWrite&&k.startsWith("dao2_saves:"))throw new Error("TALENT2_CLOSURE_REFUSAL");return origSet.call(this,k,v)}</script>'
            data=(BUILD/'index.html').read_text(encoding='utf-8').replace('<head>','<head>'+hook,1).encode('utf-8')
        else: return super().do_GET()
        self.send_response(200);self.send_header('Content-Type','application/json' if path=='/fixture' else 'text/html;charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
if __name__=='__main__':
    print('http://127.0.0.1:48471/launcher',flush=True)
    ThreadingHTTPServer(('127.0.0.1',48471),Handler).serve_forever()
