"""Separate D2-R1 origin/build; preserve D2 and AGY servers and progress."""
import argparse
import res1d2_preview_server as d2

preview = d2.preview
preview.BUILD = preview.ROOT / 'build' / 'res1d2r1'
preview.PAGE = preview.PAGE.replace('RES1-D2 隔離驗收', 'RES1-D2-R1 丹霞世界驗收').replace('三島Godot預覽', '丹霞Godot預覽')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4257)
    args = parser.parse_args()
    print(f'D2-R1 isolated normal Web: http://127.0.0.1:{args.port}/launcher', flush=True)
    preview.ThreadingHTTPServer(('127.0.0.1', args.port), preview.Handler).serve_forever()
