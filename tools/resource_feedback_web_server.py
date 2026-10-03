"""Serve release build and a test-only fixture setup page on isolated origin 4192."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent.parent


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/resource-setup":
            fixture = (ROOT / "docs/verification/artifacts/resource-feedback-web-fixture.json").read_text(encoding="utf-8-sig")
            # The fixture is set by an explicit UI click; release HTML is untouched.
            html = """<!doctype html><meta charset="utf-8"><title>Resource Feedback R1 隔離驗收</title>
<h1>Resource Feedback R1 測試資料</h1><p>僅使用 127.0.0.1:4192；與玩家 4175 origin 分離。</p>
<p>EAR1 輪迴、繼承靈界設施、道心／道證／獸魂；僅作隔離驗收。</p>
<button id="seed">載入隔離測試檔</button><p id="status"></p><a href="/index.html">進入正式遊戲</a>
<script>const fixture = FIXTURE;
document.getElementById('seed').onclick=()=>{
if(localStorage.getItem('dao2_saves:save_main') || localStorage.getItem('dao2_saves:save_backup')){
document.getElementById('status').textContent='此 origin 已有進度，保留原檔；請直接進入遊戲。';return;}
localStorage.setItem('dao2_saves:save_main',fixture);
localStorage.setItem('dao2_saves:save_index',JSON.stringify({active_slot:'save_main',commit_sequence:1,revision:JSON.parse(fixture).revision}));
document.getElementById('status').textContent='已載入隔離測試檔';};</script>""".replace("FIXTURE", json.dumps(fixture, ensure_ascii=False).replace("<", "\\u003c"))
            data = html.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            super().do_GET()


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 4192), partial(Handler, directory=str(ROOT / "build/web")))
    print("Resource Feedback R1 isolated server: http://127.0.0.1:4192/resource-setup", flush=True)
    server.serve_forever()
