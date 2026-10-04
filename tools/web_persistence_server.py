"""Isolated browser matrix. Test probe/actions never enter the Web release export."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent.parent
PORT = 4196
LIVE = r'''
<aside style="position:fixed;top:0;right:80px;z-index:9999;background:#fff;color:#123;font:14px sans-serif;padding:8px;max-width:240px;overflow-wrap:anywhere">
<button id="restore" onclick="window.liveFault='';history.replaceState(null,'',location.pathname);document.getElementById('fault').textContent='正常儲存'">恢復儲存</button>
<button id="deny" onclick="window.liveFault='write';document.getElementById('fault').textContent='拒絕寫入'">拒絕寫入</button>
<span id="fault"></span><pre id="live-report">隔離正式遊戲驗證</pre></aside>
<script>
window.liveFault = new URLSearchParams(location.search).get('fault') || '';
window.pauseFrames=false;
const nativeFrame=window.requestAnimationFrame.bind(window), heldFrames=[];
window.requestAnimationFrame=function(callback){return nativeFrame(t=>{if(window.pauseFrames)heldFrames.push(callback);else callback(t)})};
document.getElementById('fault').textContent = window.liveFault || '正常儲存';
const originalGet=Storage.prototype.getItem, originalSet=Storage.prototype.setItem;
Storage.prototype.getItem=function(k){if(k.startsWith('dao2_saves:') && window.liveFault==='read') throw new DOMException('Test read denial','SecurityError');return originalGet.call(this,k)};
Storage.prototype.setItem=function(k,v){if(k.startsWith('dao2_saves:') && (window.liveFault==='write' || window.liveFault==='read')) throw new DOMException('Test write denial','SecurityError');return originalSet.call(this,k,v)};
const log=console.log;
console.log=function(...args){log.apply(console,args); if(args.join(' ').includes('WEB_BACKGROUND')) {document.getElementById('live-report').textContent=args.join(' ');parent.postMessage({report:args.join(' ')},location.origin)}};
window.addEventListener('message',e=>{if(e.origin!==location.origin || !e.data)return;if(e.data.setfault!==undefined){window.liveFault=e.data.setfault;document.getElementById('fault').textContent=window.liveFault || '正常儲存'}if(e.data.pauseframes!==undefined){window.pauseFrames=e.data.pauseframes;if(!window.pauseFrames)heldFrames.splice(0).forEach(callback=>nativeFrame(callback))}});
document.addEventListener('visibilitychange',()=>{console.log('LIVE_VISIBILITY:',document.visibilityState)});
</script>
'''
INSTRUMENT = r'''
<style>#canvas{display:none} body{overflow:auto!important;background:#f3eddc;color:#182f33;font:18px sans-serif;padding:24px} #report{white-space:pre-wrap} #status{display:none!important} a,button{display:inline-block;padding:12px;margin:8px}</style>
<h1>RES1-B / M1-C/D Web 保存驗證</h1>
<p>隔離 origin 4196；測試專用，不含玩家進度。localStorage 為權威儲存。</p>
<nav><a href="/?case=retry">故障重試</a><a href="/?case=reload">重載</a><a href="/?case=corrupt">損壞復原</a><a href="/?case=denied">拒絕讀取</a><a href="/?case=migration">schema2 遷移</a><a href="/?case=cap">48h 上限</a><a href="/?case=lock">雙分頁鎖</a><a href="/?case=actualquota">實際 quota</a><a href="/release/index.html">正式遊戲隔離驗收</a></nav>
<button onclick="location.reload()">重新載入本案例</button>
<pre id="report">RUNNING: Godot Web 載入中</pre>
<script>
window.dao2Fault = '';
const get = Storage.prototype.getItem, set = Storage.prototype.setItem;
Storage.prototype.getItem = function(k) {
 if(k.startsWith('dao2_matrix_')) {
  if(window.dao2Fault === 'deny_read') throw new DOMException('Injected read denial','SecurityError');
  if(window.dao2Fault === 'readback' && k.endsWith(':save_backup')) throw new DOMException('Injected readback failure','SecurityError');
 }
 return get.call(this,k);
};
Storage.prototype.setItem = function(k,v) {
 if(k.startsWith('dao2_matrix_')) {
  if(window.dao2Fault === 'quota') throw new DOMException('Injected quota','QuotaExceededError');
  if(window.dao2Fault === 'security') throw new DOMException('Injected write denial','SecurityError');
  if(window.dao2Fault === 'index' && k.endsWith(':save_index')) throw new DOMException('Injected index failure','QuotaExceededError');
  if(window.dao2Fault === 'archive' && k.endsWith(':save_schema2_original')) throw new DOMException('Injected archive failure','QuotaExceededError');
  if(window.dao2Fault === 'truncate' && k.endsWith(':save_backup')) v=v.slice(0,8);
 }
 return set.call(this,k,v);
};
new MutationObserver(() => {
 const report = document.getElementById('report').textContent;
 fetch('/evidence', {method:'POST',body:JSON.stringify({url:location.href,report}),headers:{'Content-Type':'application/json'}});
}).observe(document.getElementById('report'),{childList:true});
</script>
'''

class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/c2-fixture':
            data = (ROOT/'docs/verification/artifacts/res1-c2-offline-fixture.json').read_bytes()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        if self.path == '/background':
            html = '''<!doctype html><meta charset="utf-8"><title>Web 背景恢復隔離驗證</title>
<style>body{margin:0;font:16px sans-serif}button{min-height:44px}iframe{border:0;width:100%;height:calc(100vh - 110px)}pre{margin:4px;font-size:12px;white-space:pre-wrap;max-height:45px;overflow:auto}</style>
<button onclick="document.getElementById('game').contentWindow.postMessage({pauseframes:true},location.origin);document.getElementById('game').style.display='none';document.getElementById('report').textContent='CONTROLLED FRAME PAUSE: test-only requestAnimationFrame gate'">暫停遊戲幀</button>
<button onclick="document.getElementById('game').style.display='block';document.getElementById('game').contentWindow.postMessage({pauseframes:false},location.origin)">恢復遊戲幀</button>
<button onclick="document.getElementById('game').contentWindow.postMessage({setfault:'write'},location.origin)">背景拒絕写入</button>
<button onclick="document.getElementById('game').contentWindow.postMessage({setfault:''},location.origin)">背景恢復儲存</button>
<pre id="report">RUNNING: same-origin Godot iframe</pre><iframe id="game" title="隔離遊戲" src="/release/index.html"></iframe>
<script>addEventListener('message',e=>{if(e.origin===location.origin && e.data && e.data.report){document.getElementById('report').textContent=e.data.report;fetch('/evidence',{method:'POST',body:JSON.stringify({url:location.href,report:e.data.report}),headers:{'Content-Type':'application/json'}})}})</script>'''
            data = html.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type','text/html; charset=utf-8')
            self.send_header('Content-Length',str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        elif self.path.startswith('/release/'):
            if self.path.split('?')[0] == '/release/index.html':
                html = (ROOT/'build/web/index.html').read_text(encoding='utf-8').replace('<script>', LIVE+'<script>', 1)
                data = html.encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type','text/html; charset=utf-8')
                self.send_header('Content-Length',str(len(data)))
                self.end_headers()
                self.wfile.write(data)
                return
            self.path = self.path.removeprefix('/release')
            old = self.directory
            self.directory = str(ROOT / 'build/web')
            try:
                super().do_GET()
            finally:
                self.directory = old
        elif self.path.split('?')[0] in ('/', '/index.html'):
            html = (ROOT/'build/web-persistence/index.html').read_text(encoding='utf-8')
            instrument = INSTRUMENT.replace('隔離 origin 4196', f'隔離 origin {PORT}')
            if 'case=c2' in self.path:
                instrument = instrument.replace('RES1-B / M1-C/D Web 保存驗證', 'RES1-C2 分批離線保存驗證')
                instrument = instrument.replace('<nav>', '<nav><a href="/?case=c2retry">C2 五種中斷</a><a href="/?case=c2quota">C2 真實 quota</a><a href="/?case=c2indexreload">C2 索引重載</a><a href="/?case=c2quotareload">C2 quota 重載</a><a href="/?case=c2lock">C2 雙分頁</a><a href="/?case=c2denied">C2 拒讀</a><a href="/?case=c2corrupt">C2 損壞</a>')
            html = html.replace('<script>', instrument + '<script>', 1)
            data = html.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type','text/html; charset=utf-8')
            self.send_header('Content-Length',str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            super().do_GET()

    def do_POST(self):
        if self.path != '/evidence':
            self.send_error(404)
            return
        data = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        with (ROOT/'docs/verification/artifacts/web-persistence-browser.jsonl').open('a',encoding='utf-8') as out:
            out.write(json.dumps(data,ensure_ascii=False)+'\n')
        self.send_response(204)
        self.end_headers()

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=PORT)
    args = parser.parse_args()
    PORT = args.port
    print(f'Isolated Web persistence matrix http://127.0.0.1:{PORT}',flush=True)
    ThreadingHTTPServer(('127.0.0.1',PORT),partial(Handler,directory=str(ROOT/'build/web-persistence'))).serve_forever()
