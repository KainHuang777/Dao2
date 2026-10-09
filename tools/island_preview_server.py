"""RES1-C isolated test launcher; only generated Web files and earned fixture served."""
from http.server import ThreadingHTTPServer
from web_static_server import CompressedStaticHandler, prewarm
from pathlib import Path
import json
import threading
import time

RATE_BYTES = 0
LATENCY_SECONDS = 0
RATE_LOCK = threading.Lock()
RATE_NEXT = 0.0

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / 'build' / 'island-preview'
NAMESPACE = 'dao2_islands_preview'
FIXTURE = ROOT / 'docs' / 'verification' / 'artifacts' / 'res1-c-earned-era2.json'
METRICS_LOG = ROOT / 'docs/verification/artifacts/res1-c2-closure-metrics.jsonl'
BGM_FAIL_ONCE = False
PAGE = '''<!doctype html><meta charset="utf-8"><title>RES1-C 三島隔離驗收</title>
<style>html,body{margin:0;height:100%;overflow:hidden}body{font:16px sans-serif;display:grid;grid-template-rows:44px 26px minmax(0,1fr)}button{min-height:44px}.tools{display:flex;gap:4px}iframe{border:0;display:block;width:100%;height:100%;min-width:0;min-height:0}p{margin:2px}</style>
<div class="tools"><button id="seed">載入從空白命令走出的築基測試檔</button><button id="play">開啟隔離遊戲</button><button id="compact">844×390 測試</button><button id="wide">填滿視窗</button><button id="control">同尺寸 rAF 對照</button></div>
<p id="status">獨立測試origin／dao2_islands_preview；不讀玩家dao2_saves。</p><iframe id="game" title="三島Godot預覽"></iframe>
<script>
const prefix='dao2_islands_preview:';
for (const [width,height] of [[1280,720],[800,360],[360,640]]) {
 const button=document.createElement('button');button.textContent=width+'×'+height+' 測試';
 document.querySelector('.tools').appendChild(button);
 button.onclick=()=>{const frame=document.getElementById('game');frame.style.width=width+'px';frame.style.maxWidth='100%';frame.style.height=height+'px';frame.style.alignSelf='start';document.getElementById('status').textContent='測試iframe '+width+'×'+height+' CSS px；非實體裝置驗收。';};
}
const diagnosticSeconds=new URLSearchParams(location.search).get('profileSeconds')==='60' ? '?profileSeconds=60' : '';
const normalSeconds=new URLSearchParams(location.search).get('sampleSeconds');
const normalSample=['60','300'].includes(normalSeconds) ? '?sampleSeconds='+normalSeconds : '';
const destination=location.search.includes('profile=1') ? '/profile.html'+diagnosticSeconds : (location.search.includes('metrics=1') ? '/metrics.html'+normalSample : (location.search.includes('fault=write') ? '/fault.html?fault=write' : '/index.html'));
document.getElementById('seed').onclick=async()=>{
 if(localStorage.getItem(prefix+'save_main')||localStorage.getItem(prefix+'save_backup')){document.getElementById('status').textContent='已有隔離進度，保留原檔；按開啟隔離遊戲繼續。';return;}
 const raw=await (await fetch('/fixture')).text(); const saved=JSON.parse(raw);
 localStorage.setItem(prefix+'save_main',raw);
 localStorage.setItem(prefix+'save_index',JSON.stringify({active_slot:'save_main',revision:saved.revision,commit_sequence:1}));
 document.getElementById('status').textContent='已載入命令生成築基檔；開拓／加工尚未啟用。';
 document.getElementById('game').src=destination;
};
document.getElementById('play').onclick=()=>{document.getElementById('game').src=destination;document.getElementById('status').textContent='已開啟隔離遊戲；沿用此origin既有進度，量測請等待遊戲就緒。';};
document.getElementById('control').onclick=()=>{document.getElementById('game').src='/raf-baseline';document.getElementById('status').textContent='同一iframe的無遊戲rAF對照；不能作為遊戲FPS通過證據。';};
document.getElementById('compact').onclick=()=>{const f=document.getElementById('game');f.style.width='844px';f.style.maxWidth='100%';f.style.height='390px';f.style.alignSelf='start';document.getElementById('status').textContent='測試iframe viewport 844×390 CSS px；不是實體手機證據。';};
document.getElementById('wide').onclick=()=>{const f=document.getElementById('game');f.style.width='100%';f.style.height='100%';document.getElementById('status').textContent='測試iframe填滿剩餘視窗；存檔與規則不變。';};
</script>'''

