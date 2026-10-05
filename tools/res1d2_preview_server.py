"""Serve the normal D2 export and command-earned fixture on a fresh local origin."""
import island_preview_server as preview

preview.BUILD = preview.ROOT / 'build' / 'res1d2'
preview.FIXTURE = preview.ROOT / 'docs/verification/artifacts/res1-d2-earned-era3.json'
preview.NAMESPACE = 'dao2_saves'
preview.PAGE = preview.PAGE.replace('dao2_islands_preview', 'dao2_saves').replace('RES1-C 三島隔離驗收', 'RES1-D2 隔離驗收').replace('築基測試檔', '金丹測試檔').replace('命令生成築基檔；開拓／加工尚未啟用', '命令生成金丹檔；丹霞已開拓，使用隔離進度').replace('不讀玩家dao2_saves。', '此獨立origin不讀其他origin玩家進度。')

if __name__ == '__main__':
    preview.ThreadingHTTPServer(('127.0.0.1', 4256), preview.Handler).serve_forever()
