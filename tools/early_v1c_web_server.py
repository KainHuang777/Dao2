"""Isolated candidate origin; funded skill UI evidence, never player saves."""
import argparse
from http.server import ThreadingHTTPServer
import island_preview_server as preview

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=48937)
args = parser.parse_args()
preview.BUILD = preview.ROOT / 'build/web-early-v1c'
preview.FIXTURE = preview.ROOT / 'docs/verification/artifacts/early-v1-c/web-fixture.json'
preview.NAMESPACE = 'dao2_saves'
preview.METRICS_LOG = preview.ROOT / 'docs/verification/artifacts/early-v1-c/browser-evidence.jsonl'
preview.PAGE = preview.PAGE.replace('dao2_islands_preview', 'dao2_saves').replace('RES1-C 三島隔離驗收', 'EARLY-V1-C 技能隔離驗收').replace('載入從空白命令走出的築基測試檔', '載入注資技能診斷檔').replace('已載入命令生成築基檔；開拓／加工尚未啟用。', 'Era3／8060點／築基法1／儲物法寶3 fixture；非自然流程。').replace('不讀玩家dao2_saves。', '不讀其他origin玩家進度。').replace("'/index.html'", "'/fault.html'")
preview.PAGE += '''<details style="position:fixed;right:0;bottom:0;background:white;z-index:20;max-width:45vw;max-height:200px;overflow:auto"><summary>技能存檔證據</summary><pre id="evidence"></pre><button id="capture">記錄存檔證據</button></details><script>
function evidence(){const i=JSON.parse(localStorage.getItem('dao2_saves:save_index'));if(!i)return {};const e=JSON.parse(localStorage.getItem('dao2_saves:'+i.active_slot));const s=e.state;return {revision:e.revision,era:s.era_id,skills:s.skills,points:s.resources.skill_point.value,sect:s.sect.techniques,receipts:s.command_receipts};}
setInterval(()=>{try{document.getElementById('evidence').textContent=JSON.stringify(evidence(),null,2)}catch(e){}},500);
document.getElementById('capture').onclick=()=>fetch('/metrics-evidence',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({kind:'manual-mouse-snapshot',evidence:evidence()})});
</script>'''
preview.prewarm(preview.BUILD, preview.Handler)
print(f'EARLY-V1-C http://127.0.0.1:{args.port}/launcher', flush=True)
ThreadingHTTPServer(('127.0.0.1', args.port), preview.Handler).serve_forever()
