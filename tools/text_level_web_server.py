"""Serve level-up acceptance on isolated origin 4187, without player data."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parent.parent


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path != '/level-setup':
            return super().do_GET()
        fixture = (ROOT / 'docs/verification/artifacts/text-level-web-fixture.json').read_text(encoding='utf-8-sig')
        page = '''<!doctype html><meta charset="utf-8"><title>升級過場隔離驗收</title>
<h1>升級過場隔離測試</h1><p>築基 LV8，修煉與資源已補足；不是正式開局。</p>
<button id="seed">載入隔離測試檔</button><p id="status"></p><a href="/index.html">進入遊戲</a>
<script>const fixture=FIXTURE;
document.getElementById('seed').onclick=()=>{
if(localStorage.getItem('dao2_saves:save_main')||localStorage.getItem('dao2_saves:save_backup')){
document.getElementById('status').textContent='已有進度，保留原檔';return;}
localStorage.setItem('dao2_saves:save_main',fixture);
localStorage.setItem('dao2_saves:save_index',JSON.stringify({active_slot:'save_main',commit_sequence:1,revision:JSON.parse(fixture).revision}));
document.getElementById('status').textContent='已載入';};</script>'''.replace('FIXTURE', json.dumps(fixture, ensure_ascii=False).replace('<', '\\u003c'))
        data = page.encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == '__main__':
    ThreadingHTTPServer(('127.0.0.1', int(sys.argv[1]) if len(sys.argv) > 1 else 4187), partial(Handler, directory=str(ROOT / 'build/web'))).serve_forever()
