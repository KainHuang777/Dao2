"""Only serves an isolated acceptance export on loopback."""
from http.server import ThreadingHTTPServer
from pathlib import Path
from web_static_server import CompressedStaticHandler,prewarm
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--port',type=int,default=48810)
args=parser.parse_args()
folder=Path(__file__).resolve().parent.parent/'build/hud-readiness-acceptance'
class Handler(CompressedStaticHandler):
    gzip_enabled=True
    def __init__(self,*a,**kw):super().__init__(*a,directory=str(folder),**kw)
prewarm(folder,Handler)
print(f'HUD isolated fixture http://127.0.0.1:{args.port}/index.html',flush=True)
ThreadingHTTPServer(('127.0.0.1',args.port),Handler).serve_forever()
