"""D2 browser matrix on an isolated loopback origin; no build files edited."""
import argparse
import json
from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit
from web_persistence_server import INSTRUMENT, LIVE
from web_static_server import CompressedStaticHandler, prewarm

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / 'build/res1d2-web'
RELEASE = ROOT / 'build/res1d2-web-live'
EVIDENCE = ROOT / 'docs/verification/artifacts/res1-d2-web-browser.jsonl'
CASES = ['d2progress', 'd2retry', 'd2quota', 'd2indexreload',
         'd2quotareload', 'd2lock', 'd2denied', 'd2corrupt', 'd2migration']


class Handler(CompressedStaticHandler):
    gzip_enabled = False
    def do_GET(self):
        path = urlsplit(self.path).path
        if path == '/d2-fixture':
            self.send_data((ROOT / 'docs/verification/artifacts/res1-d2-active-fixture.json').read_bytes(), 'application/json')
        elif path == '/fixture':
            self.send_data((ROOT / 'docs/verification/artifacts/res1-d2-earned-era3.json').read_bytes(), 'application/json')
        elif path == '/launcher':
            from res1d2r1_preview_server import preview
            page = preview.PAGE.replace("'/index.html'", "'/release/index.html'")
            self.send_data(page.encode('utf-8'), 'text/html; charset=utf-8')
        elif path in ('/', '/index.html'):
            instrument = INSTRUMENT.replace('RES1-B / M1-C/D Web 保存驗證', 'RES1-D2 Web 保存與規則驗證')
            instrument = instrument.replace('隔離 origin 4196', f'隔離 origin {self.server.server_port}')
            start, end = instrument.index('<nav>'), instrument.index('</nav>') + len('</nav>')
            nav = '<nav>' + ''.join(f'<a href="/?case={case}">{case}</a>' for case in CASES) + '</nav>'
            instrument = instrument[:start] + nav + instrument[end:]
            instrument = instrument.replace("k.endsWith(':save_schema2_original')", "k.endsWith(':save_before_d2')")
            instrument = instrument.replace("if(window.dao2Fault === 'index'", "if(window.dao2Fault === 'candidate_index' && k.endsWith(':save_index') && ++window.d2IndexWrites === 2) throw new DOMException('Injected candidate index failure','QuotaExceededError');\n  if(window.dao2Fault === 'index'")
            self.send_data((BUILD / 'index.html').read_text(encoding='utf-8').replace('<script>', instrument + '<script>', 1).encode('utf-8'), 'text/html; charset=utf-8')
        elif path in ('/release/index.html', '/fault.html'):
            self.send_data((RELEASE / 'index.html').read_text(encoding='utf-8').replace('<script>', LIVE + '<script>', 1).encode('utf-8'), 'text/html; charset=utf-8')
        elif path.startswith('/release/'):
            original = self.directory
            self.directory = str(RELEASE)
            self.path = self.path.removeprefix('/release')
            try:
                super().do_GET()
            finally:
                self.directory = original
        else:
            super().do_GET()

    def send_data(self, data, mime):
        self.send_response(200)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        if self.path != '/evidence':
            self.send_error(404)
            return
        size = int(self.headers.get('Content-Length', '0'))
        if not 0 < size <= 1048576:
            self.send_error(400)
            return
        record = json.loads(self.rfile.read(size))
        with EVIDENCE.open('a', encoding='utf-8') as out:
            out.write(json.dumps(record, ensure_ascii=False) + '\n')
        self.send_response(204)
        self.end_headers()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4259)
    parser.add_argument('--build', default='res1d2-web', help='Probe directory name inside build/')
    parser.add_argument('--release', default='res1d2-web-live', help='Normal export directory name inside build/')
    parser.add_argument('--evidence', default='res1-d2-web-browser.jsonl', help='Evidence path inside docs/verification/artifacts/')
    parser.add_argument('--gzip', action='store_true')
    args = parser.parse_args()
    def confined(base, relative):
        target = (base / relative).resolve()
        if not target.is_relative_to(base.resolve()) or target == base.resolve():
            parser.error('Test paths must remain inside their project directory')
        return target
    BUILD = confined(ROOT / 'build', args.build)
    RELEASE = confined(ROOT / 'build', args.release)
    EVIDENCE = confined(ROOT / 'docs/verification/artifacts', args.evidence)
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    Handler.gzip_enabled = args.gzip
    prewarm(BUILD, Handler)
    prewarm(RELEASE, Handler)
    print(f'D2 isolated browser matrix http://127.0.0.1:{args.port}/?case=d2progress', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), partial(Handler, directory=str(BUILD))).serve_forever()
