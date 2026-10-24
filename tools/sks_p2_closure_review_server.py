"""Loopback-only review of the normal SKS-P2 milestone candidate."""
from pathlib import Path
from http.server import ThreadingHTTPServer
import supply3_review_server as base

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build/web-sks-p2'
ART = ROOT / 'docs/verification/artifacts/sks-p2-closure'
PAGE = base.PAGE.replace('SUPPLY-3 desktop review', 'SKS-P2 closure candidate')
PAGE = PAGE.replace('<iframe id="game"', '<button onclick="game.width=1280;game.height=720">1280×720</button><button onclick="game.width=844;game.height=390">844×390</button><button onclick="game.width=800;game.height=360">800×360</button><iframe id="game"')
PAGE = PAGE.replace('economy:x.state.economy.version,', 'economy:x.state.economy.version,skill_version:x.state.skill_version,skills:x.state.skills,points:x.state.resources.skill_point,')

class Handler(base.CompressedStaticHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BUILD), **kwargs)

    def do_GET(self):
        path = self.path.split('?')[0]
        if path == '/launcher':
            data = PAGE.encode('utf-8')
        elif path == '/fixture':
            data = (ART / 'review-era6.json').read_bytes()
        elif path == '/index.html':
            hook = '<script>const origSet=Storage.prototype.setItem;Storage.prototype.setItem=function(k,v){if(parent.rejectSupplyWrite&&k.startsWith("dao2_saves:"))throw new Error("SKS_P2_CLOSURE_TEST_REFUSAL");return origSet.call(this,k,v)}</script>'
            data = (BUILD/'index.html').read_text(encoding='utf-8').replace('<head>', '<head>'+hook, 1).encode('utf-8')
        else:
            return super().do_GET()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json' if path == '/fixture' else 'text/html;charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

if __name__ == '__main__':
    print('SKS-P2 closure http://127.0.0.1:48461/launcher', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 48461), Handler).serve_forever()
