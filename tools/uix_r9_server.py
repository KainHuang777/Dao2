"""Isolated R9 export; existing launcher and storage fault controls only."""
from http.server import ThreadingHTTPServer
import island_preview_server as server
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--port',type=int,default=48779)
args=parser.parse_args()
server.BUILD=server.ROOT/'build/r9-acceptance'
server.NAMESPACE='dao2_saves'
server.PAGE=server.PAGE.replace('dao2_islands_preview','dao2_saves').replace('RES1-C 三島隔離驗收','R9 宗門隔離驗收')
server.Handler.gzip_enabled=True
server.prewarm(server.BUILD,server.Handler)
print(f'R9 isolated fixture http://127.0.0.1:{args.port}/launcher',flush=True)
ThreadingHTTPServer(('127.0.0.1',args.port),server.Handler).serve_forever()
