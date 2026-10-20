"""Isolated EARLY-V1-B UI evidence; funded fixture, no player origin access."""
import argparse
from http.server import ThreadingHTTPServer
import island_preview_server as preview

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=48935)
parser.add_argument('--zero', action='store_true')
args = parser.parse_args()
preview.BUILD = preview.ROOT / 'build/web-early-v1b'
preview.FIXTURE = preview.ROOT / 'docs/verification/artifacts/early-v1-b/web-fixture.json'
if args.zero:
    preview.FIXTURE = preview.ROOT / 'docs/verification/artifacts/early-v1-b/web-zero-fixture.json'
preview.NAMESPACE = 'dao2_saves'
preview.METRICS_LOG = preview.ROOT / 'docs/verification/artifacts/early-v1-b/web-evidence.jsonl'
preview.PAGE = preview.PAGE.replace('dao2_islands_preview', 'dao2_saves').replace('RES1-C 三島隔離驗收', 'EARLY-V1-B 天賦隔離驗收').replace('載入從空白命令走出的築基測試檔', '載入注資壽盡診斷檔').replace('已載入命令生成築基檔；開拓／加工尚未啟用。', '注資／壽盡 fixture，只驗介面，不證明自然流程。').replace('不讀玩家dao2_saves。', '不讀其他origin玩家進度。').replace("'/index.html'", "'/fault.html'")
preview.PAGE += '''<details style="position:fixed;right:0;bottom:0;background:white;z-index:20;max-width:48vw;max-height:180px;overflow:auto"><summary>天賦存檔證據</summary><pre id="evidence"></pre><button id="capture">記錄存檔證據</button></details><script>
function evidence(){const i=JSON.parse(localStorage.getItem('dao2_saves:save_index'));if(!i)return {};const e=JSON.parse(localStorage.getItem('dao2_saves:'+i.active_slot));const s=e.state;return {revision:e.revision,era:s.era_id,level:s.level,talents:s.talents,dao_heart:s.dao_heart,reincarnation_count:s.reincarnation_count,elapsed:s.total_elapsed_seconds,training:s.training_seconds,resources:s.resources,buildings:s.buildings,realms_data:s.realms_data,receipts:s.command_receipts};}
setInterval(()=>{try{document.getElementById('evidence').textContent=JSON.stringify(evidence(),null,2)}catch(e){}},1000);
document.getElementById('capture').onclick=()=>fetch('/metrics-evidence',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({kind:'manual-ui-snapshot',evidence:evidence()})});
</script>'''
preview.prewarm(preview.BUILD, preview.Handler)
print(f'EARLY-V1-B http://127.0.0.1:{args.port}/launcher', flush=True)
ThreadingHTTPServer(('127.0.0.1', args.port), preview.Handler).serve_forever()
