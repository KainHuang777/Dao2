"""Local, read-only ATM-LIFE-DESIGN review server; no player data."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit
import argparse

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / 'docs/visual-prototype/atm-life-design'

class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        clean = unquote(urlsplit(path).path)
        asset = clean.startswith('/assets/')
        base = ROOT / 'assets' if asset else DESIGN
        relative = clean[len('/assets/'):] if asset else clean.lstrip('/')
        target = (base / (relative or 'index.html')).resolve()
        allowed = target.is_relative_to(base.resolve()) and target.suffix in {'.html', '.json', '.js', '.css', '.png', '.ttf'}
        return str(target if allowed else DESIGN / '__denied__')

    def list_directory(self, path):
        self.send_error(403)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4395)
    args = parser.parse_args()
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
