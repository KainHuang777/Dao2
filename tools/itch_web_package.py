"""Reusable itch payload packaging and verification; stdlib, no credentials."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ('index.html', 'index.js', 'index.wasm', 'index.pck')
OPTIONAL = ('index.audio.worklet.js', 'index.audio.position.worklet.js',
            'index.icon.png', 'index.apple-touch-icon.png', 'index.png')
MAX_FILE = 200_000_000
MAX_TOTAL = 500_000_000


def sha(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def fingerprint(root: Path) -> str:
    files = [root / n for n in ('project.godot', 'export_presets.cfg')]
    for name in ('src', 'scenes', 'assets', 'content'):
        files.extend(p for p in (root / name).rglob('*') if p.is_file())
    result = hashlib.sha256()
    for path in sorted(files, key=lambda p: p.relative_to(root).as_posix()):
        if path.is_symlink():
            raise ValueError('Source symlinks are not supported')
        result.update(path.relative_to(root).as_posix().encode('utf-8') + b'\0')
        result.update(sha(path).encode('ascii') + b'\n')
    return result.hexdigest()


def in_build(root: Path, path: Path) -> Path:
    path = path.resolve()
    build = (root / 'build').resolve()
    if path == build or not path.is_relative_to(build):
        raise ValueError('Expected a file or subdirectory inside project build/')
    return path


def payload_names(root: Path, web: Path) -> list[str]:
    names = list(REQUIRED)
    names += [n for n in OPTIONAL if (web / n).is_file()]
    tracks = json.loads((root / 'assets/audio/bgm/library.json').read_text(encoding='utf-8-sig'))
    if len(tracks) != 4:
        raise ValueError('Expected the four project BGM companions')
    for track in tracks:
        name = track['filename']
        if not re.fullmatch(r'0[1-4]_[A-Za-z_]+\.mp3', name):
            raise ValueError('Invalid BGM filename')
        relative = 'audio/bgm/' + name
        if sha(web / relative) != sha(root / 'src/BGM' / name):
            raise ValueError('BGM companion differs from source: ' + name)
        names.append(relative)
    for name in names:
        path = web / name
        if not path.is_file() or path.is_symlink() or not path.resolve().is_relative_to(web):
            raise ValueError('Missing or unsafe payload file: ' + name)
    return sorted(names)


def validate_entries(entries: list[tuple[str, int]]) -> None:
    if len(entries) > 1000 or len({n.casefold() for n, _ in entries}) != len(entries):
        raise ValueError('Too many files or duplicate archive paths')
    for name, size in entries:
        p = PurePosixPath(name)
        if p.is_absolute() or '..' in p.parts or '\\' in name or ':' in name or len(name) > 240:
            raise ValueError('Unsafe or overlong archive path: ' + name)
        if size > MAX_FILE or size <= 0:
            raise ValueError('Empty or oversized payload file: ' + name)
    if sum(size for _, size in entries) > MAX_TOTAL:
        raise ValueError('HTML5 extracted size exceeds 500 MB')


def pack(root: Path, web: Path, output: Path, version: str, expected: str) -> dict:
    web, output = in_build(root, web), in_build(root, output)
    if not version or fingerprint(root) != expected:
        raise ValueError('Source changed during export; export again')
    names = payload_names(root, web)
    validate_entries([(n, (web / n).stat().st_size) for n in names])
    if output.is_relative_to(web):
        raise ValueError('Keep the ZIP outside the export directory')
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + '.tmp')
    try:
        with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
            for name in names:
                z.write(web / name, name)
        records = [{'file': n, 'bytes': (web / n).stat().st_size, 'sha256': sha(web / n)} for n in names]
        if fingerprint(root) != expected:
            raise ValueError('Source changed during packaging; export again')
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)
    report = {'schema': 1, 'version': version, 'target': 'kainhuang/dao-ascendant:html5',
              'source_fingerprint': expected, 'web_dir': web.relative_to(root).as_posix(),
              'zip_sha256': sha(output), 'zip_bytes': output.stat().st_size, 'files': records}
    manifest = output.with_suffix('.manifest.json')
    tmp_manifest = manifest.with_suffix('.json.tmp')
    tmp_manifest.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    os.replace(tmp_manifest, manifest)
    return report


def verify(root: Path, output: Path) -> dict:
    output = in_build(root, output)
    report = json.loads(output.with_suffix('.manifest.json').read_text(encoding='utf-8'))
    if report['schema'] != 1 or fingerprint(root) != report['source_fingerprint']:
        raise ValueError('Stale source fingerprint; create a fresh export')
    if sha(output) != report['zip_sha256']:
        raise ValueError('ZIP digest mismatch')
    web = in_build(root, root / report['web_dir'])
    expected = {row['file']: row for row in report['files']}
    if set(expected) != set(payload_names(root, web)):
        raise ValueError('Manifest payload differs from the export')
    with zipfile.ZipFile(output) as z:
        validate_entries([(i.filename, i.file_size) for i in z.infolist()])
        if set(z.namelist()) != set(expected):
            raise ValueError('Archive entries differ from manifest')
        for name, row in expected.items():
            with z.open(name) as stream:
                archive_sha = hashlib.file_digest(stream, 'sha256').hexdigest()
            if archive_sha != row['sha256'] or sha(web / name) != archive_sha:
                raise ValueError('Payload digest mismatch: ' + name)
        if z.testzip() is not None:
            raise ValueError('ZIP CRC mismatch')
    return report


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest='command', required=True)
    sub.add_parser('fingerprint')
    p = sub.add_parser('pack')
    p.add_argument('--web-dir', type=Path, required=True)
    p.add_argument('--zip', type=Path, required=True)
    p.add_argument('--version', required=True)
    p.add_argument('--source-fingerprint', required=True)
    p = sub.add_parser('verify')
    p.add_argument('--zip', type=Path, required=True)
    args = ap.parse_args()
    if args.command == 'fingerprint':
        print(fingerprint(ROOT))
        return
    if args.command == 'pack':
        report = pack(ROOT, args.web_dir, args.zip, args.version, args.source_fingerprint)
    else:
        report = verify(ROOT, args.zip)
    print(f'[ITCH] {args.command} PASS; version={report["version"]}; '
          f'files={len(report["files"])}; zip={report["zip_bytes"]} bytes; sha256={report["zip_sha256"]}')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, KeyError, zipfile.BadZipFile) as error:
        print('[ITCH] FAIL: ' + str(error), file=sys.stderr)
        sys.exit(1)
