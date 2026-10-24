"""Converter contract checks using a temporary miniature project only."""
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


class ViewportGateTests(unittest.TestCase):
    def test_first_pass_and_repeat_preserve_gate(self):
        with tempfile.TemporaryDirectory(prefix='dao2_gate_', dir=pathlib.Path(__file__).resolve().parents[1] / 'build') as tmp:
            root = pathlib.Path(tmp)
            (root / 'tools').mkdir()
            (root / 'tests').mkdir()
            script = root / 'tools/apply_viewport_matrix_gate.py'
            shutil.copyfile(pathlib.Path(__file__).with_name(script.name), script)
            fixture = root / 'tests/example.gd'
            fixture.write_text('for vp in [Vector2(1280,720), Vector2(844,390)]:\n\tpass\n', encoding='utf-8')
            first = subprocess.run([sys.executable, str(script)], capture_output=True, text=True, check=True)
            self.assertIn('TOTAL 1', first.stdout)
            once = fixture.read_bytes()
            self.assertEqual(once.count(b'DAO_VIEWPORT_MATRIX'), 1)
            self.assertIn(b'else [Vector2(1280,720)]', once)
            second = subprocess.run([sys.executable, str(script)], capture_output=True, text=True, check=True)
            self.assertIn('TOTAL 0', second.stdout)
            self.assertEqual(fixture.read_bytes(), once)


if __name__ == '__main__':
    unittest.main()