class Handler(CompressedStaticHandler):
    gzip_enabled = False
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BUILD), **kwargs)

    def do_GET(self):
        global BGM_FAIL_ONCE
        if LATENCY_SECONDS:
            time.sleep(LATENCY_SECONDS)
        if BGM_FAIL_ONCE and self.path.split('?')[0].startswith('/audio/bgm/'):
            BGM_FAIL_ONCE = False
            self.send_error(503, 'Isolated BGM retry test')
            return
        if self.path.split('?')[0] == '/raf-baseline':
            # Same observer, viewport and browser without the Godot workload.
            # A scheduling control, never counted as game FPS/ready evidence.
            instrument = (ROOT/'tools/res1c2_metrics.js').read_text(encoding='utf-8')
            data = ('<!doctype html><meta charset="utf-8"><title>rAF 排程對照</title>'
                    '<body><p>瀏覽器 rAF 排程對照：此頁沒有載入遊戲。結果不能代替遊戲 FPS。</p>'
                    '<script>' + instrument + '</script>').encode('utf-8')
            mime = 'text/html; charset=utf-8'
        elif self.path.split('?')[0] in ('/metrics.html', '/profile.html'):
            instrument = '<script>' + (ROOT/'tools/res1c2_metrics.js').read_text(encoding='utf-8') + '</script>'
            if self.path.split('?')[0] == '/profile.html':
                instrument = '<script>' + (ROOT/'tools/res1c2_runtime_profile.js').read_text(encoding='utf-8') + '</script>' + instrument
            data = (BUILD / 'index.html').read_text(encoding='utf-8').replace('<script>', instrument + '<script>', 1).encode('utf-8')
            mime = 'text/html; charset=utf-8'
        elif self.path.split('?')[0] == '/fault.html':
            from web_persistence_server import LIVE
            instrument = LIVE.replace('dao2_saves:', NAMESPACE + ':')
            data = (BUILD / 'index.html').read_text(encoding='utf-8').replace('<script>', instrument + '<script>', 1).encode('utf-8')
            mime = 'text/html; charset=utf-8'
        elif self.path.split('?')[0] == '/launcher':
            data = PAGE.encode('utf-8')
            mime = 'text/html; charset=utf-8'
        elif self.path == '/fixture':
            data = FIXTURE.read_bytes()
            mime = 'application/json'
        else:
            return super().do_GET()
        self.send_response(200)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self._write_bytes(data)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def _write_bytes(self, data):
        global RATE_NEXT
        for offset in range(0, len(data), 65536):
            chunk = data[offset:offset + 65536]
            if RATE_BYTES:
                with RATE_LOCK:
                    now = time.monotonic()
                    RATE_NEXT = max(now, RATE_NEXT) + len(chunk) / RATE_BYTES
                    delay = RATE_NEXT - now
                time.sleep(delay)
            self.wfile.write(chunk)

    def copyfile(self, source, outputfile):
        while chunk := source.read(65536):
            self._write_bytes(chunk)

    def do_POST(self):
        if self.path != '/metrics-evidence':
            self.send_error(404)
            return
        length = int(self.headers.get('Content-Length', '0'))
        if not 0 < length <= 1048576:
            self.send_error(400)
            return
        record = json.loads(self.rfile.read(length))
        record['network'] = {'mbps': RATE_BYTES * 8 / 1000000 if RATE_BYTES else None, 'response_latency_ms': LATENCY_SECONDS * 1000, 'compression': 'br/gzip negotiated for static files' if self.gzip_enabled else 'none'}
        with METRICS_LOG.open('a', encoding='utf-8') as out:
            out.write(json.dumps(record, ensure_ascii=False) + '\n')
        self.send_response(204)
        self.end_headers()

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=4197)
    parser.add_argument('--offline-fixture', action='store_true')
    parser.add_argument('--review-fixture', action='store_true')
    parser.add_argument('--fixture', help='Existing JSON fixture filename inside docs/verification/artifacts; isolated origin only')
    parser.add_argument('--normal-build', action='store_true', help='Serve normal Web export on a separate test origin with its normal save namespace')
    parser.add_argument('--profile-build', action='store_true', help='Serve build/web-profile with normal namespace; use launcher?profile=1 to opt into timings')
    parser.add_argument('--unopened-fixture', action='store_true', help='Fresh re-enveloped command-earned Era2 source before island activation')
    parser.add_argument('--throttle-mbps', type=float, default=0)
    parser.add_argument('--latency-ms', type=float, default=0)
    parser.add_argument('--gzip', action='store_true', help='Serve negotiated gzip without modifying exported files')
    parser.add_argument('--metrics-log', default='res1-c2-closure-metrics.jsonl', help='Evidence filename inside docs/verification/artifacts')
    parser.add_argument('--bgm-fail-once', action='store_true', help='Test-only transient failure of first optional music download')
    args = parser.parse_args()
    if args.fixture:
        if Path(args.fixture).name != args.fixture or not args.fixture.endswith('.json') or args.offline_fixture or args.review_fixture or args.unopened_fixture:
            parser.error('fixture must be one JSON filename and cannot be combined with preset fixture switches')
        FIXTURE = ROOT / 'docs' / 'verification' / 'artifacts' / args.fixture
        if not FIXTURE.is_file():
            parser.error('fixture does not exist')
        PAGE = PAGE.replace('載入從空白命令走出的築基測試檔', '載入隔離地標測試檔')
        PAGE = PAGE.replace('已載入命令生成築基檔；開拓／加工尚未啟用。', '已載入指定隔離測試檔；此頁不是正常新手流程驗收。')
    BGM_FAIL_ONCE = args.bgm_fail_once
    if Path(args.metrics_log).name != args.metrics_log:
        parser.error('metrics-log must be a filename')
    METRICS_LOG = ROOT / 'docs/verification/artifacts' / args.metrics_log
    Handler.gzip_enabled = args.gzip
    if args.normal_build or args.profile_build:
        BUILD = ROOT / 'build' / ('web-profile' if args.profile_build else 'web')
        NAMESPACE = 'dao2_saves'
        PAGE = PAGE.replace('dao2_islands_preview', 'dao2_saves').replace('不讀玩家dao2_saves。', '此獨立origin不讀其他origin的玩家進度。').replace('RES1-C 三島隔離驗收', 'RES1-C3 正常版隔離驗收')
    if args.unopened_fixture:
        if args.offline_fixture or args.review_fixture:
            parser.error('unopened fixture cannot be combined with another fixture')
        FIXTURE = ROOT / 'docs' / 'verification' / 'artifacts' / 'res1-c3-unopened-fixture.json'
    if args.offline_fixture and args.review_fixture:
        parser.error('choose either offline or review fixture')
    if args.throttle_mbps < 0 or args.latency_ms < 0:
        parser.error('throttle and latency must be nonnegative')
    RATE_BYTES = args.throttle_mbps * 1000000 / 8
    LATENCY_SECONDS = args.latency_ms / 1000
    if args.offline_fixture:
        FIXTURE = ROOT / 'docs' / 'verification' / 'artifacts' / 'res1-c2-offline-fixture.json'
        PAGE = PAGE.replace('載入從空白命令走出的築基測試檔', '載入48h雙鏈加工隔離檔').replace('已載入命令生成築基檔；開拓／加工尚未啟用。', '已載入命令生成雙鏈加工檔；游標設為48h前，等待結算。')
    if args.review_fixture:
        FIXTURE = ROOT / 'docs' / 'verification' / 'artifacts' / 'res1-c2-review-fixture.json'
        PAGE = PAGE.replace('載入從空白命令走出的築基測試檔', '載入三島雙鏈試玩檔').replace('已載入命令生成築基檔；開拓／加工尚未啟用。', '已載入命令生成三島檔；只刷新測試游標，沒有加入資源。')
    prewarm(BUILD, Handler)
    print(f'RES1-C preview: http://127.0.0.1:{args.port}/launcher gzip={args.gzip}', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
