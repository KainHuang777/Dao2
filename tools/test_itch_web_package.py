"""Isolated regression tests for stale/tampered/unsafe deployment payloads."""
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

import itch_web_package as package


class ItchPackageTest(unittest.TestCase):
    def setUp(self):
        test_output = Path(__file__).resolve().parents[1] / '.test-output'
        test_output.mkdir(exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(prefix='itch-unit-', dir=test_output)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.web = self.root / 'build/itch-web'
        self.web.mkdir(parents=True)
        self.output = self.root / 'build/game.zip'
        for name in ('project.godot', 'export_presets.cfg', 'src/game.gd'):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('fixture', encoding='utf-8')
        for name in package.REQUIRED + package.OPTIONAL:
            (self.web / name).write_bytes(b'exported fixture')
        tracks = [{'filename': f'0{i}_Track.mp3'} for i in range(1, 5)]
        catalog = self.root / 'assets/audio/bgm/library.json'
        catalog.parent.mkdir(parents=True)
        catalog.write_text(json.dumps(tracks), encoding='utf-8')
        for track in tracks:
            for path in (self.web / 'audio/bgm' / track['filename'], self.root / 'src/BGM' / track['filename']):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b'audio fixture')

    def pack(self):
        return package.pack(self.root, self.web, self.output, 'test-1', package.fingerprint(self.root))

    def test_roundtrip_contains_only_runtime_files(self):
        for name in ('.env', 'debug.log', 'compression.json', 'index.pck.br', 'internal.json'):
            (self.web / name).write_text('must not upload', encoding='utf-8')
        report = self.pack()
        self.assertEqual(package.verify(self.root, self.output), report)
        with zipfile.ZipFile(self.output) as archive:
            self.assertIn('index.html', archive.namelist())
            self.assertEqual(len(archive.namelist()), 13)
            self.assertFalse(any(n.endswith(('.env', '.log', '.json', '.br')) for n in archive.namelist()))

    def test_tampered_zip_rejected(self):
        self.pack()
        with self.output.open('ab') as stream:
            stream.write(b'tampered')
        with self.assertRaisesRegex(ValueError, 'ZIP digest'):
            package.verify(self.root, self.output)

    def test_stale_source_rejected(self):
        self.pack()
        (self.root / 'src/game.gd').write_text('new game source', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Stale source'):
            package.verify(self.root, self.output)

    def test_changed_export_rejected(self):
        self.pack()
        (self.web / 'index.pck').write_bytes(b'new export')
        with self.assertRaisesRegex(ValueError, 'Payload digest'):
            package.verify(self.root, self.output)

    def test_source_change_during_export_keeps_previous_zip(self):
        self.pack()
        previous = package.sha(self.output)
        fingerprint = package.fingerprint(self.root)
        (self.root / 'project.godot').write_text('changed', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Source changed'):
            package.pack(self.root, self.web, self.output, 'test-2', fingerprint)
        self.assertEqual(package.sha(self.output), previous)

    def test_missing_audio_rejected(self):
        (self.web / 'audio/bgm/01_Track.mp3').unlink()
        with self.assertRaises(OSError):
            self.pack()

    def test_output_cannot_escape_build(self):
        with self.assertRaisesRegex(ValueError, 'inside project build'):
            package.pack(self.root, self.web, self.root / 'outside.zip', 'v1', package.fingerprint(self.root))

    def test_html5_limits_and_unsafe_paths_rejected(self):
        for entries in ([('../secret', 1)], [('C:/secret', 1)], [('a\\b', 1)],
                        [('a', 1), ('A', 1)], [('a', package.MAX_FILE + 1)],
                        [('x' * 241, 1)], [('a', 0)],
                        [(str(i), 1) for i in range(1001)],
                        [('a', 200_000_000), ('b', 200_000_000), ('c', 200_000_000)]):
            with self.subTest(entries=str(entries)[:80]), self.assertRaises(ValueError):
                package.validate_entries(entries)


if __name__ == '__main__':
    unittest.main()
