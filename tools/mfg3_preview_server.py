"""Serve only the MFG-3 candidate on an isolated loopback origin.

The launcher explicitly seeds a funded diagnostic fixture; this is UI evidence,
not natural progression. Existing origin saves are never overwritten.
"""
import argparse
from http.server import ThreadingHTTPServer
import island_preview_server as preview

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=48933)
    args = parser.parse_args()
    preview.BUILD = preview.ROOT / 'build/web-mfg3'
    preview.FIXTURE = preview.ROOT / 'docs/verification/artifacts/mfg-3/fixture.json'
    preview.NAMESPACE = 'dao2_saves'
    preview.METRICS_LOG = preview.ROOT / 'docs/verification/artifacts/mfg-3/browser-metrics.jsonl'
    preview.PAGE = preview.PAGE.replace('dao2_islands_preview', 'dao2_saves').replace('RES1-C 三島隔離驗收', 'MFG-3 製造介面隔離驗收').replace('載入從空白命令走出的築基測試檔', '載入 MFG-3 診斷測試檔').replace('已載入命令生成築基檔；開拓／加工尚未啟用。', '已載入注資診斷檔；僅驗介面，不證明自然流程。').replace('不讀玩家dao2_saves。', '獨立origin，不讀其他origin玩家進度。')
    # Read-only, visible diagnostics from the real saved slot, outside the game.
    preview.PAGE += '''<details style="position:fixed;right:0;bottom:0;background:white;max-width:45vw;max-height:140px;overflow:auto;z-index:9"><summary>隔離存檔證據</summary><pre id="mfg-evidence"></pre></details>
<script>setInterval(()=>{try{const i=JSON.parse(localStorage.getItem('dao2_saves:save_index'));if(!i)return;const s=JSON.parse(localStorage.getItem('dao2_saves:'+i.active_slot));document.getElementById('mfg-evidence').textContent=JSON.stringify({revision:s.revision,jobs:s.state.economy.jobs,wood:s.state.economy.islands.wood.inventory,receipts:Object.values(s.state.command_receipts||{}).slice(-3)},null,2);}catch(e){document.getElementById('mfg-evidence').textContent=String(e);}},500);</script>'''
    preview.prewarm(preview.BUILD, preview.Handler)
    print(f'MFG-3: http://127.0.0.1:{args.port}/launcher', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), preview.Handler).serve_forever()
