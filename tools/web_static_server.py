"""Godot static HTTP server with negotiated gzip; never rewrites exports.

python tools/web_static_server.py --port 4175 --directory build/web
The same handler is used by isolated preview/performance verification.
"""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import gzip
import io
import threading
import json
import hashlib

class CompressedStaticHandler(SimpleHTTPRequestHandler):
    gzip_enabled = True
    _cache = {}
    _cache_lock = threading.Lock()
    _brotli = {}
    COMPRESSIBLE = {'.wasm', '.pck', '.js', '.html', '.json', '.svg', '.css', '.txt'}

    @classmethod
    def compressed(cls, path):
        path = Path(path)
        stat = path.stat()
        key = (str(path.resolve()), stat.st_mtime_ns, stat.st_size)
        with cls._cache_lock:
            if key not in cls._cache:
                # Bound cache to current files if an export is regenerated.
                cls._cache = {k: v for k, v in cls._cache.items() if k[0] != key[0]}
                cls._cache[key] = gzip.compress(path.read_bytes(), compresslevel=6, mtime=0)
            return cls._cache[key]

    def send_head(self):
        path = Path(self.translate_path(self.path))
        br = self._brotli.get(str(path.resolve()))
        if br and path.is_file() and self.accepts_encoding('br') and not self.headers.get('Range'):
            stat = path.stat()
            if (stat.st_mtime_ns, stat.st_size) == br['source_stamp']:
                data = br['data']
                self.send_response(200)
                self.send_header('Content-Type', self.guess_type(str(path)))
                self.send_header('Content-Encoding', 'br')
                self.send_header('Vary', 'Accept-Encoding')
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                return io.BytesIO(data)
        if not (self.gzip_enabled and path.is_file() and path.suffix in self.COMPRESSIBLE
                and self.accepts_gzip() and not self.headers.get('Range')):
            return super().send_head()
        data = self.compressed(path)
        self.send_response(200)
        self.send_header('Content-Type', self.guess_type(str(path)))
        self.send_header('Content-Encoding', 'gzip')
        self.send_header('Vary', 'Accept-Encoding')
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Last-Modified', self.date_time_string(path.stat().st_mtime))
        self.end_headers()
        return io.BytesIO(data)

    def accepts_gzip(self):
        return self.accepts_encoding('gzip')

    def accepts_encoding(self, encoding):
        # Explicit q=0 means uncompressed, including wildcard negotiation.
        accepted = {}
        for item in self.headers.get('Accept-Encoding', '').split(','):
            parts = item.strip().lower().split(';')
            quality = 1.0
            for part in parts[1:]:
                if part.strip().startswith('q='):
                    try:
                        quality = float(part.strip()[2:])
                    except ValueError:
                        quality = 0.0
            accepted[parts[0]] = quality
        return accepted.get(encoding, accepted.get('*', 0.0)) > 0.0

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

def prewarm(directory, handler=CompressedStaticHandler):
    directory = Path(directory)
    manifest = directory / 'compression.json'
    if handler.gzip_enabled and manifest.exists():
        for entry in json.loads(manifest.read_text(encoding='utf-8'))['files']:
            if entry['file'] not in ('index.js', 'index.wasm', 'index.pck'):
                raise ValueError('Unexpected compression companion')
            source = directory / entry['file']
            companion = directory / (entry['file'] + '.br')
            data = companion.read_bytes()
            if hashlib.sha256(source.read_bytes()).hexdigest() == entry['sha256'] and hashlib.sha256(data).hexdigest() == entry['br_sha256']:
                stat = source.stat()
                handler._brotli[str(source.resolve())] = {'data':data, 'source_stamp':(stat.st_mtime_ns, stat.st_size)}
            else:
                print(f'Stale companion: {entry["file"]}; using gzip', flush=True)
    if handler.gzip_enabled:
        for path in directory.iterdir():
            if path.is_file() and path.suffix in handler.COMPRESSIBLE:
                handler.compressed(path)

if __name__ == '__main__':
    import argparse
    from functools import partial
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4175)
    parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parent.parent / 'build/web')
    parser.add_argument('--no-gzip', action='store_true')
    args = parser.parse_args()
    CompressedStaticHandler.gzip_enabled = not args.no_gzip
    prewarm(args.directory)
    print(f'Web: http://127.0.0.1:{args.port}/index.html gzip={not args.no_gzip}', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), partial(CompressedStaticHandler, directory=str(args.directory))).serve_forever()
