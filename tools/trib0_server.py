"""Loopback-only isolated TRIB-0 fixture; normal saves are on another origin."""
from http.server import ThreadingHTTPServer
import argparse
import island_preview_server as server
parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=48930)
args = parser.parse_args()
server.BUILD = server.ROOT / 'build/trib0-acceptance'
server.NAMESPACE = 'dao2_saves'
server.Handler.gzip_enabled = True
server.prewarm(server.BUILD, server.Handler)
print(f'TRIB-0 isolated http://127.0.0.1:{args.port}/fault.html', flush=True)
ThreadingHTTPServer(('127.0.0.1', args.port), server.Handler).serve_forever()
