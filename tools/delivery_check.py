"""Generic delivery check: replaces per-task *_closure/_audit scripts.

Prints a grouped summary instead of per-file counters. Read-only.

  python tools/delivery_check.py                       # git change summary + evidence guard
  python tools/delivery_check.py --web build/web-xxx   # also verify compression.json hashes
  python tools/delivery_check.py --manifest assets/ui/foo/manifest.json  # acceptance + PNG hashes
Exit code 1 when any check fails.
"""
from collections import Counter
from pathlib import Path
import argparse, hashlib, json, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ['docs/verification/artifacts', 'src/verification']


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True, encoding='utf-8', errors='replace')


def read_json(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def check_git(fails):
    rows = [l for l in git('status', '--porcelain').splitlines() if l.strip()]
    groups = Counter()
    for l in rows:
        path = l[3:].strip().strip('"')
        parts = path.split('/')
        groups['/'.join(parts[:2]) if len(parts) > 2 else parts[0]] += 1
    print(f'[git] {len(rows)} changed entries; head={git("rev-parse", "--short", "HEAD").strip()}')
    for k, v in groups.most_common(12):
        print(f'      {v:5d}  {k}')
    ev = [l for l in rows if any(l[3:].strip().strip('"').startswith(e) for e in EVIDENCE)]
    print(f'[evidence] changed entries under {EVIDENCE}: {len(ev)} (compare with expected for this task)')


def check_web(d, fails):
    d = ROOT / d
    pkg = read_json(d / 'compression.json')
    bad = []
    for row in pkg['files']:
        if sha(d / row['file']) != row['sha256']:
            bad.append(row['file'])
        br = d / (row['file'] + '.br')
        if 'br_sha256' in row and (not br.exists() or sha(br) != row['br_sha256']):
            bad.append(row['file'] + '.br')
    for row in pkg.get('audioFiles', []):
        if sha(d / row['file']) != row['sha256']:
            bad.append(row['file'])
    total = len(pkg['files']) + len(pkg.get('audioFiles', []))
    print(f'[web] {d.name}: {total - len(bad)}/{total} files match compression.json')
    if bad:
        fails.append('web hash mismatch: ' + ', '.join(bad[:5]))


def check_manifest(path, fails):
    p = ROOT / path
    obj = read_json(p)
    ok = obj.get('acceptance') == 'ACCEPTED'
    bad = [a['id'] for a in obj.get('assets', []) if not (sha(ROOT / a['runtime']) == sha(ROOT / a['original']) == a['sha256'])]
    print(f'[manifest] {p.name}: acceptance={obj.get("acceptance")}, assets ok={len(obj.get("assets", [])) - len(bad)}/{len(obj.get("assets", []))}')
    if not ok:
        fails.append(f'{path}: not ACCEPTED')
    if bad:
        fails.append(f'{path}: PNG hash mismatch {bad}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--web', action='append', default=[])
    ap.add_argument('--manifest', action='append', default=[])
    a = ap.parse_args()
    fails = []
    check_git(fails)
    for w in a.web:
        check_web(w, fails)
    for m in a.manifest:
        check_manifest(m, fails)
    print('RESULT', 'FAIL ' + '; '.join(fails) if fails else 'PASS')
    sys.exit(1 if fails else 0)


if __name__ == '__main__':
    main()
