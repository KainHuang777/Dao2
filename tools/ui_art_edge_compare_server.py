"""Local visual comparison; allow only the prototype and existing asset files."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import unquote, urlparse
import argparse
ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / 'docs/visual-prototype/ui-art-edge-compare'
class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        clean = unquote(urlparse(path).path)
        base = ROOT / 'assets' if clean.startswith('/assets/') else DESIGN
        relative = clean.removeprefix('/assets/') if base != DESIGN else clean.lstrip('/')
        target = (base / (relative or 'index.html')).resolve()
        return str(target if target.is_relative_to(base.resolve()) and target.suffix.lower() in {'.html','.png','.ttf','.svg'} else DESIGN / '__not_allowed__')
    def list_directory(self, path):
        self.send_error(403)
        return None
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4421)
    args = parser.parse_args()
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
