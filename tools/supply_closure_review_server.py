"""Isolated candidate review with explicit desktop iframe sizes."""
from pathlib import Path
from http.server import ThreadingHTTPServer
import argparse
import supply3_review_server as base

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build/web-content-p2-supply'
ARTIFACTS = ROOT / 'docs/verification/artifacts/content-p2-supply-closure'

class Handler(base.Handler):
    def __init__(self, *args, **kwargs):
        base.CompressedStaticHandler.__init__(self, *args, directory=str(BUILD), **kwargs)

    def do_GET(self):
        path = self.path.split('?')[0]
        if path == '/launcher':
            page = base.PAGE.replace('SUPPLY-3 desktop review', 'SUPPLY closure candidate review')
            page = page.replace('<iframe id="game"', '<button onclick="game.width=1280;game.height=720">1280×720</button><button onclick="game.width=844;game.height=390">844×390</button><button onclick="game.width=800;game.height=360">800×360</button><iframe id="game"')
            data = page.encode('utf-8')
        elif path == '/fixture':
            data = (ARTIFACTS / ARGS.fixture).read_bytes()
        elif path == '/index.html':
            hook = '<script>const origSet=Storage.prototype.setItem;Storage.prototype.setItem=function(k,v){if(parent.rejectSupplyWrite&&k.startsWith("dao2_saves:"))throw new Error("SUPPLY_CLOSURE_TEST_REFUSAL");return origSet.call(this,k,v)}</script>'
            data = (BUILD/'index.html').read_text(encoding='utf-8').replace('<head>', '<head>'+hook, 1).encode('utf-8')
        else:
            return base.CompressedStaticHandler.do_GET(self)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json' if path == '/fixture' else 'text/html;charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=48450)
    parser.add_argument('--fixture', default='review-era6.json')
    ARGS = parser.parse_args()
    ThreadingHTTPServer(('127.0.0.1', ARGS.port), Handler).serve_forever()
