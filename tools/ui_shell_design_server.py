"""Read-only local design preview. Only expose this proposal and existing image/font assets."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse, unquote
import argparse

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / 'docs/visual-prototype/ui-shell-design'

class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        clean = unquote(urlparse(path).path)
        base = ROOT / 'assets' if clean.startswith('/assets/') else DESIGN
        relative = clean.removeprefix('/assets/') if base != DESIGN else clean.lstrip('/')
        target = (base / (relative or 'index.html')).resolve()
        allowed = target.is_relative_to(base.resolve())
        allowed = allowed and (target.suffix.lower() in {'.html', '.png', '.ttf', '.jpg', '.svg'})
        return str(target if allowed else DESIGN / '__not_allowed__')

    def list_directory(self, path):
        self.send_error(403)
        return None

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4391)
    args = parser.parse_args()
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
