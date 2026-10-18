"""Loopback R11 acceptance fixture, separate from normal player origin."""
from http.server import ThreadingHTTPServer
import island_preview_server as server
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--port',type=int,default=48830)
args=parser.parse_args()
server.BUILD=server.ROOT/'build/r11-acceptance'
server.NAMESPACE='dao2_saves'
server.PAGE=server.PAGE.replace('dao2_islands_preview','dao2_saves').replace('RES1-C 三島隔離驗收','R11 天道決策隔離驗收')
server.Handler.gzip_enabled=True
server.prewarm(server.BUILD,server.Handler)
print(f'R11 isolated fixture http://127.0.0.1:{args.port}/launcher',flush=True)
ThreadingHTTPServer(('127.0.0.1',args.port),server.Handler).serve_forever()
