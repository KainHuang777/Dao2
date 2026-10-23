"""Isolated UI-SHELL desktop review harness. No player origin is accessed."""
from pathlib import Path
from http.server import ThreadingHTTPServer
from web_static_server import CompressedStaticHandler
import argparse

PAGE = '''<!doctype html><meta charset="utf-8"><title>UI-SHELL isolated fixture</title>
<style>html,body{margin:0;background:#ddd;font:14px sans-serif}button{min-height:44px}iframe{display:block;border:0}#state{display:block;white-space:pre-wrap;max-width:1280px;height:64px;overflow:auto}</style>
<button onclick="resizeGame(1280,720)">1280×720</button><button onclick="resizeGame(844,390)">844×390</button><button onclick="resizeGame(800,360)">800×360</button>
<button onclick="shellFail=true;this.textContent='拒寫中'">拒寫</button><button onclick="shellFail=false">恢復寫入</button>
<span>隔離測試材料；不是自然進度</span><output id="state">載入中</output>
<iframe id="game" title="Godot 正式場景" width="1280" height="720" src="/index.html"></iframe>
<script>window.shellFail=false;function resizeGame(w,h){let f=document.getElementById('game');f.width=w;f.height=h}</script>'''

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4391)
    parser.add_argument('--build', default='build/ui-shell-acceptance')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    build = (root / args.build).resolve()
    if not build.is_relative_to(root / 'build'):
        parser.error('build must stay within project build directory')
    class Handler(CompressedStaticHandler):
        gzip_enabled = True
        def __init__(self, *a, **kw): super().__init__(*a, directory=str(build), **kw)
        def do_GET(self):
            if self.path == '/review':
                body = PAGE.encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Content-Length', str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            else: super().do_GET()
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()

if __name__ == '__main__': main()
