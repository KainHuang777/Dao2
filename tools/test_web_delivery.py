"""Real HTTP byte/header checks for the exported companions; stdlib only."""
from pathlib import Path
import argparse
import gzip
import hashlib
import http.client
import json

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, required=True)
args = parser.parse_args()
records = []
for encoding in ('br,gzip', 'gzip', 'br;q=0,gzip;q=0'):
    for name in ('index.js', 'index.wasm', 'index.pck'):
        connection = http.client.HTTPConnection('127.0.0.1', args.port, timeout=30)
        connection.request('GET', '/'+name, headers={'Accept-Encoding':encoding})
        response = connection.getresponse()
        body = response.read()
        actual = response.getheader('Content-Encoding')
        original = (root/'build/web'/name).read_bytes()
        assert response.status == 200
        assert int(response.getheader('Content-Length')) == len(body)
        if encoding == 'br,gzip':
            assert actual == 'br' and body == (root/'build/web'/(name+'.br')).read_bytes()
        elif encoding == 'gzip':
            assert actual == 'gzip' and gzip.decompress(body) == original
        else:
            assert actual is None and body == original
        records.append({'name':name, 'requested':encoding, 'encoding':actual,
                        'bytes':len(body), 'sha256':hashlib.sha256(body).hexdigest()})
        connection.close()
for entry in json.loads((root/'build/web/compression.json').read_text(encoding='utf-8'))['audioFiles']:
    connection = http.client.HTTPConnection('127.0.0.1', args.port, timeout=30)
    connection.request('GET', '/'+entry['file'])
    response = connection.getresponse()
    body = response.read()
    assert response.status == 200 and hashlib.sha256(body).hexdigest() == entry['sha256']
    records.append({'name':entry['file'], 'bytes':len(body), 'source_sha256':entry['sha256']})
    connection.close()
print(json.dumps({'ok':True, 'cases':records}))
